#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${1:-/config/www/esphome_bins}"
NODES_CSV="${2:-}"   # comma-separated node names (empty = compile ALL)
ESPHOME_DIR="/config/esphome"

mkdir -p "$BIN_DIR"
REPORT_JSON="$BIN_DIR/last_run.json"
REPORT_MD="$BIN_DIR/last_run.md"
TMP_JSON="$(mktemp)"
TMP_MD="$(mktemp)"

command -v esphome >/dev/null 2>&1 || {
  echo "ERROR: esphome CLI not found" >&2
  echo "{\"status\":\"error\",\"message\":\"esphome CLI not found\",\"results\":[]}" > "$REPORT_JSON"
  printf "# ESPHome Staged Updates\n\n**Status:** error\n\n**Message:** esphome CLI not found\n" > "$REPORT_MD"
  exit 1
}

# Build list of YAMLs to compile
declare -a YAMLS=()
if [[ -n "$NODES_CSV" ]]; then
  IFS=',' read -ra NODES <<< "$NODES_CSV"
  for node in "${NODES[@]}"; do
    y="$ESPHOME_DIR/$node.yaml"
    [[ -f "$y" ]] || y="$ESPHOME_DIR/$node.yml"
    if [[ -f "$y" ]] ; then
      YAMLS+=("$y")
    else
      echo "WARN: No YAML for node '$node'" >&2
    fi
  done
else
  shopt -s nullglob
  for y in "$ESPHOME_DIR"/*.yaml "$ESPHOME_DIR"/*.yml; do YAMLS+=("$y"); done
fi

RESULTS=()
ok_count=0
fail_count=0

for yaml in "${YAMLS[@]}"; do
  name="$(basename "$yaml")"
  node="${name%.*}"
  echo "==> Compiling $node"
  if esphome compile "$yaml"; then
    build_dir="$ESPHOME_DIR/.esphome/build/$node"
    bin_path="$(find "$build_dir" -path "*/.pioenvs/*/firmware.bin" -type f -print 2>/dev/null | sort | tail -n 1)"
    if [[ -n "${bin_path:-}" && -f "$bin_path" ]]; then
      cp -f "$bin_path" "$BIN_DIR/$node.bin"
      RESULTS+=("{\"node\":\"$node\",\"yaml\":\"$name\",\"status\":\"compiled\",\"bin\":\"$BIN_DIR/$node.bin\"}")
      ((ok_count++))
    else
      RESULTS+=("{\"node\":\"$node\",\"yaml\":\"$name\",\"status\":\"no_firmware\",\"bin\":null}")
      ((fail_count++))
    fi
  else
    RESULTS+=("{\"node\":\"$node\",\"yaml\":\"$name\",\"status\":\"compile_failed\",\"bin\":null}")
    ((fail_count++))
  fi
done

timestamp="$(date -Is)"
printf '{ "status":"done","ok":%d,"failed":%d,"timestamp":"%s","results":[%s] }\n' \
  "$ok_count" "$fail_count" "$timestamp" "$(IFS=,; echo "${RESULTS[*]-}")" > "$TMP_JSON"
mv "$TMP_JSON" "$REPORT_JSON"

# Markdown report
{
  echo "# ESPHome Staged Updates"
  echo ""
  echo "**Timestamp:** $timestamp  "
  echo "**Compiled OK:** $ok_count  "
  echo "**Failed:** $fail_count  "
  echo ""
  echo "| Node | YAML | Status | Binary |"
  echo "|------|------|--------|--------|"
} > "$TMP_MD"

# Read back JSON and render rows with jq if available, else naive parsing
if command -v jq >/dev/null 2>&1; then
  jq -r '.results[] | "| \(.node) | \(.yaml) | \(.status) | \(.bin//"-") |"' "$REPORT_JSON" >> "$TMP_MD"
else
  # Fallback: append a note
  echo "\n_JQ not found. Install jq on your HA host for detailed rows._" >> "$TMP_MD"
fi

mv "$TMP_MD" "$REPORT_MD"

# Minimal manifest to keep update entity contented if used
cat > "$BIN_DIR/manifest.json" <<'JSON'
{ "version": "staged", "files": [] }
JSON

echo "Staged binaries in $BIN_DIR"
echo "Reports: $REPORT_JSON , $REPORT_MD"
