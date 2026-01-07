#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

DOMAINS_FILE="$1"
CSV_FILE="security_headers_report.csv"
TMP_DIR="/tmp/security_headers_scan_$$"
MAX_PARALLEL=10  # Adjust based on your system

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
NC="\033[0m"

SEC_HEADERS=(
  "X-Frame-Options"
  "X-Content-Type-Options"
  "Strict-Transport-Security"
  "Content-Security-Policy"
  "X-Permitted-Cross-Domain-Policies"
  "Referrer-Policy"
  "Permissions-Policy"
  "Cross-Origin-Embedder-Policy"
  "Cross-Origin-Resource-Policy"
  "Cross-Origin-Opener-Policy"
)

# Cleanup function
cleanup() {
  if [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
  # Kill any remaining background processes
  pkill -P $$ 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Create temporary directory
mkdir -p "$TMP_DIR"

# ───────────────────────── CSV HEADER ─────────────────────────
{
  printf "domain"
  for h in "${SEC_HEADERS[@]}"; do
    printf ",%s" "$h"
  done
  printf "\n"
} > "$CSV_FILE"

# Function to process a single domain
process_domain() {
  local domain="$1"
  local tmp_file="$2"
  
  [[ -z "$domain" || "$domain" =~ ^# ]] && return
  
  echo -e "${PURPLE}[*] Analyzing headers of $domain${NC}" >&2
  
  local headers=$(curl -skI --connect-timeout 4 --max-time 8 "https://$domain" 2>/dev/null)
  local url="https://$domain"
  
  if [[ -z "$headers" ]]; then
    headers=$(curl -skI --connect-timeout 4 --max-time 8 "http://$domain" 2>/dev/null)
    url="http://$domain"
  fi
  
  if [[ -z "$headers" ]]; then
    echo -e "${RED}[-] No response (HTTP/HTTPS) from $domain${NC}" >&2
    # Still write to CSV but with all "Non"
    local csv_line="$domain"
    for ((i=0; i<${#SEC_HEADERS[@]}; i++)); do
      csv_line+=",Non"
    done
    echo "$csv_line" > "$tmp_file"
    return
  fi
  
  echo -e "${BLUE}[*] Effective URL for $domain: $url${NC}" >&2
  
  local csv_line="$domain"
  
  for header in "${SEC_HEADERS[@]}"; do
    local value=$(echo "$headers" | awk -v h="$header" '
      BEGIN{IGNORECASE=1}
      $0 ~ "^"h":" {print; exit}
    ')
    
    if [[ -n "$value" ]]; then
      echo -e "${GREEN}[*] Header $header is present for $domain${NC}" >&2
      csv_line+=",Oui"
    else
      echo -e "${RED}[-] Header $header is NOT present for $domain${NC}" >&2
      csv_line+=",Non"
    fi
  done
  
  echo "$csv_line" > "$tmp_file"
  echo -e "${BLUE}-------------------------------------------------------${NC}" >&2
}

# ───────────────────────── PARALLEL PROCESSING ─────────────────────────
export -f process_domain
export SEC_HEADERS
export GREEN RED YELLOW BLUE PURPLE NC

echo "Starting parallel scan with up to $MAX_PARALLEL concurrent processes..."
echo

# Array to store PIDs
declare -a PIDS=()
declare -a TMP_FILES=()

# Read domains and process them
while read -r domain; do
  # Wait if we have too many parallel processes
  while [ ${#PIDS[@]} -ge $MAX_PARALLEL ]; do
    # Check for finished processes
    for i in "${!PIDS[@]}"; do
      if ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
        # Process finished, remove from array
        unset PIDS[$i]
        # Re-index array
        PIDS=("${PIDS[@]}")
        break
      fi
    done
    # Sleep a bit before checking again
    sleep 0.1
  done
  
  # Create temp file for this domain's result
  tmp_file="$TMP_DIR/$(echo "$domain" | tr -cd '[:alnum:]').tmp"
  TMP_FILES+=("$tmp_file")
  
  # Start processing in background
  process_domain "$domain" "$tmp_file" &
  PIDS+=($!)
  
done < "$DOMAINS_FILE"

# Wait for all background processes to finish
echo "Waiting for all scans to complete..."
wait

# ───────────────────────── COLLECT RESULTS ─────────────────────────
echo "Collecting results..."

# Sort temp files for consistent output order
IFS=$'\n' sorted_tmp_files=($(sort <<<"${TMP_FILES[*]}"))
unset IFS

for tmp_file in "${sorted_tmp_files[@]}"; do
  if [ -f "$tmp_file" ]; then
    cat "$tmp_file" >> "$CSV_FILE"
  fi
done

echo
echo -e "${GREEN}[+] CSV report generated:${NC} $CSV_FILE"
echo -e "${GREEN}[+] Scanned $(wc -l < "$DOMAINS_FILE") domains${NC}"
