#!/bin/bash
# Script: audit_cis_1_6.sh
# Purpose: Audit System-wide Crypto Policy (CIS 1.6)

echo "=========================================================================="
echo " CIS Requirement: 1.6 System-wide Crypto Policy"
echo " - Ensure system-wide crypto policy is set correctly (NO-SHA1, CIS-SSH)."
echo " - Ensure no hardcoded crypto settings exist in sshd_config."
echo " Oracle Context:"
echo " 1. Updating the system crypto policy is generally transparent to"
echo "    Oracle Database and RAC installations."
echo " 2. Removing hardcoded SSH ciphers ensures SSHD uses the system-wide"
echo "    secure policy without disrupting DBA remote access."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] 1. Checking System Crypto Policy..."
CURRENT_POLICY=$(update-crypto-policies --show 2>/dev/null)
if [[ "$CURRENT_POLICY" == *"DEFAULT:NO-SHA1:CIS-SSH"* || "$CURRENT_POLICY" == *"FIPS:NO-SHA1:CIS-SSH"* ]]; then
    echo -e "  \e[32m[PASS]\e[0m System Crypto Policy is $CURRENT_POLICY."
else
    echo -e "  \e[31m[FAIL]\e[0m Crypto Policy is $CURRENT_POLICY (Expected: DEFAULT:NO-SHA1:CIS-SSH)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 2. Checking sshd_config for hardcoded crypto settings..."
HARDCODED=$(grep -h -E -i '^\s*(Ciphers|MACs|KexAlgorithms|GSSAPIKexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedKeyTypes)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)

if [ -z "$HARDCODED" ]; then
    echo -e "  \e[32m[PASS]\e[0m No hardcoded crypto settings found in SSH config."
else
    echo -e "  \e[31m[FAIL]\e[0m Hardcoded crypto settings found:"
    echo "$HARDCODED"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

