#!/bin/bash
# Script: audit_cis_1_4.sh
# Purpose: Audit Bootloader Configuration (CIS 1.4)

echo "=========================================================================="
echo " CIS Requirement: 1.4 Secure Bootloader Configuration"
echo " - Ensure bootloader password is set."
echo " - Ensure bootloader config file permissions are secure."
echo " Oracle Context: Setting a GRUB password prevents unauthorized access to"
echo " single-user mode. It does NOT impact Oracle DB/RAC/Grid operations as"
echo " they run post-boot and do not interact with the bootloader."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] 1. Checking GRUB password configuration..."
if [ -s /boot/grub2/user.cfg ] && grep -q "^GRUB2_PASSWORD=" /boot/grub2/user.cfg; then
    echo -e "  \e[32m[PASS]\e[0m GRUB password is set in /boot/grub2/user.cfg."
else
    echo -e "  \e[31m[FAIL]\e[0m GRUB password is NOT configured (/boot/grub2/user.cfg missing or empty)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 2. Checking permissions of GRUB config files..."
for file in /boot/grub2/grub.cfg /boot/grub2/user.cfg; do
    if [ -e "$file" ]; then
        PERM=$(stat -c "%a %U %G" "$file")
        if [[ "$PERM" == "400 root root" || "$PERM" == "600 root root" ]]; then
            echo -e "  \e[32m[PASS]\e[0m $file permissions are secure ($PERM)."
        else
            echo -e "  \e[31m[FAIL]\e[0m $file has insecure permissions ($PERM). Expected 400 or 600 root root."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        # Only fail if it's grub.cfg, since missing user.cfg is already caught in step 1
        if [ "$file" == "/boot/grub2/grub.cfg" ]; then
            echo -e "  \e[31m[FAIL]\e[0m $file does not exist."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
done

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

