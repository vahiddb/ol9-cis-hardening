#!/bin/bash
# Script: audit8.sh
# Purpose: Audit Command Line Warning Banners (CIS 1.7)

echo "=========================================================================="
echo " CIS Requirement: 1.7 Command Line Warning Banners"
echo " - Ensure /etc/motd, /etc/issue, and /etc/issue.net are configured."
echo " - Ensure permissions are 644 and ownership is root:root."
echo " - Ensure no OS or kernel information is leaked."
echo " Oracle Context:"
echo " - Modifying warning banners has NO impact on Oracle Database/RAC."
echo " - Standard banners do not interfere with Oracle automated tasks."
echo "=========================================================================="

FAIL_COUNT=0
FILES=("/etc/motd" "/etc/issue" "/etc/issue.net")
OS_NAME=$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/"//g')

echo -e "\n[*] Auditing Warning Banners and Permissions..."

for FILE in "${FILES[@]}"; do
    echo "[*] Checking $FILE..."
    if [ -e "$FILE" ]; then
        # Check permissions and ownership
        STAT=$(stat -c "%a %U %G" "$FILE")
        if [ "$STAT" == "644 root root" ]; then
            echo -e "  \e[32m[PASS]\e[0m Permissions and ownership are correct ($STAT)."
        else
            echo -e "  \e[31m[FAIL]\e[0m Incorrect permissions/ownership. Current: $STAT (Expected: 644 root root)."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi

        # Check for OS information leaks
        if grep -E -i "(\\\v|\\\r|\\\m|\\\s|$OS_NAME)" "$FILE" > /dev/null 2>&1; then
            echo -e "  \e[31m[FAIL]\e[0m OS or Kernel information leakage detected."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        else
            echo -e "  \e[32m[PASS]\e[0m No OS information leaks detected."
        fi
    else
        echo -e "  \e[31m[FAIL]\e[0m File $FILE does not exist."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

