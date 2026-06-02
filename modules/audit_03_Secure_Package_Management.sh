#!/bin/bash
# Script: audit_cis_1_2.sh
# Purpose: Audit DNF settings and Repositories (CIS 1.2)

echo "=========================================================================="
echo " CIS Requirement: 1.2 Package Management"
echo " - Ensure gpgcheck is globally activated (1.2.3)"
echo " - Ensure localpkg_gpgcheck is activated (1.2.4)"
echo " - Ensure no individual repos override gpgcheck=0"
echo " Oracle Context: 'repo_gpgcheck=0' is allowed for air-gapped environments."
echo "=========================================================================="

DNF_CONF="/etc/dnf/dnf.conf"
FAIL_COUNT=0

echo -e "\n[*] Auditing DNF global configurations in $DNF_CONF..."

check_dnf_option() {
    local opt=$1
    local expected=$2
    local val=$(grep "^${opt}=" "$DNF_CONF" | cut -d'=' -f2)
    
    if [ "$val" == "$expected" ]; then
        echo -e "  \e[32m[PASS]\e[0m $opt is set to $val"
    else
        echo -e "  \e[31m[FAIL]\e[0m $opt is not set to $expected (Current: ${val:-Not Set})"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_dnf_option "gpgcheck" "1"
check_dnf_option "localpkg_gpgcheck" "1"
check_dnf_option "repo_gpgcheck" "0"

echo -e "\n[*] Checking Repository Overrides (*.repo)..."
OVERRIDE_COUNT=$(grep -ir '^gpgcheck\s*=\s*0' /etc/yum.repos.d/ 2>/dev/null | wc -l)

if [ "$OVERRIDE_COUNT" -eq 0 ]; then
    echo -e "  \e[32m[PASS]\e[0m No repositories override gpgcheck to 0."
else
    echo -e "  \e[31m[FAIL]\e[0m Found repositories overriding gpgcheck to 0:"
    grep -ir '^gpgcheck\s*=\s*0' /etc/yum.repos.d/ | sed 's/^/    - /'
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Active Repositories:"
dnf repolist enabled 2>/dev/null | awk 'NR>1 {print "  - " $0}'

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

