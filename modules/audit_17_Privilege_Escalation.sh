#!/bin/bash
# Script: audit17.sh
# Purpose: Audit Script for Sudo and su (CIS 5.3 & 5.6)

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[!] Please run as root\e[0m"
    exit 1
fi

FAIL_COUNT=0

echo "=========================================================================="
echo " Audit Script for Sudo & su (CIS 5.3 & 5.6)"
echo " Oracle Context: oracle/grid users need 'su -' access without being sudoers."
echo " Oracle Exception: Using custom 'sugroup' instead of default 'wheel'."
echo "=========================================================================="

echo -e "\n[*] Checking if sudo is installed..."
if rpm -q sudo >/dev/null 2>&1; then
    echo -e "  \e[32m[PASS]\e[0m sudo is installed"
else
    echo -e "  \e[31m[FAIL]\e[0m sudo is not installed"
    ((FAIL_COUNT++))
fi

echo -e "\n[*] Checking sudo configuration (Defaults)..."
check_sudo_default() {
    local param=$1
    if grep -rEi "^\s*Defaults\s+([^#]+,\s*)?${param}" /etc/sudoers /etc/sudoers.d/* >/dev/null 2>&1; then
        echo -e "  \e[32m[PASS]\e[0m sudo is configured with $param"
    else
        echo -e "  \e[31m[FAIL]\e[0m sudo is missing configuration for $param"
        ((FAIL_COUNT++))
    fi
}

check_sudo_default "use_pty"
check_sudo_default "logfile"
check_sudo_default "timestamp_timeout"

echo -e "\n[*] Checking for '!authenticate' in sudoers..."
if grep -rEi "^\s*[^#].*!authenticate" /etc/sudoers /etc/sudoers.d/* >/dev/null 2>&1; then
    echo -e "  \e[31m[FAIL]\e[0m Found '!authenticate' in sudo configuration"
    ((FAIL_COUNT++))
else
    echo -e "  \e[32m[PASS]\e[0m No '!authenticate' found in sudo configuration"
fi

echo -e "\n[*] Checking 'su' restrictions (pam_wheel.so) and groups..."
if grep -Eq "^\s*auth\s+(required|requisite)\s+pam_wheel\.so\s+.*group=sugroup" /etc/pam.d/su; then
    echo -e "  \e[32m[PASS]\e[0m pam_wheel.so is configured with group=sugroup in /etc/pam.d/su"
else
    echo -e "  \e[31m[FAIL]\e[0m pam_wheel.so with group=sugroup is not properly configured in /etc/pam.d/su"
    ((FAIL_COUNT++))
fi

# Check if sugroup exists and users are members
if getent group sugroup >/dev/null 2>&1; then
    echo -e "  \e[32m[PASS]\e[0m Group 'sugroup' exists"
    for u in oracle grid; do
        if id "$u" >/dev/null 2>&1; then # Check if user exists on system
            if id -nG "$u" | grep -qw "sugroup"; then
                echo -e "  \e[32m[PASS]\e[0m User $u is a member of 'sugroup'"
            else
                echo -e "  \e[31m[FAIL]\e[0m User $u is NOT a member of 'sugroup'"
                ((FAIL_COUNT++))
            fi
        fi
    done
else
    echo -e "  \e[31m[FAIL]\e[0m Group 'sugroup' does not exist"
    ((FAIL_COUNT++))
fi

# Ensure Oracle users are NOT in wheel group
for u in oracle grid; do
    if id "$u" >/dev/null 2>&1; then
        if id -nG "$u" | grep -qw "wheel"; then
            echo -e "  \e[31m[FAIL]\e[0m User $u is in 'wheel' (Should be removed to prevent sudo access)"
            ((FAIL_COUNT++))
        else
            echo -e "  \e[32m[PASS]\e[0m User $u is safely NOT in 'wheel'"
        fi
    fi
done

echo "=========================================================================="
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\e[32m[+] AUDIT PASSED: All Sudo & su settings meet CIS/Oracle requirements.\e[0m"
else
    echo -e "\e[31m[-] AUDIT FAILED: $FAIL_COUNT issue(s) found. Run remediation17.sh.\e[0m"
fi

