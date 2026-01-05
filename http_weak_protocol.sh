#!/usr/bin/env bash


if [ $# -ne 1 ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

DOMAINS_FILE="$1"
JOBS=20


GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m"


TMPDIR=$(mktemp -d)
RESULTS="$TMPDIR/http_accessible.txt"


check_http() {
  domain="$1"

  if curl -sI --connect-timeout 3 --max-time 6 "http://$domain" >/dev/null; then
    echo "$domain" >> "$RESULTS"
    printf "%b[+] HTTP enabled:%b %s\n" "$GREEN" "$NC" "$domain"
  else
    printf "%b[-] No HTTP:%b %s\n" "$RED" "$NC" "$domain"
  fi
}

export -f check_http RESULTS GREEN RED NC


echo -e "${BLUE}========== HTTP WEAK PROTOCOL CHECK ==========${NC}"

grep -vE '^\s*$|^#' "$DOMAINS_FILE" \
  | xargs -P "$JOBS" -n 1 bash -c 'check_http "$@"' _


echo
echo -e "${BLUE}================ SUMMARY ================${NC}"

if [ -s "$RESULTS" ]; then
  sort -u "$RESULTS"
else
  echo "No domains accessible over HTTP"
fi


rm -rf "$TMPDIR"
