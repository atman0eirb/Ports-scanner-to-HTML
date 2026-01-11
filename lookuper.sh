#!/bin/bash

DOMAIN_FILE=$1
NSLOOKUP_FILE="nslookup.txt"

# Run nslookup on each domain and save output
while read -r domain; do
    nslookup "$domain"
done < "$DOMAIN_FILE" > "$NSLOOKUP_FILE"

# Extract IPv4 addresses, remove private IPs, sort & unique
IPS=$(grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$NSLOOKUP_FILE" \
    | grep -vE '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)' \
    | sort -u)

# Display results
echo ""
echo "Public IP addresses found:"
echo "$IPS"

# Remove temporary nslookup file
rm -f "$NSLOOKUP_FILE"
