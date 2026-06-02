#!/bin/bash
# Script: audit13.sh
# Purpose: Audit Script for Job Schedulers - Cron & At (CIS 2.4)

echo "=========================================================================="
echo " CIS Requirement: 2.4 Job Schedulers"
echo " - Ensure cron daemon is active and permissions are tightly configured."
echo " Oracle Context:"
echo " - CRITICAL: 'oracle' and 'grid' users MUST be allowed to use cron."
echo " - Database backups (RMAN) and maintenance jobs rely heavily on crontab."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Auditing Cron & At Configurations..."

# 1. Check crond service
if systemctl is-enabled crond &>/dev/null && systemctl is-active crond &>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m crond service is enabled and active."
else
    echo -e "  \e[31m[FAIL]\e[0m crond service is NOT enabled/active."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2. Check /etc/crontab permissions
if [ "$(stat -c "%a %U %G" /etc/crontab 2>/dev/null)" = "600 root root" ]; then
    echo -e "  \e[32m[PASS]\e[0m /etc/crontab permissions are correct (0600 root:root)."
else
    echo -e "  \e[31m[FAIL]\e[0m /etc/crontab permissions are incorrect."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 3. Check cron directories permissions
for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d; do
    if [ -d "$dir" ]; then
        if [ "$(stat -c "%a %U %G" "$dir" 2>/dev/null)" = "700 root root" ]; then
            echo -e "  \e[32m[PASS]\e[0m $dir permissions are correct."
        else
            echo -e "  \e[31m[FAIL]\e[0m $dir permissions are incorrect."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
done

# 4. Check cron access control
if [ ! -f /etc/cron.deny ] && [ -f /etc/cron.allow ] && [ "$(stat -c "%a %U %G" /etc/cron.allow 2>/dev/null)" = "600 root root" ]; then
    echo -e "  \e[32m[PASS]\e[0m cron.allow exists (0600 root:root) and cron.deny is absent."
else
    echo -e "  \e[31m[FAIL]\e[0m cron access control is not properly configured."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 5. Check at access control
if [ ! -f /etc/at.deny ] && [ -f /etc/at.allow ] && [ "$(stat -c "%a %U %G" /etc/at.allow 2>/dev/null)" = "600 root root" ]; then
    echo -e "  \e[32m[PASS]\e[0m at.allow exists (0600 root:root) and at.deny is absent."
else
    echo -e "  \e[31m[FAIL]\e[0m at access control is not properly configured."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 6. Oracle Context: Check if oracle/grid are whitelisted in cron.allow
if grep -q "^oracle$" /etc/cron.allow 2>/dev/null || grep -q "^grid$" /etc/cron.allow 2>/dev/null; then
    echo -e "  \e[32m[PASS]\e[0m Oracle/Grid users are correctly whitelisted in /etc/cron.allow."
else
    echo -e "  \e[31m[FAIL]\e[0m Oracle/Grid users are MISSING from /etc/cron.allow!"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

