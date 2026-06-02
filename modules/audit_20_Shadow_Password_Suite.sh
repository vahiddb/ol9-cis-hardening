#!/bin/bash
# Script: audit20.sh
# Purpose: Audit Script for Password Expiration & Aging (CIS Section 20)

echo "=========================================================================="
echo " CIS Requirement: Password Aging Policies (/etc/login.defs & Shadow)"
echo " - Ensure password expiration is 365 days or less (PASS_MAX_DAYS)."
echo " - Ensure minimum days between changes is 1 or more (PASS_MIN_DAYS)."
echo " - Ensure inactive password lock is 30 days or less (INACTIVE)."
echo " - Ensure all passwords have a valid change date (not in the future)."
echo " Oracle Context:"
echo " - WARNING: Enforcing expiration (PASS_MAX_DAYS) on database service"
echo "   accounts ('oracle', 'grid') will cause critical cluster and database"
echo "   outages. Service accounts must be explicitly excluded from aging."
echo "=========================================================================="

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Please run as root\e[0m"
  exit 1
fi

FAIL_COUNT=0

echo -e "\n[*] Checking /etc/login.defs parameters..."
check_login_defs() {
    local param=$1
    local expected=$2
    local current=$(grep -E "^\s*${param}\b" /etc/login.defs | awk '{print $2}')
    
    if [ "$current" == "$expected" ]; then
        echo -e "  \e[32m[PASS]\e[0m $param is $current"
    else
        echo -e "  \e[31m[FAIL]\e[0m $param is $current (Expected: $expected)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_login_defs "PASS_MAX_DAYS" "365"
check_login_defs "PASS_MIN_DAYS" "1"
check_login_defs "PASS_WARN_AGE" "7"
check_login_defs "ENCRYPT_METHOD" "YESCRYPT"

echo -e "\n[*] Checking Default Inactive Lock..."
inactive_val=$(useradd -D | grep INACTIVE | cut -d= -f2)
if [ "$inactive_val" == "30" ]; then
    echo -e "  \e[32m[PASS]\e[0m INACTIVE is set to $inactive_val"
else
    echo -e "  \e[31m[FAIL]\e[0m INACTIVE is set to $inactive_val (Expected: 30)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking for passwords changed in the future (/etc/shadow)..."
# Fix for the broken awk command in the original script
CURRENT_EPOCH=$(date +%s)
CURRENT_DAYS=$((CURRENT_EPOCH / 86400))
FUTURE_USERS=$(awk -v now="$CURRENT_DAYS" -F: '($2 != "!" && $2 != "*" && $2 != "" && $3 > now) {print $1}' /etc/shadow)

if [ -z "$FUTURE_USERS" ]; then
    echo -e "  \e[32m[PASS]\e[0m No accounts have a password change date in the future."
else
    echo -e "  \e[31m[FAIL]\e[0m Accounts with future password change dates: $(echo $FUTURE_USERS | tr '\n' ' ')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

