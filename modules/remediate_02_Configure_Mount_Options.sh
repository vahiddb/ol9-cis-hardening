#!/bin/bash
# Script: remediate_cis_1_1_2.sh
# Purpose: Apply Secure Mount Options (CIS 1.1.2 - 1.1.8)

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Applying Remediation for Partitions & Mount Options..."
echo -e "[!] Note: Skipping 'noexec' on /dev/shm for Oracle compatibility.\n"

# 3. Function to update /etc/fstab safely
update_fstab() {
    local mount_point=$1
    local options=$2

    if grep -q "^[^#].*[[:space:]]${mount_point}[[:space:]]" /etc/fstab; then
        for opt in $(echo "$options" | tr ',' ' '); do
            sed -i "/^[[:space:]]*[^#].*[[:space:]]${mount_point//\//\\/}[[:space:]]/ s/\([ \t]*[^\t ]*[ \t]*[^\t ]*[ \t]*[^\t ]*[ \t]*\)\([^ \t]*\)/\1\2,$opt/" /etc/fstab
        done
        sed -i "/^[[:space:]]*[^#].*[[:space:]]${mount_point//\//\\/}[[:space:]]/ s/,\{2,\}/,/g" /etc/fstab
        sed -i "/^[[:space:]]*[^#].*[[:space:]]${mount_point//\//\\/}[[:space:]]/ s/,[ \t]/ /g" /etc/fstab
        mount -o remount "$mount_point" 2>/dev/null
        echo "  [+] Updated options for $mount_point"
    else
        echo "  [-] WARNING: $mount_point is not in /etc/fstab (requires architectural change)."
    fi
}

# 1. Configure /tmp (Check fstab first, fallback to systemd)
echo "  [*] Configuring /tmp..."
if grep -q "^[^#].*[[:space:]]/tmp[[:space:]]" /etc/fstab; then
    update_fstab "/tmp" "nodev,nosuid,noexec"
else
    echo "      Using systemd (tmpfs) for /tmp..."
    cp /usr/lib/systemd/system/tmp.mount /etc/systemd/system/ 2>/dev/null
    sed -i 's/^Options=.*/Options=mode=1777,strictatime,noexec,nodev,nosuid/' /etc/systemd/system/tmp.mount
    systemctl daemon-reload
    systemctl enable tmp.mount --now
    mount -o remount /tmp 2>/dev/null
fi

# 2. Fix /dev/shm (Add to fstab explicitly for Oracle)
echo "  [*] Configuring /dev/shm explicitly for Oracle..."
if ! grep -q "^tmpfs[[:space:]]*/dev/shm" /etc/fstab; then
    echo "tmpfs   /dev/shm    tmpfs   defaults,nodev,nosuid,seclabel   0 0" >> /etc/fstab
else
    sed -i -E 's|^(tmpfs[[:space:]]+/dev/shm[[:space:]]+tmpfs[[:space:]]+)([^[:space:]]+)|\1defaults,nodev,nosuid,seclabel|' /etc/fstab
fi
mount -o remount /dev/shm 2>/dev/null


# Update other partitions
update_fstab "/home" "nodev,nosuid"
update_fstab "/var" "nodev,nosuid"
update_fstab "/var/tmp" "nodev,nosuid,noexec"
update_fstab "/var/log" "nodev,nosuid,noexec"
update_fstab "/var/log/audit" "nodev,nosuid,noexec"

echo -e "\n[+] Mount options hardening completed."

