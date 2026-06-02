#!/bin/bash
# Script: audit16.sh
# Purpose: Audit Script for SSH Service (CIS 5.1)

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[!] Please run as root\e[0m"
    exit 1
fi

FAIL_COUNT=0

echo "=========================================================================="
echo " Audit Script for SSH Service (CIS 5.1)"
echo " Oracle Context: AllowGroups must include 'dba'. "
echo " Oracle Exception: X11Forwarding is YES for Oracle GUI tools (DBCA, etc)."
echo "=========================================================================="

check_sshd_param() {
    local param=$1
    local expected=$2
    local actual=$(sshd -T 2>/dev/null | grep -iw "^$param" | awk '{print $2}')
    
    if [[ "$param" == "allowgroups" ]]; then
        if echo "$actual" | grep -q "$expected"; then
            echo -e "  \e[32m[PASS]\e[0m $param contains '$expected'"
        else
            echo -e "  \e[31m[FAIL]\e[0m $param ($actual) does not contain '$expected'"
            ((FAIL_COUNT++))
        fi
        return
    fi

    if [ "$actual" == "$expected" ]; then
        echo -e "  \e[32m[PASS]\e[0m $param is set to $expected"
    else
        echo -e "  \e[31m[FAIL]\e[0m $param is '$actual' (Expected: $expected)"
        ((FAIL_COUNT++))
    fi
}

echo -e "\n[*] Checking active SSH parameters..."
check_sshd_param "permitrootlogin" "no"
check_sshd_param "x11forwarding" "yes"     # <--- Oracle Exception: YES
check_sshd_param "clientaliveinterval" "300"
check_sshd_param "clientalivecountmax" "3"
check_sshd_param "disableforwarding" "yes"
check_sshd_param "gssapiauthentication" "no"
check_sshd_param "logingracetime" "60"
check_sshd_param "maxauthtries" "4"
check_sshd_param "maxsessions" "10"
check_sshd_param "permitemptypasswords" "no"
check_sshd_param "allowgroups" "dba"

echo -e "\n[*] Checking Permissions for sshd_config and Keys..."
SSHD_PERM=$(stat -c "%a" /etc/ssh/sshd_config)
if [ "$SSHD_PERM" == "600" ]; then
    echo -e "  \e[32m[PASS]\e[0m /etc/ssh/sshd_config has permissions 600"
else
    echo -e "  \e[31m[FAIL]\e[0m /etc/ssh/sshd_config has permissions $SSHD_PERM (Expected: 600)"
    ((FAIL_COUNT++))
fi

echo "=========================================================================="
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\e[32m[+] AUDIT PASSED: All SSH settings meet CIS/Oracle requirements.\e[0m"
else
    echo -e "\e[31m[-] AUDIT FAILED: $FAIL_COUNT issue(s) found. Run remediation16.sh.\e[0m"
fi

