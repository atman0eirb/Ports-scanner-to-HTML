#!/usr/bin/env bash

# ------------------------------------------------------------------
# Usage check
# ------------------------------------------------------------------
if [ $# -ne 1 ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

DOMAINS_FILE="$1"
JOBS=20

# ------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
NC="\033[0m"

# ------------------------------------------------------------------
# Header detection regex
# ------------------------------------------------------------------
HEADER_REGEX='^(server|x-powered-by|x-aspnet-version|x-aspnetmvc-version|x-generator|x-drupal-cache|x-backend-server|via|x-cache|x-varnish):'

# ------------------------------------------------------------------
# Temporary files
# ------------------------------------------------------------------
TMPDIR=$(mktemp -d)
FOUND_FILE="$TMPDIR/found.txt"

export HEADER_REGEX RED GREEN YELLOW BLUE PURPLE NC TMPDIR FOUND_FILE

# ------------------------------------------------------------------
# Domain processing function
# ------------------------------------------------------------------
process_domain() {
  domain="$1"
  out="$TMPDIR/$domain.out"

  {
    echo
    printf "%b[*] Target:%b %s\n" "$BLUE" "$NC" "$domain"

    headers=$(
      curl -skI --connect-timeout 3 --max-time 6 "https://$domain" \
        || curl -skI --connect-timeout 3 --max-time 6 "http://$domain"
    )

    if [[ -z "$headers" ]]; then
      printf "  %b[-] No response%b\n" "$RED" "$NC"
      exit
    fi

    matches=$(echo "$headers" | grep -Ei "$HEADER_REGEX")

    if [[ -n "$matches" ]]; then
      printf "  %b[!] Verbose headers found:%b\n" "$YELLOW" "$NC"

      while IFS= read -r line; do
        printf "      %b%s%b\n" "$YELLOW" "$line" "$NC"
      done <<< "$matches"

      echo "$domain" >> "$FOUND_FILE"
    else
      printf "  %b[+] No verbose headers detected%b\n" "$GREEN" "$NC"
    fi
  } > "$out"
}

export -f process_domain

# ------------------------------------------------------------------
# Execution
# ------------------------------------------------------------------
echo -e "${PURPLE}================ VERBOSE HEADER CHECK ================${NC}"

grep -vE '^\s*$|^#' "$DOMAINS_FILE" \
  | xargs -P "$JOBS" -n 1 bash -c 'process_domain "$@"' _

# ------------------------------------------------------------------
# Output results (ordered)
# ------------------------------------------------------------------
for f in "$TMPDIR"/*.out; do
  cat "$f"
done

echo
echo -e "${PURPLE}==================== SUMMARY ====================${NC}"

if [ ! -s "$FOUND_FILE" ]; then
  echo -e "${GREEN}[+] No domains with verbose headers found${NC}"
else
  sort -u "$FOUND_FILE" | awk '{print " - " $0}'
fi

# ------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------
rm -rf "$TMPDIR"
