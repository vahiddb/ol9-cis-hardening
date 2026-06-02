#!/bin/bash
# Remediation Script for CIS 5.1 - SSH Server Configuration
# Direct edit of /etc/ssh/sshd_config (Oracle RAC/GUI Compatible)

# 1. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m[-] Please run as root.\033[0m"
  exit 1
fi

CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%F_%T)"

# 2. Backup the original file and fix permissions
echo -e "\033[34m[*] Backing up $CONFIG_FILE to $BACKUP_FILE...\033[0m"
cp -p "$CONFIG_FILE" "$BACKUP_FILE"
chmod 0600 "$CONFIG_FILE"

# Function to safely update or append parameters in sshd_config
set_ssh_param() {
    local param="$1"
    local val="$2"
    
    # Check if parameter exists (commented or uncommented)
    if grep -q -E -i "^[#[:space:]]*${param}\b" "$CONFIG_FILE"; then
        # Replace the line with the correct parameter and value
        sed -i -E "s/^[#[:space:]]*${param}\b.*/${param} ${val}/i" "$CONFIG_FILE"
    else
        # Append to the end of the file if it doesn't exist
        echo "${param} ${val}" >> "$CONFIG_FILE"
    fi
}

echo -e "\033[34m[*] Applying CIS & Oracle SSH settings directly to $CONFIG_FILE...\033[0m"

# Oracle Exceptions (GUI Tools)
set_ssh_param "X11Forwarding" "yes"

# CIS Benchmark Settings + Oracle Context
set_ssh_param "PermitRootLogin" "no"
set_ssh_param "ClientAliveInterval" "300"
set_ssh_param "ClientAliveCountMax" "3"
set_ssh_param "DisableForwarding" "yes"
set_ssh_param "GSSAPIAuthentication" "no"
set_ssh_param "LoginGraceTime" "60"
set_ssh_param "MaxAuthTries" "4"
set_ssh_param "MaxSessions" "10"
set_ssh_param "PermitEmptyPasswords" "no"
set_ssh_param "AllowGroups" "wheel dba oinstall"

# NOTE on Oracle Linux 9 / RHEL 9:
# If "Include /etc/ssh/sshd_config.d/*.conf" is at the top of the file,
# settings in the drop-in directory (like 50-redhat.conf) might still override these.
# We ensure the Include line is either handled or we trust our direct edits.
# Uncomment the line below if you want to disable the drop-in directory completely:
# sed -i 's/^Include \/etc\/ssh\/sshd_config.d\/\*\.conf/#Include \/etc\/ssh\/sshd_config.d\/\*\.conf/' "$CONFIG_FILE"
# Fix GSSAPIAuthentication in drop-in files
sed -i 's/^GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config.d/*.conf 2>/dev/null

# 3. Check syntax and restart SSH service
echo -e "\033[34m[*] Checking SSH configuration syntax...\033[0m"
if sshd -t; then
    echo -e "\033[32m[+] Syntax OK. Restarting SSH service...\033[0m"
    systemctl restart sshd
    echo -e "\033[32m[+] Remediation completed successfully.\033[0m"
else
    echo -e "\033[31m[-] Syntax error detected in $CONFIG_FILE. Restoring backup...\033[0m"
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    exit 1
fi

