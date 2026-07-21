#!/usr/bin/env zsh
# run_test.sh — Run a Patrol test and automatically capture the device logcat.
#
# Usage (from the RcomFTPAutomation folder):
#   ./run_test.sh <suite/test_file.dart> [device-id]
#
# Examples:
#   ./run_test.sh suites/gameplay/first_drop_test.dart
#   ./run_test.sh suites/gameplay/first_drop_test.dart 14091JEC202977
#
# What it does:
#   1. Clears the on-device logcat buffer (so no stale lines from a previous run).
#   2. Runs the patrol test.
#   3. Captures logcat to reports/logcat_<test-id>_<timestamp>.txt immediately
#      after the test exits (pass or fail), so no manual step is needed.
#
# After the run, convert to Allure with:
#   dart run tool/convert_to_allure.dart \
#     --logcat reports/logcat_<file>.txt \
#     --output reports/allure-results/ \
#     --suite  gameplay \
#     --api-level 34

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
FVM_FLUTTER="$HOME/fvm/versions/3.41.6/bin"
PUB_CACHE="$HOME/.pub-cache/bin"

# Auto-detect RUMMY_DIR: check common locations or use RUMMY_DIR env var.
# Team can override: RUMMY_DIR=/path/to/rummy ./run_test.sh ...
if [[ -n "${RUMMY_DIR:-}" ]]; then
  # Explicitly set via env var
  true
elif [[ -d "$HOME/Developer/prism/apps/rummy" ]]; then
  RUMMY_DIR="$HOME/Developer/prism/apps/rummy"
elif [[ -d "../../prism/apps/rummy" ]]; then
  RUMMY_DIR="$(cd "../../prism/apps/rummy" && pwd)"
else
  echo "✗ RUMMY_DIR not found. Set it explicitly:"
  echo "   RUMMY_DIR=/path/to/rummy ./run_test.sh ..."
  exit 1
fi

# Verify RUMMY_DIR exists and has the right structure
if [[ ! -d "$RUMMY_DIR" || ! -f "$RUMMY_DIR/pubspec.yaml" ]]; then
  echo "✗ RUMMY_DIR invalid: $RUMMY_DIR"
  echo "   (expected: <rummy-repo>/apps/rummy with pubspec.yaml)"
  exit 1
fi

export PATH="$FVM_FLUTTER:$PUB_CACHE:$PATH"

# ── Args ──────────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <suite/test_file.dart> [device-id] [configs]"
  echo "Examples:"
  echo "  $0 suites/gameplay/first_drop_test.dart 14091JEC202977"
  echo "  $0 suites/gameplay/first_drop_test.dart 14091JEC202977 points-6p"
  echo "  $0 suites/gameplay/valid_declare_test.dart 14091JEC202977 points-2p,points-6p"
  exit 1
fi

TEST_REL="$1"                        # e.g. suites/gameplay/first_drop_test.dart
TEST_FILE="integration_test/$TEST_REL"

# Derive a short id from the test filename for the logcat filename.
# When a config is passed, append it so 2P and 6P produce separate files
# and show as separate entries in the Allure report.
#   first_drop              (no config arg)
#   first_drop_points-2p    (config = points-2p)
#   first_drop_points-6p    (config = points-6p)
TEST_ID=$(basename "$TEST_REL" _test.dart | sed 's/_test$//')
if [[ $# -ge 3 && -n "$3" ]]; then
  TEST_ID="${TEST_ID}_${3//,/-}"   # points-2p,points-6p → points-2p-points-6p
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGCAT_FILE="$REPORTS_DIR/logcat_${TEST_ID}_${TIMESTAMP}.txt"

# Arrays so zsh doesn't treat "adb -s DEVICE" as a single command token.
DEVICE_FLAG=()
ADB=(adb)
if [[ $# -ge 2 ]]; then
  DEVICE_FLAG=(-d "$2")
  ADB=(adb -s "$2")
fi

# Optional 3rd arg: TABLE_CONFIGS dart-define (default: points-2p).
# Single config: points-6p   Both: points-2p,points-6p
TABLE_CONFIGS_FLAG=()
if [[ $# -ge 3 && -n "$3" ]]; then
  TABLE_CONFIGS_FLAG=("--dart-define=TABLE_CONFIGS=$3")
  echo "▶  Table configs: $3"
fi

mkdir -p "$REPORTS_DIR"

# ── Run ───────────────────────────────────────────────────────────────────────

# Record device-side timestamp before the test so we can filter logcat to only
# entries produced during THIS run. Using the device clock avoids timezone drift.
# Format for `adb logcat -T`: "MM-DD HH:MM:SS.mmm"
# NOTE: single-quote the format string so the device shell doesn't split on spaces.
PRE_TEST_TS=$("${ADB[@]}" shell 'date "+%m-%d %H:%M:%S.000"' 2>/dev/null || date "+%m-%d %H:%M:%S.000")

# Set up allure-results dir early — the watcher writes PNGs here.
ALLURE_OUT="$REPORTS_DIR/allure-results"
mkdir -p "$ALLURE_OUT"

# Enlarge the on-device logcat ring buffer so it never overflows even for
# long human-paced multi-game tests (default ~256 KB ≈ 3K lines; 16 MB
# holds ~200K lines — more than enough for a 1-hour session).
"${ADB[@]}" logcat -G 16m 2>/dev/null || true

# ── Screencap watcher ────────────────────────────────────────────────────────
# Lightweight background stream: only fires `adb exec-out screencap -p` when
# a 🃏 SCREENSHOT marker appears. Does NOT write to the logcat file — the
# ring buffer (now 16 MB) retains everything; the post-test dump captures it.
(
  "${ADB[@]}" logcat -T "$PRE_TEST_TS" 2>/dev/null | while IFS= read -r _line; do
    if [[ "$_line" == *'🃏 SCREENSHOT | '* ]]; then
      _name=$(printf '%s' "$_line" \
              | sed -E 's/.*🃏 SCREENSHOT \| [^:]+:: *//' \
              | tr -d '[:space:]\r')
      if [[ -n "$_name" ]]; then
        "${ADB[@]}" exec-out screencap -p > "$ALLURE_OUT/${_name}.png" 2>/dev/null
        echo "   Screencap: ${_name}.png"
      fi
    fi
  done
) &
WATCHER_PID=$!

# Hard ceiling so a genuine hang (native-bridge desync, app ANR, stuck
# stream) fails the run instead of blocking the script forever and requiring
# a manual kill. 6P settlement (5 players × 35 s/turn, possibly twice in a
# drop/rejoin test) is slower than 2P, so give it more room — but not
# unbounded: confirmed via logcat (2026-07-21, drop_and_leave 6P) that a
# legitimate full run (script start → Dart test completion, both chip checks
# included) took ~198s, and a known app-side teardown stall after mid-drop
# (still-live socket from an abandoned Drop & Leave table) never resolves on
# its own no matter how long you wait. 300s (~50% margin over the observed
# worst case) catches the hang quickly without eating minutes per test when
# running a full suite sequentially.
TEST_TIMEOUT_SECS=600
if [[ $# -ge 3 && "$3" == *6p* ]]; then
  TEST_TIMEOUT_SECS=300
fi
# Override for one-off diagnostic runs: WATCHDOG_SECS=180 ./run_test.sh ...
TEST_TIMEOUT_SECS="${WATCHDOG_SECS:-$TEST_TIMEOUT_SECS}"

echo "▶  Running: $TEST_FILE  (logcat from $PRE_TEST_TS onwards, " \
     "watchdog ${TEST_TIMEOUT_SECS}s)"
cd "$RUMMY_DIR"

set +e
patrol test \
  -t "$TEST_FILE" \
  --flavor rummy \
  --dart-define=FLUTTER_ENV=qa \
  "${TABLE_CONFIGS_FLAG[@]}" \
  --no-uninstall \
  "${DEVICE_FLAG[@]}" &
PATROL_PID=$!

WAITED=0
PATROL_EXIT=""
while kill -0 "$PATROL_PID" 2>/dev/null; do
  sleep 5
  WAITED=$((WAITED + 5))
  if (( WAITED >= TEST_TIMEOUT_SECS )); then
    echo ""
    echo "⏱  WATCHDOG: patrol test exceeded ${TEST_TIMEOUT_SECS}s — killing (PID $PATROL_PID)."
    echo "   This usually means a real hang (native-bridge desync or app freeze), not a slow test."
    kill -TERM "$PATROL_PID" 2>/dev/null
    sleep 5
    kill -KILL "$PATROL_PID" 2>/dev/null
    wait "$PATROL_PID" 2>/dev/null
    PATROL_EXIT=124
    break
  fi
done
if [[ -z "$PATROL_EXIT" ]]; then
  wait "$PATROL_PID"
  PATROL_EXIT=$?
fi
set -e

# Stop the screencap watcher immediately — its job is done.
kill $WATCHER_PID 2>/dev/null || true
wait $WATCHER_PID 2>/dev/null || true

# ── Post-test logcat dump ────────────────────────────────────────────────────
# The enlarged ring buffer holds the full test run. Retry a few times to let
# adb reconnect after Patrol's teardown.  Long 6P tests need more settling
# time — use 10 s per retry (5 × 10 s = 50 s max wait).
cd "$SCRIPT_DIR"
echo ""
echo "▶  Capturing logcat (from $PRE_TEST_TS) → $LOGCAT_FILE"
LOGCAT_LINES=0
LOGCAT_ERROR=""

for _retry in 1 2 3 4 5 6; do
  sleep 15
  # Capture stderr so we can diagnose adb failures.
  LOGCAT_ERROR=$("${ADB[@]}" logcat -T "$PRE_TEST_TS" -d > "$LOGCAT_FILE" 2>&1) || LOGCAT_ERROR="adb command failed"

  # Check if file was written and has content.
  if [[ -f "$LOGCAT_FILE" ]]; then
    LOGCAT_LINES=$(wc -l < "$LOGCAT_FILE" | tr -d ' ')
  else
    LOGCAT_LINES=0
  fi

  if [[ $LOGCAT_LINES -gt 0 ]]; then
    echo "   ✓ Timestamp-filtered logcat: $LOGCAT_LINES lines"
    break
  fi
  echo "   Retry $_retry/6: got $LOGCAT_LINES lines${LOGCAT_ERROR:+, error: $LOGCAT_ERROR}, waiting..."
done

# Fallback: if the timestamp-filtered dump is still empty, try a full buffer
# dump (includes pre-test lines but the converter only cares about 🃏 markers).
if [[ $LOGCAT_LINES -eq 0 ]]; then
  echo "   ⚠  Timestamp-filtered dump empty — falling back to full buffer dump..."
  sleep 5
  "${ADB[@]}" logcat -d > "$LOGCAT_FILE" 2>&1
  if [[ -f "$LOGCAT_FILE" ]]; then
    LOGCAT_LINES=$(wc -l < "$LOGCAT_FILE" | tr -d ' ')
    echo "   ✓ Full buffer logcat: $LOGCAT_LINES lines (includes pre-test lines)"
  else
    echo "   ✗ FAILED to capture logcat — adb may be unresponsive"
    LOGCAT_LINES=0
  fi
fi

if [[ $LOGCAT_LINES -eq 0 ]]; then
  echo "   ✗ ERROR: Logcat file is empty — cannot generate Allure report"
  exit 1
fi

echo "   Saved: $LOGCAT_FILE ($LOGCAT_LINES lines)"

# ── Convert to Allure ─────────────────────────────────────────────────────────
# Note: ALLURE_OUT already set above; PNGs already written by the watcher.

echo ""
echo "▶  Converting to Allure → $ALLURE_OUT"
# Append this run's result to allure-results (do NOT clear).
# To rebuild a clean full-suite report use ./generate_report.sh instead.
dart run tool/convert_to_allure.dart \
  --logcat  "$LOGCAT_FILE" \
  --output  "$ALLURE_OUT" \
  --suite   gameplay \
  --api-level 34

echo ""
if [[ $PATROL_EXIT -eq 0 ]]; then
  echo "✅  Test PASSED. Open report with:  allure serve $ALLURE_OUT"
elif [[ $PATROL_EXIT -eq 124 ]]; then
  echo "❌  Test TIMED OUT (watchdog killed it after ${TEST_TIMEOUT_SECS}s — real hang, not a normal failure). Open report with:  allure serve $ALLURE_OUT"
else
  echo "❌  Test FAILED (patrol exit $PATROL_EXIT). Open report with:  allure serve $ALLURE_OUT"
fi

exit $PATROL_EXIT
