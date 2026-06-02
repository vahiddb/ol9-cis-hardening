#!/bin/bash
# Script: remediation9.sh
# Purpose: Remove GDM and Enforce CLI Boot Mode (CIS 1.8)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 1.8 (GNOME Display Manager)"
echo " Oracle Context: Safe and Recommended for Database Servers."
echo "=========================================================================="

# 1. Remove GDM if installed
if rpm -q gdm > /dev/null 2>&1; then
    echo "[*] Removing GDM package and dependencies..."
    dnf remove -y gdm
    echo -e "  \e[32m[OK]\e[0m GDM removed successfully."
else
    echo -e "  \e[32m[OK]\e[0m GDM is already absent."
fi

# 2. Enforce CLI Boot Mode
CURRENT_TARGET=$(systemctl get-default)
if [ "$CURRENT_TARGET" != "multi-user.target" ]; then
    echo "[*] Setting default target to multi-user.target..."
    systemctl set-default multi-user.target
    echo -e "  \e[32m[OK]\e[0m Default target updated to multi-user.target."
else
    echo -e "  \e[32m[OK]\e[0m Default target is already multi-user.target."
fi

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

