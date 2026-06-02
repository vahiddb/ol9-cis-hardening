#!/bin/bash
# Script: remediate_cis_6_3_4.sh
# Purpose: Fix permissions and ownership for auditd files and tools

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Remediating CIS 6.3.4..."

# 6.3.4.1 - 6.3.4.4: Log files and directory
echo "[*] Securing /var/log/audit and log files..."
chown root:root /var/log/audit
chmod 0750 /var/log/audit
find /var/log/audit -type f -exec chmod 0640 {} \;
find /var/log/audit -type f -exec chown root:root {} \;

# 6.3.4.5 - 6.3.4.7: Config files
echo "[*] Securing /etc/audit/ configuration files..."
find /etc/audit -type f -exec chown root:root {} \;
find /etc/audit -type f -exec chmod 0640 {} \;
chown root:root /etc/audit/auditd.conf 2>/dev/null
chmod 0640 /etc/audit/auditd.conf 2>/dev/null

# 6.3.4.8 - 6.3.4.10: Audit tools
echo "[*] Securing audit tools..."
TOOLS=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")
for tool in "${TOOLS[@]}"; do
    if [ -e "$tool" ]; then
        chown root:root "$tool"
        chmod 0755 "$tool"
    fi
done

echo "[+] Remediation applied successfully."
