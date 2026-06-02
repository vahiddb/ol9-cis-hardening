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

# 2. Fix Repo Overrides (Change gpgcheck=0 to gpgcheck=1 in all .repo files)
echo -e "\n  [*] Checking for gpgcheck overrides in repository files..."
if grep -qir '^gpgcheck\s*=\s*0' /etc/yum.repos.d/; then
    sed -i 's/^gpgcheck\s*=\s*0/gpgcheck=1/ig' /etc/yum.repos.d/*.repo
    echo "  [+] Fixed: Changed 'gpgcheck=0' to 'gpgcheck=1' in repository files."
else
    echo "  [INFO] No repository overrides found."
fi

# 3. Configure Local Repository Template (if not exists)
# ... (ادامه اسکریپت قبلی برای ساخت offline-local.repo) ...

echo -e "\n[+] Package Management Hardening Completed."

