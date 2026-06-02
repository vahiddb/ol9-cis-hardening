#!/bin/bash
# Script: audit27.sh
# Purpose: Audit permissions and ownership of auditd files and tools (CIS 6.3.4)

echo "=========================================================================="
echo " CIS Requirement: Auditd File Access (CIS 6.3.4)"
echo " - Ensure /var/log/audit is 0750 or 0700"
echo " - Ensure log files and config files are 0640 or 0600, owned by root"
echo " - Ensure audit tools are securely configured"
echo "=========================================================================="

AUDIT_STATUS="PASS"

check_perms() {
    local desc="$1"
    local result="$2"
    if [ -z "$result" ]; then
        echo "[PASS] $desc"
    else
        echo "[FAIL] $desc"
        echo "$result" | sed 's/^/       -> /'
        AUDIT_STATUS="FAIL"
    fi
}

# 1. Directory Mode
RES=$(stat -c "%n - %a" /var/log/audit 2>/dev/null | grep -vE "(750|700)")
check_perms "/var/log/audit directory mode" "$RES"

# 2. Log Files
RES=$(find /var/log/audit -type f \( ! -perm 0600 -a ! -perm 0640 \) 2>/dev/null)
check_perms "/var/log/audit files mode (0600/0640)" "$RES"

RES=$(find /var/log/audit -type f ! -user root -o ! -group root 2>/dev/null)
check_perms "/var/log/audit files ownership (root:root)" "$RES"

# 3. Config Files
RES=$(find /etc/audit -type f \( ! -perm 0640 -a ! -perm 0600 \) 2>/dev/null)
check_perms "/etc/audit config files mode (0640/0600)" "$RES"

RES=$(find /etc/audit -type f ! -user root -o ! -group root 2>/dev/null)
check_perms "/etc/audit config files ownership (root:root)" "$RES"

# 4. Tools
TOOLS=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")
TOOL_FAIL=""
for tool in "${TOOLS[@]}"; do
    if [ -e "$tool" ]; then
        MODE=$(stat -c "%a" "$tool")
        OWNER=$(stat -c "%U:%G" "$tool")
        if [[ ! "$MODE" =~ ^(755|750)$ ]] || [[ "$OWNER" != "root:root" ]]; then
            TOOL_FAIL="$TOOL_FAIL$tool (Mode:$MODE, Owner:$OWNER)\n"
        fi
    fi
done
check_perms "Audit tools permissions and ownership" "$(echo -e "$TOOL_FAIL" | sed '/^$/d')"

echo "--------------------------------------------------------------------------"
if [ "$AUDIT_STATUS" = "PASS" ]; then
    echo " Final Audit Status: PASS"
else
    echo " Final Audit Status: FAIL"
fi
echo "=========================================================================="
