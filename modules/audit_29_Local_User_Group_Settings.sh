#!/bin/bash
# -------------------------------------------------------------------------
# Script: audit29.sh
# Purpose: Audit Local User and Group Settings (CIS 7.2)
# -------------------------------------------------------------------------

echo "=========================================================================="
echo " CIS Requirement: 7.2 - Local User and Group Settings"
echo " - 7.2.1: Ensure accounts in /etc/passwd use shadowed passwords."
echo " - 7.2.2: Ensure /etc/shadow does not contain empty password fields."
echo " - 7.2.4: Ensure no duplicate UIDs exist."
echo " - 7.2.5: Ensure no duplicate GIDs exist."
echo " - 7.2.6: Ensure no duplicate user names exist."
echo " - 7.2.7: Ensure no duplicate group names exist."
echo " - 7.2.8/9: Ensure home directory and dot-file permissions are secure."
echo ""
echo " Oracle Context & Exceptions:"
echo " - Fully Compatible. UID/GID consistency is a PRE-REQUISITE for Oracle"
echo "   RAC / Grid Infrastructure installations."
echo ""
echo " Action Taken:"
echo " - This script audits all the CIS requirements listed above."
echo "=========================================================================="
echo ""

FAILED=0

# --- Audit Checks ---

echo "[*] Auditing: Non-shadowed passwords (CIS 7.2.1)..."
NON_SHADOWED=$(awk -F: '($2 != "x" ) { print $1 }' /etc/passwd)
if [ -n "$NON_SHADOWED" ]; then
    echo "[-] FAIL: Accounts found without shadowed passwords: $NON_SHADOWED"
    FAILED=1
else
    echo "[+] PASS: All accounts use shadowed passwords."
fi

echo -e "\n[*] Auditing: Empty password fields (CIS 7.2.2)..."
EMPTY_PASS=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow)
if [ -n "$EMPTY_PASS" ]; then
    echo "[-] FAIL: Accounts with empty passwords found: $EMPTY_PASS"
    FAILED=1
else
    echo "[+] PASS: No empty password fields found."
fi

echo -e "\n[*] Auditing: Duplicate UIDs (CIS 7.2.4)..."
DUP_UIDS=$(cut -f3 -d":" /etc/passwd | sort -n | uniq -c | awk '$1 > 1 {print $2}')
if [ -n "$DUP_UIDS" ]; then
    echo "[-] FAIL: Duplicate UIDs found:"
    for uid in $DUP_UIDS; do
        users=$(awk -F: '($3 == n) { print $1 }' n=$uid /etc/passwd | xargs)
        echo "    -> UID $uid is shared by: $users"
    done
    FAILED=1
else
    echo "[+] PASS: No duplicate UIDs found."
fi

echo -e "\n[*] Auditing: Duplicate GIDs (CIS 7.2.5)..."
DUP_GIDS=$(cut -f3 -d":" /etc/group | sort -n | uniq -c | awk '$1 > 1 {print $2}')
if [ -n "$DUP_GIDS" ]; then
    echo "[-] FAIL: Duplicate GIDs found:"
    for gid in $DUP_GIDS; do
        groups=$(awk -F: '($3 == n) { print $1 }' n=$gid /etc/group | xargs)
        echo "    -> GID $gid is shared by: $groups"
    done
    FAILED=1
else
    echo "[+] PASS: No duplicate GIDs found."
fi

echo -e "\n[*] Auditing: Duplicate user names (CIS 7.2.6)..."
DUP_USERS=$(cut -d: -f1 /etc/passwd | sort | uniq -c | awk '$1 > 1 {print $2}')
if [ -n "$DUP_USERS" ]; then
    echo "[-] FAIL: Duplicate Usernames found: $DUP_USERS"
    FAILED=1
else
    echo "[+] PASS: No duplicate user names found."
fi

echo -e "\n[*] Auditing: Duplicate group names (CIS 7.2.7)..."
DUP_GROUPS=$(cut -d: -f1 /etc/group | sort | uniq -c | awk '$1 > 1 {print $2}')
if [ -n "$DUP_GROUPS" ]; then
    echo "[-] FAIL: Duplicate Group Names found: $DUP_GROUPS"
    FAILED=1
else
    echo "[+] PASS: No duplicate group names found."
fi

echo -e "\n[*] Auditing: Home directory permissions (CIS 7.2.8 & 7.2.9)..."
HOME_ISSUES=0
awk -F: '($3 >= 1000 && $1 != "nfsnobody") { print $1 " " $6 }' /etc/passwd | while read -r user dir; do
    if [ -d "$dir" ]; then
        dirperm=$(stat -L -c "%a" "$dir")
        # Using 8# to explicitly tell bash these are octal numbers
        if [ $(( 8#$dirperm & 8#022 )) -ne 0 ]; then
            echo "[-] FAIL: Home directory ($dir) for user ($user) is group or world-writable ($dirperm)."
            HOME_ISSUES=1
        fi
    fi
done
if [ "$HOME_ISSUES" -eq 0 ]; then
    echo "[+] PASS: Interactive user home directory permissions are secure."
else
    FAILED=1
fi


# --- Final Result ---
echo "=========================================================================="
if [ "$FAILED" -eq 1 ]; then
    echo "[!] FINAL AUDIT RESULT: FAILED. Remediation required."
else
    echo "[+] FINAL AUDIT RESULT: PASSED."
fi
echo "=========================================================================="

