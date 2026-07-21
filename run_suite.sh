#!/usr/bin/env zsh
# run_suite.sh — Run the full stakeholder gameplay sequence in ONE guest
# session, sequentially, then build ONE completely fresh Allure report.
#
# Sequence (per QA sign-off order):
#   0. Pregame flow            (table_setup)      — establishes the guest session
#   1. First drop              (2P, then 6P)
#   2. Mid drop                (2P, then 6P)
#   3. Invalid declare         (2P, then 6P)
#   4. Valid declare           (2P, then 6P)
#   5. Drop & leave            (2P, then 6P)
#
# Guarantees the stakeholder constraints:
#   • Guest-only: step 0 creates the guest once; every later launch reuses the
#     on-disk session (AuthPage.ensureLoggedIn logs "existing session reused").
#   • No re-login / no reinstall: each run_test.sh call passes --no-uninstall,
#     so the guest token survives the per-scenario relaunch.
#   • No halt between transitions: a failing scenario (or the known 6P Drop &
#     Leave watchdog kill, exit 124) is logged and the suite CONTINUES.
#   • Fresh report: old logcats are archived and allure-results wiped before
#     the run, so the final report contains ONLY this session's results.
#
# Usage:
#   ./run_suite.sh                       # auto-detect device, serve report
#   ./run_suite.sh 14091JEC202977        # explicit device
#   ./run_suite.sh 14091JEC202977 --no-serve   # CI: build report, don't serve
#
# Environment variables (optional overrides):
#   RUMMY_DIR=/path/to/rummy  # if not at default $HOME/Developer/prism/apps/rummy
#
# NOTE: deliberately NO `set -e` — an individual scenario must never abort the
# sequence. Failures surface as report cards, not as a halted run.
set -uo pipefail
setopt NULL_GLOB

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
SUITE="suites/gameplay"

# ── Args ───────────────────────────────────────────────────────────────────
DEVICE=""
SERVE=true
for arg in "$@"; do
  case "$arg" in
    --no-serve) SERVE=false ;;
    *)          DEVICE="$arg" ;;
  esac
done
# Auto-detect the first attached device if none was given.
if [[ -z "$DEVICE" ]]; then
  DEVICE=$(adb devices | awk 'NR==2 && $2=="device" {print $1}')
fi
if [[ -z "$DEVICE" ]]; then
  echo "✗ No device found (adb devices). Plug one in or pass its id."
  exit 1
fi
echo "▶  Device: $DEVICE"

# ── Fresh slate (this is what makes the stakeholder report clean) ───────────
mkdir -p "$REPORTS_DIR/archive"
old_logs=( "$REPORTS_DIR"/logcat_*.txt )
if (( ${#old_logs} )); then
  mv "${old_logs[@]}" "$REPORTS_DIR/archive/"
  echo "▶  Archived ${#old_logs} old logcat(s) → reports/archive/"
fi
rm -rf "$REPORTS_DIR/allure-results"
mkdir -p "$REPORTS_DIR/allure-results"
echo "▶  Cleared reports/allure-results/ — report will contain only this run."

# ── The ordered sequence ────────────────────────────────────────────────────
# One entry = one run_test.sh invocation = one patrol session = one watchdog
# window (600s for 2P, 300s for 6P). 2P precedes 6P within every scenario.
sequence=(
  "table_setup_test.dart points-2p"        # 0. pregame / guest bootstrap
  "first_drop_test.dart points-2p"         # 1.
  "first_drop_test.dart points-6p"
  "mid_drop_test.dart points-2p"           # 2.
  "mid_drop_test.dart points-6p"
  "invalid_declare_test.dart points-2p"    # 3.
  "invalid_declare_test.dart points-6p"
  "valid_declare_test.dart points-2p"      # 4.
  "valid_declare_test.dart points-6p"
  "drop_and_leave_test.dart points-2p"     # 5.
  "drop_and_leave_test.dart points-6p"
)

total=${#sequence[@]}
idx=0
typeset -A results   # "file config" -> exit code
for entry in "${sequence[@]}"; do
  idx=$((idx + 1))
  file="${entry%% *}"
  cfg="${entry##* }"
  echo ""
  echo "══════════════════════════════════════════════════════════════════════"
  echo "▶  [$idx/$total]  $file  [$cfg]"
  echo "══════════════════════════════════════════════════════════════════════"
  # run_test.sh: <suite/file.dart> <device> <configs>. It captures logcat and
  # converts to Allure itself; we rebuild cleanly at the end regardless.
  ./run_test.sh "$SUITE/$file" "$DEVICE" "$cfg"
  code=$?
  results[$entry]=$code
  if [[ $code -eq 0 ]]; then
    echo "✅  [$idx/$total] $file [$cfg] PASSED"
  elif [[ $code -eq 124 ]]; then
    echo "⏱  [$idx/$total] $file [$cfg] watchdog-killed (known hang) — continuing"
  else
    echo "❌  [$idx/$total] $file [$cfg] exit $code — continuing"
  fi
done

# ── Sequence summary (console; the report is the source of truth) ───────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Sequence complete — per-scenario exit codes:"
for entry in "${sequence[@]}"; do
  printf "    %-40s exit %s\n" "$entry" "${results[$entry]}"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Fresh stakeholder report ────────────────────────────────────────────────
# generate_report.sh wipes *-result.json and rebuilds from the LATEST logcat
# per test-id. Since we archived old logcats above, "latest" = this run only.
echo ""
echo "▶  Building fresh Allure report…"
if $SERVE; then
  ./generate_report.sh            # rebuild + serve
else
  ./generate_report.sh --no-serve # rebuild only (CI)
fi
