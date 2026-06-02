#!/bin/bash
# Script: audit14.sh
# Purpose: Audit Script for Network & Sysctl (CIS 3)

echo "=========================================================================="
echo " CIS Requirement: 3 Network Configuration"
echo " - Ensure wireless/bluetooth and uncommon network protocols are disabled."
echo " - Ensure network sysctl parameters are securely configured."
echo " Oracle Context:"
echo " - ACCEPTED EXCEPTION: 'net.ipv4.conf.all.rp_filter' and 'default.rp_filter'"
echo "   are expected to be '2' (Loose) instead of '1' (Strict) due to Oracle"
echo "   RAC/Clusterware interconnect requirements."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Checking Wireless and Bluetooth..."
if nmcli radio all 2>/dev/null | grep -q "enabled"; then
    echo -e "  \e[31m[FAIL]\e[0m Wireless interfaces are not completely disabled."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m Wireless interfaces are disabled."
fi

if systemctl is-active bluetooth.service &>/dev/null; then
    echo -e "  \e[31m[FAIL]\e[0m Bluetooth service is active."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m Bluetooth service is inactive."
fi

echo -e "\n[*] Checking Network Modules (dccp, tipc, rds, sctp)..."
for mod in dccp tipc rds sctp; do
    if modprobe -n -v "$mod" 2>/dev/null | grep -q "install /bin/true"; then
        echo -e "  \e[32m[PASS]\e[0m Module $mod is disabled."
    else
        echo -e "  \e[31m[FAIL]\e[0m Module $mod is NOT properly disabled."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo -e "\n[*] Checking Network sysctl parameters..."
# rp_filter is set to 2 to comply with Oracle Preinstall requirements
params=(
    "net.ipv4.ip_forward=0"
    "net.ipv6.conf.all.forwarding=0"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.all.rp_filter=2" 
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv6.conf.all.accept_ra=0"
)

for p in "${params[@]}"; do
    key=$(echo "$p" | cut -d= -f1)
    expected=$(echo "$p" | cut -d= -f2)
    actual=$(sysctl -n "$key" 2>/dev/null)
    
    if [ "$actual" = "$expected" ]; then
        if [ "$key" == "net.ipv4.conf.all.rp_filter" ]; then
             echo -e "  \e[32m[PASS]\e[0m $key is set to $expected (Oracle Exception Applied)"
        else
             echo -e "  \e[32m[PASS]\e[0m $key is set to $expected"
        fi
    else
        echo -e "  \e[31m[FAIL]\e[0m $key is set to $actual (Expected: $expected)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

