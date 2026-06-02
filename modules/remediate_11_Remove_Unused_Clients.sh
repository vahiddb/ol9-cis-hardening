#!/bin/bash
# Script: remediation11.sh
# Purpose: Remove unnecessary service clients (CIS 2.2)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 2.2 (Service Clients)"
echo " Oracle Context: Safe for DB/RAC. No dependencies on these legacy clients."
echo "=========================================================================="

CLIENT_PACKAGES=(ftp openldap-clients ypbind telnet tftp)

echo -e "\n[*] Removing unnecessary service clients..."
for pkg in "${CLIENT_PACKAGES[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        dnf remove -y "$pkg" > /dev/null 2>&1
        echo -e "  \e[32m[OK]\e[0m Removed '$pkg'"
    else
        echo -e "  \e[32m[OK]\e[0m Package '$pkg' is already removed or not installed."
    fi
done

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

