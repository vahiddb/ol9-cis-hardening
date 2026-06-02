#!/bin/bash
# Script: remediation24.sh
# Purpose: Restrict permissions on logfiles (CIS 6.2.4) with Oracle Exceptions

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo "=========================================================================="
echo " [ Remediation ] Section 24: Logfiles Access Permissions"
echo " Applying CIS Requirements while maintaining Oracle/System exceptions:"
echo " - Setting general logs to max 0640."
echo " - Setting directories to max 0750."
echo " - Setting btmp to 0600 (root:utmp)."
echo " - Setting wtmp & lastlog to 0664 (root:utmp)."
echo "=========================================================================="

# 1. Restrict general files (excluding exceptions)
find /var/log -type f \( ! -name "wtmp" -a ! -name "lastlog" -a ! -name "btmp" \) -exec chmod g-wx,o-rwx "{}" +

# 2. Restrict directories
find /var/log -type d -exec chmod g-w,o-rwx "{}" +

# 3. Apply exceptions for btmp
if [ -f /var/log/btmp ]; then
    chmod 0600 /var/log/btmp
    chown root:utmp /var/log/btmp
fi

# 4. Apply exceptions for wtmp and lastlog
for file in /var/log/wtmp /var/log/lastlog; do
    if [ -f "$file" ]; then
        chmod 0664 "$file"
        chown root:utmp "$file"
    fi
done

echo "[+] Logfiles permissions successfully restricted and exceptions applied."
