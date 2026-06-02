#!/bin/bash
# Script: audit26.sh
# Purpose: Audit Auditd Rules (CIS 6.3.3) for Oracle Linux

echo "=========================================================================="
echo " CIS Requirement: Auditd Rules Configuration (CIS 6.3.3)"
echo " - Ensure various audit rules are populated (sudo, time, network, etc.)."
echo " - Ensure audit configuration is immutable using '-e 2' (CIS 6.3.3.20)."
echo " Oracle Context & Exceptions:"
echo " - EXCEPTION: Setting rules to immutable (-e 2) locks them until reboot."
echo "   In Oracle DB/RAC production environments, this hinders troubleshooting."
echo "   ACTION: We accept '-e 1' (locked but mutable) to maintain stability"
echo "   and prevent unwanted node evictions or required downtime."
echo "=========================================================================="

AUDIT_STATUS="PASS"

check_rule() {
    local rule_desc="$1"
    local search_key="$2"
    # Added '--' so grep doesn't treat '-k' as a command-line option
    if grep -REq -- "$search_key" /etc/audit/rules.d/ 2>/dev/null; then
        echo "[PASS] Rule populated: $rule_desc"
    else
        echo "[FAIL] Rule missing: $rule_desc"
        AUDIT_STATUS="FAIL"
    fi
}

echo "Checking Audit Rules..."
check_rule "Sudoers changes (scope)" "-k scope"
check_rule "Sudo log file" "-k sudo_log_file"
check_rule "Time changes" "-k time-change"
check_rule "Network environment (system-locale)" "-k system-locale"
check_rule "User/Group info (identity)" "-k identity"
check_rule "Logins and logouts" "-k logins"
check_rule "File deletions" "-k delete"
check_rule "Kernel modules" "-k modules"

# Check Immutability Status
echo "Checking Immutability Flag..."
if grep -Eq -- "^\s*-e\s+2" /etc/audit/rules.d/*.rules 2>/dev/null; then
    echo "[PASS] Configuration is strictly immutable (-e 2) [CIS Standard]"
elif grep -Eq -- "^\s*-e\s+1" /etc/audit/rules.d/*.rules 2>/dev/null; then
    echo "[PASS] Configuration is locked (-e 1) [Oracle Best Practice Exception]"
else
    echo "[FAIL] Immutability flag (-e 1 or -e 2) is missing or set to 0"
    AUDIT_STATUS="FAIL"
fi

echo "--------------------------------------------------------------------------"
if [ "$AUDIT_STATUS" = "PASS" ]; then
    echo " Final Audit Status: PASS"
else
    echo " Final Audit Status: FAIL"
fi
echo "=========================================================================="
