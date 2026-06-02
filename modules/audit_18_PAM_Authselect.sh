#!/bin/bash
# Script: audit18.sh
# Purpose: Audit Script for PAM, Authselect & Oracle Faillock Bypass (CIS 5.3)

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[!] Please run as root\e[0m"
    exit 1
fi

FAIL_COUNT=0

echo "=========================================================================="
echo " Audit Script for PAM Packages & Authselect Profile (CIS 5.3)"
echo " Context: EL9 authselect requires 'with-faillock' and 'without-nullok'."
echo " Exception (Oracle): 'oracle' and 'grid' must be bypassed in PAM to avoid DB outage."
echo "=========================================================================="

echo -e "\n[*] Checking required PAM packages..."
check_package() {
    local pkg=$1
    if rpm -q "$pkg" >/dev/null 2>&1; then
        echo -e "  \e[32m[PASS]\e[0m Package '$pkg' is installed"
    else
        echo -e "  \e[31m[FAIL]\e[0m Package '$pkg' is NOT installed"
        ((FAIL_COUNT++))
    fi
}

check_package "pam"
check_package "authselect"
check_package "libpwquality"

echo -e "\n[*] Checking Authselect Profile configuration..."
CURRENT_PROFILE=$(authselect current 2>/dev/null | head -n 1 | awk '{print $3}')

if [ -z "$CURRENT_PROFILE" ] || [[ "$CURRENT_PROFILE" == "No" ]]; then
    echo -e "  \e[31m[FAIL]\e[0m No authselect profile is currently active"
    ((FAIL_COUNT++))
else
    echo -e "  \e[32m[PASS]\e[0m Active authselect profile: $CURRENT_PROFILE"
    
    check_authselect_feature() {
        local feature=$1
        if authselect current 2>/dev/null | grep -qw "$feature"; then
            echo -e "  \e[32m[PASS]\e[0m Feature '$feature' is enabled"
        else
            echo -e "  \e[31m[FAIL]\e[0m Feature '$feature' is missing"
            ((FAIL_COUNT++))
        fi
    }

    check_authselect_feature "with-faillock"
    check_authselect_feature "without-nullok"
fi

echo -e "\n[*] Checking Oracle/Grid Faillock Bypass..."
if grep -q "pam_succeed_if.so user in oracle:grid" /etc/pam.d/system-auth 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Oracle/Grid accounts are successfully excluded from faillock rules"
else
    echo -e "  \e[31m[FAIL]\e[0m Oracle/Grid accounts are NOT excluded from faillock (High Risk for DB!)"
    ((FAIL_COUNT++))
fi

echo "=========================================================================="
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\e[32m[+] AUDIT PASSED: PAM, Authselect, and Oracle Exceptions are perfectly configured.\e[0m"
else
    echo -e "\e[31m[-] AUDIT FAILED: $FAIL_COUNT issue(s) found. Run remediation18.sh.\e[0m"
fi

