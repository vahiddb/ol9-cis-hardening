#!/bin/bash
# Script: audit21.sh
# Purpose: Audit System Accounts, Umask, TMOUT & UID 0 (CIS 5.4.2 & 5.4.3)

echo "=========================================================================="
echo " CIS Requirement: User Accounts and Environment"
echo " - Ensure only 'root' has UID 0."
echo " - Ensure system accounts are non-login (shell /sbin/nologin)."
echo " - Ensure default user umask is 027."
echo " - Ensure TMOUT is 900 or less."
echo " Oracle Context & Exceptions:"
echo " - EXCEPTION: Oracle/Grid users require umask 022 for installation/operation."
echo " - WARNING: TMOUT=900 may disconnect long-running DBA scripts."
echo "=========================================================================="

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Please run as root\e[0m"
  exit 1
fi

FAIL_COUNT=0

echo -e "\n[*] Checking for UID 0 Accounts..."
UID_0_USERS=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)
if [ "$UID_0_USERS" == "root" ]; then
    echo -e "  \e[32m[PASS]\e[0m Only 'root' has UID 0."
else
    echo -e "  \e[31m[FAIL]\e[0m Non-root accounts with UID 0 found: $UID_0_USERS"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking System Accounts (Interactive Shell)..."
MIN_UID=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
SYS_USERS_WITH_SHELL=$(awk -F: -v min_uid="$MIN_UID" '
    $3 < min_uid && $1 != "root" && $1 != "sync" && $1 != "shutdown" && $1 != "halt" && $7 != "/sbin/nologin" && $7 != "/bin/false" {print $1}
' /etc/passwd)

if [ -z "$SYS_USERS_WITH_SHELL" ]; then
    echo -e "  \e[32m[PASS]\e[0m No system accounts have an interactive shell."
else
    echo -e "  \e[31m[FAIL]\e[0m System accounts with valid shell: $(echo $SYS_USERS_WITH_SHELL | tr '\n' ' ')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking Global Umask..."
if grep -q "umask 027" /etc/profile.d/umask.sh 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Default umask 027 is configured."
else
    echo -e "  \e[31m[FAIL]\e[0m Default umask 027 not found in /etc/profile.d/umask.sh."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking TMOUT..."
if grep -Eq "^\s*readonly TMOUT=900" /etc/profile.d/tmout.sh 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m TMOUT is securely configured to 900 seconds."
else
    echo -e "  \e[31m[FAIL]\e[0m TMOUT is not correctly set to 900 in /etc/profile.d/tmout.sh."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

