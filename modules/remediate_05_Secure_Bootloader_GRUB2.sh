#!/bin/bash
# Script: remediate_cis_1_4.sh
# Purpose: Secure Bootloader Configuration (CIS 1.4)

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Applying Remediation for Bootloader (CIS 1.4)..."

# 1. Set GRUB Password (CIS 1.4.1)
echo "[*] Configuring GRUB2 password..."
if [ ! -s /boot/grub2/user.cfg ]; then
    echo "  [!] Please enter a strong password for the GRUB bootloader:"
    # Calling it directly allows interactive hidden input without stty errors
    grub2-setpassword
    
    if [ $? -eq 0 ]; then
        echo "  [+] GRUB password set successfully."
    else
        echo "  [-] Failed to set GRUB password."
    fi
else
    echo "  [-] GRUB password is already configured. Skipping to prevent overwrite."
fi

# 2. Set strict permissions (CIS 1.4.2)
echo -e "\n[*] Restricting permissions on GRUB configuration files..."

if [ -f /boot/grub2/grub.cfg ]; then
    chown root:root /boot/grub2/grub.cfg
    chmod 0400 /boot/grub2/grub.cfg
    echo "  [+] Secured /boot/grub2/grub.cfg (set to 400 root root)"
fi

if [ -f /boot/grub2/user.cfg ]; then
    chown root:root /boot/grub2/user.cfg
    chmod 0400 /boot/grub2/user.cfg
    echo "  [+] Secured /boot/grub2/user.cfg (set to 400 root root)"
fi

echo -e "\n[+] Bootloader secured successfully."

