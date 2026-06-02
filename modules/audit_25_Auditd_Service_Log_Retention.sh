#!/bin/bash
# Script: audit25.sh
# Purpose: Audit CIS 6.3.1 & 6.3.2 (Auditd Configuration & Retention)

echo "=========================================================================="
echo " CIS Requirement: Configure auditd Service and Data Retention"
echo "--------------------------------------------------------------------------"
echo " Oracle Context & Exceptions:"
echo " - CRITICAL INTERFERENCE: CIS recommends HALT/SINGLE for space_left_action."
echo " - EXPLANATION: In Oracle DB/RAC environments, halting the OS due to full"
echo "   audit logs causes node eviction and database downtime."
echo " - SOLUTION: Set space_left_action and admin_space_left_action to SYSLOG."
echo "=========================================================================="

AUDIT_STATUS="PASS"

# 1. Packages & Service
if rpm -q audit audit-libs >/dev/null 2>&1; then
    echo "[ PASS ] Packages 'audit' and 'audit-libs' are installed."
else
    echo "[ FAIL ] Packages 'audit' and 'audit-libs' are not installed."
    AUDIT_STATUS="FAIL"
fi

if systemctl is-active auditd >/dev/null 2>&1; then
    echo "[ PASS ] auditd service is active."
else
    echo "[ FAIL ] auditd service is not active."
    AUDIT_STATUS="FAIL"
fi

if systemctl is-enabled auditd >/dev/null 2>&1; then
    echo "[ PASS ] auditd service is enabled."
else
    echo "[ FAIL ] auditd service is not enabled."
    AUDIT_STATUS="FAIL"
fi

# 2. GRUB Configuration
if grubby --info=ALL | grep -q "audit=1"; then
    echo "[ PASS ] GRUB parameter 'audit=1' is present."
else
    echo "[ FAIL ] GRUB parameter 'audit=1' is missing."
    AUDIT_STATUS="FAIL"
fi

if grubby --info=ALL | grep -q "audit_backlog_limit="; then
    echo "[ PASS ] GRUB parameter 'audit_backlog_limit' is present."
else
    echo "[ FAIL ] GRUB parameter 'audit_backlog_limit=' is missing."
    AUDIT_STATUS="FAIL"
fi

# 3. Data Retention Configuration
check_audit_conf() {
    local key=$1
    local expected=$2
    local current=$(grep -E "^${key}\s*=" /etc/audit/auditd.conf | awk -F= '{print $2}' | tr -d ' ')
    if [ "$current" != "$expected" ]; then
         echo "[ FAIL ] auditd.conf: $key is '$current' (Expected: $expected)"
         AUDIT_STATUS="FAIL"
    else
         echo "[ PASS ] auditd.conf: $key is correctly set to '$current'"
    fi
}

check_audit_conf "max_log_file" "24"
check_audit_conf "max_log_file_action" "keep_logs"
check_audit_conf "space_left_action" "SYSLOG"
check_audit_conf "admin_space_left_action" "SYSLOG"

echo "----------------------------------------------------------"
if [ "$AUDIT_STATUS" == "PASS" ]; then
    echo -e "\e[32m[ PASS ] Final Status: Section 25 Auditing Passed Successfully.\e[0m"
else
    echo -e "\e[31m[ FAIL ] Final Status: Section 25 Auditing Failed. Run remediation script.\e[0m"
fi
echo "=========================================================="
