# Nmap XML → HTML Scanner
 
A Bash automation script that performs **Nmap service & script scans**, exports results to **XML**, and generates a **Bootstrap-based HTML report** using `nmap-bootstrap.xsl`.
 
Designed for **pentesting, audits, and reporting**.
 
---
 
## ✨ Features
 
- Interactive scan mode selection
  - ⚡ **FAST scan** (top ports)
  - 🔍 **Custom port range**
  - 🔥 **Full scan** (all 65,535 ports)
- Automatic dependency handling
  - Installs `xsltproc` if missing
- Automatic download of `nmap-bootstrap.xsl`
- Nmap scan with:
  - Service detection (`-sV`)
  - Default safe scripts (`-sC`)
- Generates:
  - 📄 XML output
  - 🌐 Clean HTML report (Bootstrap)
- Pentest-ready output for tools like:
  - DefectDojo
  - Faraday
  - Dradis
 
---
 
## 📦 Requirements
 
- Linux (Kali, Ubuntu, Debian)
- `nmap`
- `wget`
- `sudo` privileges (for dependency installation)
 
---
 
## 📁 Files Generated
 
| File | Description |
|-----|------------|
| `output.xml` | Raw Nmap XML output |
| `report.html` | Human-readable HTML report |
| `nmap-bootstrap.xsl` | XSL stylesheet (auto-downloaded) |
 
---
 
## 🚀 Installation
 
Clone or copy the script
 
```bash
chmod +x nmap_report.sh
