#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="${SCRIPT_DIR}/transkribus-page-2013-sample.xml"
TMP_DIR="$(mktemp -d)"
NORM="${TMP_DIR}/page-2019.xml"
ALTO="${TMP_DIR}/page.alto.xml"

echo "1) PAGE 2013 -> PAGE 2019 via transkribus-to-prima"
transkribus-to-prima "$INPUT" > "$NORM"

grep -q "PAGE/gts/pagecontent/2019" "$NORM" \
  || { echo "Normalized file does not look like PAGE 2019"; exit 1; }

echo "2) PAGE 2019 -> ALTO via page-to-alto"
page-to-alto --alto-version 4.2 --no-check-words "$NORM" -O "$ALTO"

test -s "$ALTO" || { echo "ALTO output not created"; exit 1; }

grep -q "http://www.loc.gov/standards/alto" "$ALTO" \
  || { echo "Output does not look like ALTO XML"; exit 1; }

echo "OK: both conversions work."
rm -rf "$TMP_DIR"
