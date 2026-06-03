#!/bin/bash
# Script: remediate_cis_1_2.sh
# Purpose: Harden DNF and Configure Local Repository

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

DNF_CONF="/etc/dnf/dnf.conf"
echo -e "\n[+] Applying Remediation for Package Management (CIS 1.2)..."

set_dnf_option() {
    local option=$1
    local value=$2
    if grep -q "^${option}=" "$DNF_CONF"; then
        sed -i "s/^${option}=.*/${option}=${value}/" "$DNF_CONF"
    else
        echo "${option}=${value}" >> "$DNF_CONF"
    fi
    echo "  [+] Set $option=$value in $DNF_CONF"
}

# 1. Global Settings
set_dnf_option "gpgcheck" "1"
set_dnf_option "localpkg_gpgcheck" "1"
set_dnf_option "repo_gpgcheck" "0"

# 2. Fix Repo Overrides and Ensure GPG Key (Change gpgcheck=0 to gpgcheck=1)
echo -e "\n  [*] Fixing gpgcheck and ensuring gpgkey is set in repository files..."

# Import the Oracle GPG Key globally to prevent interactive prompts
if [ -f /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle ]; then
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
    echo "  [+] Oracle GPG Key imported successfully."
fi

# Loop through all repo files to enforce gpgcheck and append gpgkey if missing
for repo in /etc/yum.repos.d/*.repo; do
    if [ -f "$repo" ]; then
        # 1. Change gpgcheck=0 to gpgcheck=1
        if grep -qir '^gpgcheck\s*=\s*0' "$repo"; then
            sed -i 's/^gpgcheck\s*=\s*0/gpgcheck=1/ig' "$repo"
            echo "  [+] Fixed: Changed 'gpgcheck=0' to 'gpgcheck=1' in $repo"
        fi
        
        # 2. Add gpgkey if it does not exist in the file
        if ! grep -qi '^gpgkey\s*=' "$repo"; then
            echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle" >> "$repo"
            echo "  [+] Added 'gpgkey' path to $repo"
        fi
    fi
done


# 3. Configure Local Repository Template (if not exists)
# ... (ادامه اسکریپت قبلی برای ساخت offline-local.repo) ...

echo -e "\n[+] Package Management Hardening Completed."

