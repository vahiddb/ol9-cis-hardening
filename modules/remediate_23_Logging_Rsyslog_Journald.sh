#!/bin/bash
# Script: remediation23.sh
# Purpose: Configure System Logging (CIS 6.2) for Oracle Linux environments

echo "=========================================================================="
echo " Applying Remediation: System Logging Configuration"
echo "=========================================================================="

# 1. systemd-journald configuration
echo "[+] Configuring systemd-journald..."
sed -i 's/^#Compress=.*/Compress=yes/' /etc/systemd/journald.conf
sed -i 's/^#Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
sed -i 's/^#ForwardToSyslog=.*/ForwardToSyslog=yes/' /etc/systemd/journald.conf

# Ensure entries exist if they were entirely missing
grep -q "^Compress=yes" /etc/systemd/journald.conf || echo "Compress=yes" >> /etc/systemd/journald.conf
grep -q "^Storage=persistent" /etc/systemd/journald.conf || echo "Storage=persistent" >> /etc/systemd/journald.conf
grep -q "^ForwardToSyslog=yes" /etc/systemd/journald.conf || echo "ForwardToSyslog=yes" >> /etc/systemd/journald.conf

systemctl restart systemd-journald

# 2. rsyslog configuration (FileCreateMode)
echo "[+] Configuring rsyslog FileCreateMode..."
if grep -q "^\$FileCreateMode" /etc/rsyslog.conf; then
    sed -i 's/^\$FileCreateMode.*/$FileCreateMode 0640/' /etc/rsyslog.conf
else
    # Add it to the configuration if missing
    echo "\$FileCreateMode 0640" >> /etc/rsyslog.conf
fi

# 3. Remote Logging Configuration
echo "[+] Configuring Remote Logging..."
# Prompt user for log server
read -p "Enter Remote Syslog Server IP/Hostname (Press Enter to skip if none): " REMOTE_SERVER

if [ -n "$REMOTE_SERVER" ]; then
    # Remove old forwarding rules if they exist
    sed -i '/^\*\.\* @@/d' /etc/rsyslog.conf
    sed -i '/^\*\.\* @/d' /etc/rsyslog.conf
    
    # Add new TCP forwarding rule at the end of the file
    echo "*.* @@${REMOTE_SERVER}:514" >> /etc/rsyslog.conf
    echo "  -> Remote logging configured to send to ${REMOTE_SERVER} via TCP."
else
    echo "  -> No Remote Syslog Server provided. Skipping remote configuration."
fi

# Ensure rsyslog is enabled and restart to apply changes
systemctl enable --quiet rsyslog
systemctl restart rsyslog

# 4. Fixing Log Permissions
echo "[+] Securing existing log file permissions..."
find /var/log -type f -exec chmod g-wx,o-rwx "{}" +
# Restore specific permissions for special log files (like wtmp, btmp, lastlog)
[ -f /var/log/wtmp ] && chmod 0664 /var/log/wtmp
[ -f /var/log/lastlog ] && chmod 0664 /var/log/lastlog
[ -f /var/log/btmp ] && chmod 0660 /var/log/btmp

echo "=========================================================================="
echo " Remediation completed successfully."
echo " Run ./audit23.sh again to verify."
echo "=========================================================================="

