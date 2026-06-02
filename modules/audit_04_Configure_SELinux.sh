#!/bin/bash
# Script: audit_cis_1_3_1.sh
# Purpose: Audit SELinux Configurations (CIS 1.3.1)

echo "=========================================================================="
echo " CIS Requirement: 1.3.1 Configure SELinux"
echo " - Ensure SELinux is installed, enforcing, and targeted."
echo " - Ensure mcstrans and setroubleshoot are not installed."
echo " - Ensure bootloader has no selinux=0 or enforcing=0."
echo " Oracle Context: Oracle Database (19c/23ai) fully supports SELinux in"
echo " 'Enforcing' and 'Targeted' mode. In Oracle RAC/Grid, some Clusterware"
echo " temp files may need proper labels, but disabling SELinux is NOT required."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] 1. Checking SELinux Packages..."
if rpm -q libselinux >/dev/null 2>&1; then
    echo -e "  \e[32m[PASS]\e[0m libselinux is installed."
else
    echo -e "  \e[31m[FAIL]\e[0m libselinux is NOT installed."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if rpm -q mcstrans setroubleshoot >/dev/null 2>&1; then
    echo -e "  \e[31m[FAIL]\e[0m Unsafe packages (mcstrans/setroubleshoot) are installed."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m Unsafe packages are NOT installed."
fi

echo -e "\n[*] 2. Checking Bootloader configurations..."
if grubby --info=ALL | grep -E 'selinux=0|enforcing=0' >/dev/null 2>&1; then
    echo -e "  \e[31m[FAIL]\e[0m SELinux is disabled in bootloader (grub)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m Bootloader parameters are clean."
fi

echo -e "\n[*] 3. Checking SELinux Config File (/etc/selinux/config)..."
if grep -Eq '^SELINUX=enforcing' /etc/selinux/config; then
    echo -e "  \e[32m[PASS]\e[0m SELINUX is set to enforcing in config."
else
    echo -e "  \e[31m[FAIL]\e[0m SELINUX is NOT set to enforcing in config."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -Eq '^SELINUXTYPE=targeted' /etc/selinux/config; then
    echo -e "  \e[32m[PASS]\e[0m SELINUXTYPE is set to targeted in config."
else
    echo -e "  \e[31m[FAIL]\e[0m SELINUXTYPE is NOT set to targeted in config."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 4. Checking Current SELinux Status..."
CURRENT_MODE=$(getenforce)
if [ "$CURRENT_MODE" == "Enforcing" ]; then
    echo -e "  \e[32m[PASS]\e[0m Current SELinux mode is Enforcing."
else
    echo -e "  \e[31m[FAIL]\e[0m Current SELinux mode is $CURRENT_MODE."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 5. Checking for Unconfined Services..."
UNCONFINED=$(ps -eZ | grep unconfined_service_t)
if [ -z "$UNCONFINED" ]; then
    echo -e "  \e[32m[PASS]\e[0m No unconfined services found."
else
    echo -e "  \e[33m[WARN]\e[0m Unconfined services detected (Manual check required):"
    echo "$UNCONFINED" | awk '{print "    - " $NF}'
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

