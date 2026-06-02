#!/bin/bash
# Script: remediation12.sh
# Purpose: Configure Time Synchronization via Chrony (CIS 2.3)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 2.3 (Time Synchronization)"
echo " Oracle Context: chronyd setup is fully supported and required for Oracle."
echo "=========================================================================="

echo -e "\n[*] Configuring Time Synchronization (Chrony)..."

# Ask user for NTP Server IP/Hostname
read -p "Enter your primary NTP server address (e.g., 192.168.1.50 or pool.ntp.org): " NTP_SERVER

if [ -z "$NTP_SERVER" ]; then
    echo -e "\n\e[31m[-] NTP Server address cannot be empty. Exiting.\e[0m"
    exit 1
fi

# 1. Install chrony if not present
dnf install -y chrony > /dev/null 2>&1

# 2. Configure NTP Server in chrony.conf
cp /etc/chrony.conf /etc/chrony.conf.bak
# Remove existing default pools/servers to avoid conflicts
sed -i '/^pool /d' /etc/chrony.conf
sed -i '/^server /d' /etc/chrony.conf
# Add the user-provided NTP server
echo "server $NTP_SERVER iburst" >> /etc/chrony.conf
echo -e "  \e[32m[OK]\e[0m Set NTP server to $NTP_SERVER in /etc/chrony.conf"

# 3. Ensure it does not run as root
SYSCONFIG_FILE="/etc/sysconfig/chronyd"
if grep -q "^OPTIONS" "$SYSCONFIG_FILE"; then
    if ! grep -q 'OPTIONS.*-u chrony' "$SYSCONFIG_FILE"; then
        sed -i 's/^OPTIONS="\(.*\)"/OPTIONS="\1 -u chrony"/' "$SYSCONFIG_FILE"
    fi
else
    echo 'OPTIONS="-u chrony"' >> "$SYSCONFIG_FILE"
fi
echo -e "  \e[32m[OK]\e[0m Configured chronyd to run as 'chrony' user."

# 4. Enable and restart the service
systemctl enable --now chronyd > /dev/null 2>&1
systemctl restart chronyd
echo -e "  \e[32m[OK]\e[0m chronyd service enabled and restarted."

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

