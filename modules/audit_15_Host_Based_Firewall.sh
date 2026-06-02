#!/bin/bash
# Script: audit15.sh
# Purpose: Audit Script for Firewall (CIS 4)

echo "=========================================================================="
echo " CIS Requirement: 4 Firewall Configuration"
echo " - Ensure firewalld is active and using nftables backend."
echo " Oracle Context:"
echo " - CRITICAL: Oracle RAC requires specific public ports (1521, 1522, 6200)."
echo " - CRITICAL: RAC Private Interconnect interface MUST be trusted."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Checking firewalld service status..."
if systemctl is-active firewalld.service &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m firewalld is active and running."
else
    echo -e "  \e[31m[FAIL]\e[0m firewalld is not active."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking FirewallBackend in firewalld.conf..."
BACKEND=$(grep -i '^FirewallBackend' /etc/firewalld/firewalld.conf | cut -d= -f2)
if [ "$BACKEND" == "nftables" ]; then
    echo -e "  \e[32m[PASS]\e[0m FirewallBackend is set to nftables."
else
    echo -e "  \e[31m[FAIL]\e[0m FirewallBackend is set to $BACKEND (Expected: nftables)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] Checking currently open ports (Public Zone)..."
PORTS=$(firewall-cmd --list-ports 2>/dev/null)
if [ -n "$PORTS" ]; then
    echo -e "  \e[34m[INFO]\e[0m Open ports: $PORTS"
else
    echo -e "  \e[34m[INFO]\e[0m No ports explicitly opened in default zone."
fi

echo -e "\n[*] Checking Trusted Interfaces (For RAC Private Interconnect)..."
TRUSTED_IFACES=$(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null)
if [ -n "$TRUSTED_IFACES" ]; then
    echo -e "  \e[32m[PASS]\e[0m Trusted interfaces found: $TRUSTED_IFACES"
else
    echo -e "  \e[33m[WARN]\e[0m No interfaces in 'trusted' zone. (Ensure RAC interconnect is trusted!)"
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m (Check warnings manually)"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

