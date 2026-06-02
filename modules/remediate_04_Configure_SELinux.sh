#!/bin/bash
# Script: remediate_cis_1_3_1.sh
# Purpose: Harden SELinux Configurations (CIS 1.3.1)

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Applying Remediation for SELinux (CIS 1.3.1)..."

# 1. Ensure libselinux is installed (Using --nogpgcheck temporarily if local keys are not imported, but recommended to import keys first)
echo "  [*] Ensuring libselinux is installed..."
dnf install -y libselinux -q

# 2. Remove unsafe SELinux troubleshooting tools (CIS 1.3.1.7, 1.3.1.8)
echo "  [*] Removing unsafe SELinux packages (mcstrans, setroubleshoot)..."
dnf remove -y mcstrans setroubleshoot -q >/dev/null 2>&1

# 3. Remove selinux=0 or enforcing=0 from bootloader (CIS 1.3.1.2)
echo "  [*] Hardening Bootloader parameters..."
grubby --update-kernel ALL --remove-args="selinux=0 enforcing=0"

# 4. Configure SELinux policy and mode in config file (CIS 1.3.1.3, 1.3.1.4, 1.3.1.5)
echo "  [*] Enforcing SELinux 'targeted' policy in /etc/selinux/config..."
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config

# 5. Apply Enforcing mode immediately if possible
echo "  [*] Applying SELinux state..."
if [ "$(getenforce)" != "Disabled" ]; then
    setenforce 1
    echo "  [+] SELinux is set to Enforcing."
else
    echo "  [!] SELinux is currently Disabled in kernel. A REBOOT IS REQUIRED to activate Enforcing mode."
fi

echo -e "\n[+] SELinux configuration applied successfully."

