#!/bin/bash
# Script: audit22.sh
# Purpose: Audit File Integrity Monitoring (AIDE) (CIS 6.1)

echo "=========================================================================="
echo " CIS Requirement: File Integrity Monitoring (AIDE)"
echo " - Ensure AIDE is installed (CIS 6.1.1)."
echo " - Ensure filesystem integrity is regularly checked (CIS 6.1.2)."
echo " - Ensure cryptographic mechanisms protect audit tools (CIS 6.1.3)."
echo " Oracle Context & Exceptions:"
echo " - EXCEPTION: Oracle/Grid directories (/u01, /u02, etc.) MUST be excluded"
echo "   from AIDE checks to prevent severe I/O performance degradation."
echo "=========================================================================="

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[-] Please run as root\e[0m"
  exit 1
fi

FAIL_COUNT=0

echo -e "\n[*] 1. Checking if AIDE is installed (CIS 6.1.1)..."
if rpm -q aide &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m AIDE is installed: $(rpm -q aide)"
else
    echo -e "  \e[31m[FAIL]\e[0m AIDE is not installed."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 2. Checking Regular AIDE Checks (CIS 6.1.2)..."
if systemctl is-enabled aidecheck.timer &>/dev/null || grep -rq "/usr/sbin/aide" /etc/cron.* /etc/crontab /var/spool/cron/ 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Regular AIDE checks are scheduled (Cron/Timer)."
else
    echo -e "  \e[31m[FAIL]\e[0m Regular AIDE checks are NOT scheduled."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 3. Checking Audit Tools Integrity Configuration (CIS 6.1.3)..."
if grep -Eq '^/sbin/auditctl' /etc/aide.conf 2>/dev/null && grep -Eq '^/sbin/auditd' /etc/aide.conf 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Audit tools are configured in /etc/aide.conf."
else
    echo -e "  \e[31m[FAIL]\e[0m Audit tools integrity tracking missing in /etc/aide.conf."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 4. Checking Oracle/Grid Exclusions..."
if grep -Eq '^!/u01|^!/u02|^!/opt/oracle' /etc/aide.conf 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Oracle/Grid exclusions found in /etc/aide.conf."
else
    echo -e "  \e[31m[FAIL]\e[0m Oracle/Grid exclusions MISSING. This will cause I/O spikes!"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

