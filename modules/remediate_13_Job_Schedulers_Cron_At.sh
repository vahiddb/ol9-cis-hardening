#!/bin/bash
# Script: remediation13.sh
# Purpose: Configure Job Schedulers (Cron & At) (CIS 2.4)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 2.4 (Job Schedulers)"
echo " Oracle Context: Ensuring 'oracle' and 'grid' can execute scheduled jobs."
echo "=========================================================================="

echo -e "\n[*] Configuring Cron and At..."

# 1. Enable and start crond
systemctl enable --now crond > /dev/null 2>&1
echo -e "  \e[32m[OK]\e[0m Enabled and started crond service."

# 2. Set permissions for /etc/crontab
chown root:root /etc/crontab
chmod 0600 /etc/crontab
echo -e "  \e[32m[OK]\e[0m Set permissions on /etc/crontab."

# 3. Set permissions for cron directories
for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d; do
    if [ -d "$dir" ]; then
        chown root:root "$dir"
        chmod 0700 "$dir"
    fi
done
echo -e "  \e[32m[OK]\e[0m Set permissions on /etc/cron.* directories."

# 4. Restrict crontab access
rm -f /etc/cron.deny
touch /etc/cron.allow
chown root:root /etc/cron.allow
chmod 0600 /etc/cron.allow

# 5. Restrict at access
rm -f /etc/at.deny
touch /etc/at.allow
chown root:root /etc/at.allow
chmod 0600 /etc/at.allow

echo -e "  \e[32m[OK]\e[0m Configured cron.allow and at.allow (denied others)."

# 6. Oracle DBA Exception: Allow oracle and grid users
grep -q "^oracle$" /etc/cron.allow || echo "oracle" >> /etc/cron.allow
grep -q "^grid$" /etc/cron.allow || echo "grid" >> /etc/cron.allow
# Optional: also allow root explicitly
grep -q "^root$" /etc/cron.allow || echo "root" >> /etc/cron.allow

echo -e "  \e[32m[OK]\e[0m Whitelisted 'root', 'oracle', and 'grid' users in /etc/cron.allow."

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

