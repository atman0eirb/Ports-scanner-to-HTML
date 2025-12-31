#!/bin/bash
 
# ==========================
# BANNER
# ==========================
clear
cat << "EOF"
_   _ __  __    _    ____  
| \ | |  \/  |  / \  |  _ \ 
|  \| | |\/| | / _ \ | |_) |
| |\  | |  | |/ ___ \|  __/ 
|_| \_|_|  |_/_/   \_\_|    
 
   Nmap XML → HTML Scanner
   Service & Script Scan
   Bootstrap Report
=================================
EOF
 
sleep 1
 
# ==========================
# CONFIGURATION
# ==========================
TARGETS_FILE="$1"
XML_OUTPUT="output.xml"
HTML_REPORT="report.html"
XSL_FILE="nmap-bootstrap.xsl"
XSL_URL="https://raw.githubusercontent.com/Haxxnet/nmap-bootstrap-xsl/main/nmap-bootstrap.xsl"
 
# ==========================
# CHECK ARGUMENT
# ==========================
if [[ -z "$TARGETS_FILE" ]]; then
    echo "[!] Usage: $0 targets.txt"
    exit 1
fi
 
if [[ ! -f "$TARGETS_FILE" ]]; then
    echo "[!] Targets file not found: $TARGETS_FILE"
    exit 1
fi
 
# ==========================
# CHECK xsltproc
# ==========================
if ! command -v xsltproc >/dev/null 2>&1; then
    echo "[*] xsltproc not found. Installing..."
    sudo apt update && sudo apt install -y xsltproc
else
    echo "[+] xsltproc is already installed"
fi
 
# ==========================
# DOWNLOAD nmap-bootstrap.xsl
# ==========================
if [[ ! -f "$XSL_FILE" ]]; then
    echo "[*] Downloading nmap-bootstrap.xsl..."
    wget -q "$XSL_URL" -O "$XSL_FILE" || {
        echo "[!] Download failed"
        exit 1
    }
else
    echo "[+] nmap-bootstrap.xsl found"
fi
 
# ==========================
# ASK SCAN MODE
# ==========================
echo
read -p "[?] Do you want a FAST Nmap scan? (y/n): " FAST_SCAN
 
if [[ "$FAST_SCAN" =~ ^[Yy]$ ]]; then
    NMAP_PORTS="-F"
    SCAN_LABEL="FAST scan (top ports)"
else
    echo
    read -p "[?] Enter port range (example: 1-65353) or 'all': " PORT_RANGE
 
    if [[ "$PORT_RANGE" == "all" ]]; then
        NMAP_PORTS="-p-"
        SCAN_LABEL="FULL scan (all ports)"
    elif [[ "$PORT_RANGE" =~ ^[0-9]+-[0-9]+$ ]]; then
        NMAP_PORTS="-p $PORT_RANGE"
        SCAN_LABEL="Custom port range ($PORT_RANGE)"
    else
        echo "[!] Invalid port format"
        exit 1
    fi
fi
 
echo "[+] Selected mode: $SCAN_LABEL"
 
# ==========================
# RUN NMAP
# ==========================
echo
echo "[*] Starting Nmap scan..."
nmap -sV -sC $NMAP_PORTS -iL "$TARGETS_FILE" -oX "$XML_OUTPUT" || {
    echo "[!] Nmap scan failed"
    exit 1
}
 
# ==========================
# GENERATE HTML REPORT
# ==========================
echo
echo "[*] Generating HTML report..."
xsltproc -o "$HTML_REPORT" "$XSL_FILE" "$XML_OUTPUT" || {
    echo "[!] HTML generation failed"
    exit 1
}
 
# ==========================
# DONE
# ==========================
echo
echo "[+] Scan completed successfully"
echo "[+] XML report  : $(realpath "$XML_OUTPUT")"
echo "[+] HTML report : $(realpath "$HTML_REPORT")"
