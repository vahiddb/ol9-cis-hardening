#!/bin/bash
# Script: audit11.sh
# Purpose: Audit for Service Clients (CIS 2.2)

echo "=========================================================================="
echo " CIS Requirement: 2.2 Service Clients"
echo " - Ensure unnecessary client packages are not installed."
echo " Oracle Context:"
echo " - Oracle DB/Grid uses SQL*Net and built-in LDAP resolution libraries."
echo " - OS-level clients like ftp, telnet, and openldap-clients are NOT needed."
echo "=========================================================================="

FAIL_COUNT=0
CLIENT_PACKAGES=(ftp openldap-clients ypbind telnet tftp)

echo -e "\n[*] Auditing Service Clients..."
for pkg in "${CLIENT_PACKAGES[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        echo -e "  \e[31m[FAIL]\e[0m Package '$pkg' is INSTALLED."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo -e "  \e[32m[PASS]\e[0m Package '$pkg' is NOT installed."
    fi
done

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

