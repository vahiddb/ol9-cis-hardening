#!/bin/bash
# Script: remediate_cis_7_2.sh
# Purpose: Remediate obvious issues in Local User Settings

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Remediating CIS 7.2..."

echo "[*] Ensuring shadowed passwords (pwconv)..."
pwconv

echo "[*] Locking accounts with empty passwords..."
for user in $(awk -F: '($2 == "" ) { print $1 }' /etc/shadow); do
    echo "Locking account $user due to empty password."
    passwd -l "$user"
done

echo "[*] Fixing permissions on interactive user home directories..."
awk -F: '($3 >= 1000 && $1 != "nfsnobody") { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
    if [ -d "$dir" ]; then
        chmod g-w,o-rwx "$dir"
        
        # Securing dot files
        find "$dir" -type f -name ".*" -exec chmod go-w {} \; 2>/dev/null
    fi
done

echo "[+] Automated remediation applied."
echo "[!] Action Required: Duplicate UIDs, GIDs, and Usernames must be resolved manually."
