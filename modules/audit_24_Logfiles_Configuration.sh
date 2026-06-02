#!/bin/bash
# Script: audit24.sh
# Purpose: Audit CIS 6.2.4 Logfiles Access Configuration

echo "=========================================================================="
echo " CIS Requirement: Logfiles Access Configuration (CIS 6.2.4)"
echo " - Ensure all general logfiles have permissions of 0640 or more restrictive."
echo " - Ensure /var/log/btmp permissions are 0600 or more restrictive."
echo " - Ensure /var/log/wtmp and lastlog permissions are 0664 or more restrictive."
echo " - Ensure log directories have permissions of 0750 or more restrictive."
echo "--------------------------------------------------------------------------"
echo " Oracle Context & Exceptions:"
echo " - INTERFERENCE: None (Path Isolation)."
echo " - EXPLANATION: Actions target /var/log/. Oracle logs (ADR) reside in"
echo "   \$ORACLE_BASE/diag/ and are managed by Oracle's specific users/groups."
echo " - NOTE: If Oracle auxiliary tools (like TFA or OSWatcher) read /var/log/,"
echo "   they must run as root to avoid 'Permission Denied' errors."
echo "=========================================================================="

AUDIT_STATUS="PASS"

# 1. Check general log files (Expected: max 0640 -> Forbidden bits: 0137)
BAD_FILES=$(find /var/log -type f \( ! -name "wtmp" -a ! -name "lastlog" -a ! -name "btmp" \) -perm /0137 2>/dev/null)
if [ -n "$BAD_FILES" ]; then
    echo "[ FAIL ] General log files with unauthorized permissions (looser than 0640):"
    find /var/log -type f \( ! -name "wtmp" -a ! -name "lastlog" -a ! -name "btmp" \) -perm /0137 -ls 2>/dev/null
    AUDIT_STATUS="FAIL"
else
    echo "[ OK ] General log files permissions are secure."
fi

# 2. Check btmp file (Expected: max 0600 -> Forbidden bits: 0177)
if [ -f /var/log/btmp ]; then
    BAD_BTMP=$(find /var/log/btmp -type f -perm /0177 2>/dev/null)
    if [ -n "$BAD_BTMP" ]; then
        echo "[ FAIL ] /var/log/btmp has unauthorized permissions (looser than 0600):"
        ls -l /var/log/btmp
        AUDIT_STATUS="FAIL"
    else
        echo "[ OK ] /var/log/btmp permission is secure."
    fi
fi

# 3. Check wtmp and lastlog (Expected: max 0664 -> Forbidden bits: 0113)
BAD_WTMP=$(find /var/log -type f \( -name "wtmp" -o -name "lastlog" \) -perm /0113 2>/dev/null)
if [ -n "$BAD_WTMP" ]; then
    echo "[ FAIL ] wtmp/lastlog have unauthorized permissions (looser than 0664):"
    find /var/log -type f \( -name "wtmp" -o -name "lastlog" \) -perm /0113 -ls 2>/dev/null
    AUDIT_STATUS="FAIL"
else
    echo "[ OK ] wtmp/lastlog permissions are secure."
fi

# 4. Check log directories (Expected: max 0750 -> Forbidden bits: 0027)
BAD_DIRS=$(find /var/log -type d -perm /0027 2>/dev/null)
if [ -n "$BAD_DIRS" ]; then
    echo "[ FAIL ] Log directories with unauthorized permissions (looser than 0750):"
    find /var/log -type d -perm /0027 -ls 2>/dev/null
    AUDIT_STATUS="FAIL"
else
    echo "[ OK ] Log directories permissions are secure."
fi

echo "----------------------------------------------------------"
if [ "$AUDIT_STATUS" == "PASS" ]; then
    echo -e "\e[32m[ PASS ] Final Status: Section 24 Auditing Passed Successfully.\e[0m"
else
    echo -e "\e[31m[ FAIL ] Final Status: Section 24 Auditing Failed. Run remediation script.\e[0m"
fi
echo "=========================================================="
