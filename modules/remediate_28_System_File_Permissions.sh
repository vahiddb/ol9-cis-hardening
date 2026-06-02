#!/bin/bash
# Script: remediate_cis_7_1.sh
# Purpose: Fix permissions and ownership for system credential files

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Remediating CIS 7.1..."

chown root:root /etc/passwd /etc/passwd- /etc/group /etc/group- /etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow- /etc/shells /etc/security/opasswd 2>/dev/null

chmod 0644 /etc/passwd
chmod 0600 /etc/passwd-
chmod 0644 /etc/group
chmod 0600 /etc/group-
chmod 0000 /etc/shadow
chmod 0000 /etc/shadow-
chmod 0000 /etc/gshadow
chmod 0000 /etc/gshadow-
chmod 0644 /etc/shells
chmod 0600 /etc/security/opasswd 2>/dev/null || touch /etc/security/opasswd && chmod 0600 /etc/security/opasswd

echo "[+] Basic file permissions applied successfully."
echo "[!] Action Required: You must manually investigate and fix unowned files, world-writable files, and review SUID/SGID binaries (CIS 7.1.11 - 7.1.13)."
