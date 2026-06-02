#!/bin/bash
# Script: audit12.sh
# Purpose: Audit Script for Time Sync (CIS 2.3)

echo "=========================================================================="
echo " CIS Requirement: 2.3 Time Synchronization"
echo " - Ensure time synchronization is in use and properly configured (Chrony)."
echo " Oracle Context:"
echo " - Time sync is CRITICAL for Oracle RAC/Grid Infrastructure."
echo " - 'chronyd' is the recommended time service for Oracle DB 19c/23ai on OL9."
echo " - When chronyd is active, Oracle CTSS automatically runs in Observer mode."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Auditing Time Synchronization (Chrony)..."

# 1. Check if chrony is installed
if rpm -q chrony &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m 'chrony' package is installed."
else
    echo -e "  \e[31m[FAIL]\e[0m 'chrony' package is NOT installed."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2. Check chrony configuration for servers/pools
if grep -E '^(server|pool)' /etc/chrony.conf &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Remote time servers are configured in /etc/chrony.conf."
else
    echo -e "  \e[31m[FAIL]\e[0m No remote time servers (server/pool) configured."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 3. Check if chrony runs as non-root (user 'chrony')
if grep -q 'OPTIONS.*-u chrony' /etc/sysconfig/chronyd 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m chronyd is configured to run as user 'chrony'."
else
    echo -e "  \e[31m[FAIL]\e[0m chronyd is NOT explicitly configured to run as user 'chrony'."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 4. Check service status
if systemctl is-enabled chronyd &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m chronyd service is enabled."
else
    echo -e "  \e[31m[FAIL]\e[0m chronyd service is NOT enabled."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

