#!/bin/bash
# Remediation Script for CIS 5.3 & 5.6 - Sudo and su Configuration
# Direct configuration of sudoers and pam (Oracle RAC Compatible)

# 1. Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m[-] Please run as root.\033[0m"
  exit 1
fi

SUDOERS_FILE="/etc/sudoers"
PAM_SU_FILE="/etc/pam.d/su"
BACKUP_SUFFIX=".bak.$(date +%F_%T)"

# 2. Backup the original files
echo -e "\033[34m[*] Backing up configuration files...\033[0m"
cp -p "$SUDOERS_FILE" "${SUDOERS_FILE}${BACKUP_SUFFIX}"
cp -p "$PAM_SU_FILE" "${PAM_SU_FILE}${BACKUP_SUFFIX}"

# 3. Ensure sudo is installed
echo -e "\033[34m[*] Ensuring sudo is installed...\033[0m"
dnf install -y sudo > /dev/null 2>&1

# 4. Configure Sudo Defaults
echo -e "\033[34m[*] Applying CIS Sudo Defaults (use_pty, logfile, timestamp_timeout)...\033[0m"
cat << 'EOF' > /etc/sudoers.d/99-cis-sudo-defaults
Defaults use_pty
Defaults logfile="/var/log/sudo.log"
Defaults timestamp_timeout=15
EOF
chmod 0440 /etc/sudoers.d/99-cis-sudo-defaults

# 5. Remove !authenticate
echo -e "\033[34m[*] Removing '!authenticate' from sudoers files...\033[0m"
sed -i 's/!authenticate//g' /etc/sudoers
for f in /etc/sudoers.d/*; do
  if [ -f "$f" ]; then
    sed -i 's/!authenticate//g' "$f"
  fi
done


# 6. Restrict 'su' to a specific group (e.g., 'sugroup') to prevent granting sudo access
echo -e "\033[34m[*] Restricting 'su' command to 'sugroup' in pam...\033[0m"

# Create the group if it does not exist
groupadd -f sugroup

# Add Oracle users to this group
usermod -aG sugroup oracle 2>/dev/null
usermod -aG sugroup grid 2>/dev/null

# Configure pam_wheel to use this specific group (preventing interference with wheel and sudo)
if grep -q "pam_wheel.so" "$PAM_SU_FILE"; then
    sed -i 's/^#\s*auth\s*required\s*pam_wheel.so.*/auth            required        pam_wheel.so use_uid group=sugroup/' "$PAM_SU_FILE"
    sed -i 's/^auth\s*required\s*pam_wheel.so.*/auth            required        pam_wheel.so use_uid group=sugroup/' "$PAM_SU_FILE"
else
    sed -i '/pam_rootok.so/a auth            required        pam_wheel.so use_uid group=sugroup' "$PAM_SU_FILE"
fi

# 7. Add Oracle/Grid to wheel group (Oracle Exception)
echo -e "\033[34m[*] Adding Oracle and Grid users to 'wheel' group...\033[0m"
for user in oracle grid; do
    if id "$user" &>/dev/null; then
        usermod -aG wheel "$user"
    fi
done

# 8. Check syntax
echo -e "\033[34m[*] Checking sudoers configuration syntax...\033[0m"
if visudo -c >/dev/null 2>&1; then
    echo -e "\033[32m[+] Syntax OK. Remediation completed successfully.\033[0m"
else
    echo -e "\033[31m[-] Syntax error detected in sudoers. Restoring backup...\033[0m"
    cp -p "${SUDOERS_FILE}${BACKUP_SUFFIX}" "$SUDOERS_FILE"
    rm -f /etc/sudoers.d/99-cis-sudo-defaults
    exit 1
fi

