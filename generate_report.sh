#!/usr/bin/env zsh
# generate_report.sh — Build one Allure report covering ALL test cases.
#
# How it works:
#   1. Scans reports/ for every logcat_*.txt file.
#   2. Groups them by test-case ID (auto-named files: "first_drop",
#      "table_setup", etc.; manually-named files: "drop001", "drop002", etc.).
#   3. For each test-case ID, picks the MOST RECENT logcat file (so re-runs
#      always show the latest result, not stale ones).
#   4. Clears allure-results/, converts each chosen file, then serves.
#
# Usage:
#   ./generate_report.sh            # convert + serve
#   ./generate_report.sh --no-serve # convert only (CI mode)
#
# After the script finishes you can always re-serve with:
#   allure serve reports/allure-results/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
ALLURE_OUT="$REPORTS_DIR/allure-results"
SERVE=true

for arg in "$@"; do
  [[ "$arg" == "--no-serve" ]] && SERVE=false
done

# ── Find all logcat files ──────────────────────────────────────────────────────

logcat_files=("$REPORTS_DIR"/logcat_*.txt(N))
if [[ ${#logcat_files[@]} -eq 0 ]]; then
  echo "ERROR: No logcat_*.txt files found in $REPORTS_DIR"
  echo "       Run a test first with ./run_test.sh"
  exit 1
fi

# ── Group by test-case ID; keep latest per group ───────────────────────────────
#
# Filename patterns:
#   auto-named : logcat_first_drop_20260720_194330.txt  → id = first_drop
#   manual     : logcat_drop001.txt                     → id = drop001
#
# "Latest" = highest sort order of the filename (timestamps sort lexically).

typeset -A best_file   # test_id → best logcat path

for f in "${logcat_files[@]}"; do
  base=$(basename "$f" .txt)                      # e.g. logcat_first_drop_20260720_194330

  # Strip the leading "logcat_"
  rest="${base#logcat_}"                          # e.g. first_drop_20260720_194330

  # If the name ends in _YYYYMMDD_HHMMSS, strip the timestamp suffix
  if [[ "$rest" =~ ^(.+)_([0-9]{8})_([0-9]{6})$ ]]; then
    test_id="${match[1]}"                         # e.g. first_drop
  else
    test_id="$rest"                               # e.g. drop001
  fi

  # Keep whichever filename sorts later (latest timestamp wins for auto-named;
  # last alphabetically for manually-named files with the same prefix).
  if [[ -z "${best_file[$test_id]+_}" ]] || [[ "$f" > "${best_file[$test_id]}" ]]; then
    best_file[$test_id]="$f"
  fi
done

# ── Convert ────────────────────────────────────────────────────────────────────

echo "▶  Found ${#best_file[@]} test case(s) to convert:"
for id in ${(k)best_file}; do
  echo "   • $id  ← $(basename ${best_file[$id]})"
done
echo ""

# Fresh slate — remove old result JSONs (keep categories.json).
rm -f "$ALLURE_OUT"/*-result.json(N)
mkdir -p "$ALLURE_OUT"

cd "$SCRIPT_DIR"
converted=0
failed=0

for id in ${(k)best_file}; do
  logcat="${best_file[$id]}"
  echo "▶  Converting: $id"
  if dart run tool/convert_to_allure.dart \
       --logcat  "$logcat" \
       --output  "$ALLURE_OUT" \
       --suite   gameplay \
       --api-level 34; then
    converted=$(( converted + 1 ))
  else
    echo "   WARNING: conversion failed for $id"
    failed=$(( failed + 1 ))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Converted : $converted test case(s)"
[[ $failed -gt 0 ]] && echo "  Failed    : $failed (check warnings above)" || true
echo "  Results   : $ALLURE_OUT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if $SERVE; then
  echo ""
  echo "▶  Launching Allure..."
  allure serve "$ALLURE_OUT"
else
  echo ""
  echo "  View with:  allure serve $ALLURE_OUT"
fi
