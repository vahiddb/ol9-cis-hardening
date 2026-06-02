#!/bin/bash
# Script: audit23.sh
# Purpose: Audit System Logging Configuration (CIS)

ISSUES=0

echo "=========================================================================="
echo " CIS Requirement: System Logging Configuration"
echo " - Ensure systemd-journald is configured properly (Compress, Storage, ForwardToSyslog)."
echo " - Ensure rsyslog is active, FileCreateMode is 0640, and Remote Logging is set."
echo " - Ensure log files have appropriate permissions (0640 or stricter)."
echo " Oracle Context & Exceptions:"
echo " - Permissions on Oracle pre-install logs and oracleasm will be secured"
echo "   without affecting functionality. Remote logging has NO DB/Grid conflict."
echo "=========================================================================="
echo ""

# 1. Checking systemd-journald settings
echo "[*] 1. Checking systemd-journald settings..."
if grep -Eq "^Compress=yes" /etc/systemd/journald.conf; then
    echo -e "  [\e[32mPASS\e[0m] Compress=yes is configured."
else
    echo -e "  [\e[31mFAIL\e[0m] Compress=yes is missing or commented out."
    ((ISSUES++))
fi

if grep -Eq "^Storage=persistent" /etc/systemd/journald.conf; then
    echo -e "  [\e[32mPASS\e[0m] Storage=persistent is configured."
else
    echo -e "  [\e[31mFAIL\e[0m] Storage=persistent is missing or commented out."
    ((ISSUES++))
fi

if grep -Eq "^ForwardToSyslog=yes" /etc/systemd/journald.conf; then
    echo -e "  [\e[32mPASS\e[0m] ForwardToSyslog=yes is configured."
else
    echo -e "  [\e[31mFAIL\e[0m] ForwardToSyslog=yes is missing or commented out."
    ((ISSUES++))
fi

# 2. Checking rsyslog status & FileCreateMode
echo -e "\n[*] 2. Checking rsyslog status & FileCreateMode..."
if systemctl is-active --quiet rsyslog; then
    echo -e "  [\e[32mPASS\e[0m] rsyslog is active."
else
    echo -e "  [\e[31mFAIL\e[0m] rsyslog is NOT active."
    ((ISSUES++))
fi

if grep -Eq '^\$FileCreateMode 0640' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null; then
    echo -e "  [\e[32mPASS\e[0m] rsyslog FileCreateMode is set to 0640."
else
    echo -e "  [\e[31mFAIL\e[0m] rsyslog FileCreateMode 0640 is missing."
    ((ISSUES++))
fi

# 3. Checking Remote Logging Configuration
echo -e "\n[*] 3. Checking Remote Logging Configuration..."
REMOTE_CONF=$(grep -E '^\*\.\* \@' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)
if [ -n "$REMOTE_CONF" ]; then
    echo -e "  [\e[32mPASS\e[0m] Remote logging is configured."
else
    echo -e "  [\e[31mFAIL\e[0m] Remote logging is NOT configured. Logs are only stored locally."
    ((ISSUES++))
fi

# 4. Checking Logfile Permissions
echo -e "\n[*] 4. Checking Logfile Permissions..."
BAD_PERMS=$(find /var/log -type f -perm /0137 ! -name 'lastlog' ! -name 'wtmp' ! -name 'btmp' 2>/dev/null)
if [ -z "$BAD_PERMS" ]; then
    echo -e "  [\e[32mPASS\e[0m] General log file permissions are secure."
else
    echo -e "  [\e[31mFAIL\e[0m] Some log files have insecure permissions."
    ((ISSUES++))
fi

echo -e "\n=========================================================================="
if [ $ISSUES -eq 0 ]; then
    echo -e " [-] AUDIT RESULT: \e[32mPASS\e[0m (0 issues found)"
else
    echo -e " [-] AUDIT RESULT: \e[31mFAIL\e[0m ($ISSUES issues found)"
fi
echo "=========================================================================="

