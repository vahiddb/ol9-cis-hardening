#!/bin/bash
# Script: audit19.sh
# Purpose: Audit Script for Faillock & Password Quality (CIS Section 19)

echo "=========================================================================="
echo " CIS Requirement: Password Policies & Lockout Mechanisms"
echo " - Ensure faillock locks out users after 5 failed attempts for 15 mins."
echo " - Ensure pwquality enforces complexity (length, classes, dictcheck)."
echo " - Ensure password history remembers last 5 passwords."
echo " - Ensure yescrypt is used for password hashing."
echo " Oracle Context:"
echo " - WARNING: Strict faillock policies can lock out 'oracle' and 'grid'"
echo "   users during automated deployments (Ansible/Terraform). A PAM bypass"
echo "   should be implemented (covered in Sec 18) to avoid database outages."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Checking faillock configuration (/etc/security/faillock.conf)..."
for param in "deny = 5" "unlock_time = 900" "even_deny_root"; do
    if grep -q -E "^\s*${param}" /etc/security/faillock.conf; then
        echo -e "  \e[32m[PASS]\e[0m $param is configured."
    else
        echo -e "  \e[31m[FAIL]\e[0m $param is missing or incorrect."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo -e "\n[*] Checking pwquality configuration (/etc/security/pwquality.conf)..."
for param in "difok = 8" "minlen = 14" "minclass = 4" "maxrepeat = 3" "maxsequence = 3" "dictcheck = 1" "enforce_for_root"; do
    if grep -q -E "^\s*${param}" /etc/security/pwquality.conf; then
        echo -e "  \e[32m[PASS]\e[0m $param is configured."
    else
        echo -e "  \e[31m[FAIL]\e[0m $param is missing or incorrect."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo -e "\n[*] Checking PAM configurations for pwhistory and yescrypt..."
for pam_file in /etc/authselect/system-auth /etc/authselect/password-auth; do
    echo -e "  \e[34m[INFO]\e[0m Checking $pam_file..."
    
    if grep -E '^\s*password\s+requisite\s+pam_pwhistory.so' $pam_file | grep -q 'remember=5' && \
       grep -E '^\s*password\s+requisite\s+pam_pwhistory.so' $pam_file | grep -q 'enforce_for_root'; then
        echo -e "  \e[32m[PASS]\e[0m pwhistory is set correctly."
    else
        echo -e "  \e[31m[FAIL]\e[0m Missing correct pwhistory settings."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if grep -E '^\s*password\s+(sufficient|required)\s+pam_unix.so' $pam_file | grep -q 'yescrypt'; then
        echo -e "  \e[32m[PASS]\e[0m pam_unix is using yescrypt."
    else
        echo -e "  \e[31m[FAIL]\e[0m yescrypt is not configured."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

