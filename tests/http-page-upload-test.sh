#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/page-sample.xml" >&2
  exit 2
fi

SAMPLE="$1"

if [ ! -f "$SAMPLE" ]; then
  echo "ERROR: Sample file not found: $SAMPLE" >&2
  exit 2
fi

UPLOAD_KEY="${UPLOAD_KEY:-}"
if [ -z "$UPLOAD_KEY" ]; then
  echo "ERROR: UPLOAD_KEY is not set in the environment" >&2
  exit 2
fi

SERVER_URL="${SERVER_URL:-http://localhost:8000/index.php}"

echo "Uploading '$SAMPLE' to ${SERVER_URL}"

RESP=$(curl -sS -w "\n%{http_code}" \
  -H "Authorization: Bearer ${UPLOAD_KEY}" \
  -F "file=@${SAMPLE};type=application/xml" \
  "${SERVER_URL}")

BODY=$(echo "$RESP" | sed '$d')
CODE=$(echo "$RESP" | tail -n1)

echo "HTTP status: $CODE"

if [ "$CODE" -ne 200 ]; then
  echo "Non-200 response from API"
  echo "Body: $BODY"
  exit 1
fi

echo "$BODY" | grep -q "http://www.loc.gov/standards/alto" || {
  echo "Response does not look like ALTO XML"
  echo "Body (truncated):"
  echo "$BODY" | head -n 40
  exit 1
}

echo "OK: POST upload endpoint returned ALTO XML."
