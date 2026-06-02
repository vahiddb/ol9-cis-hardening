#!/bin/bash
# Script: remediation8.sh
# Purpose: Configure Warning Banners and Permissions (CIS 1.7)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 1.7 (Command Line Warning Banners)"
echo " Oracle Context: Safe to apply. No impact on DB/RAC operations."
echo "=========================================================================="

BANNER_TEXT="Authorized uses only. All activity may be monitored and reported.
Individuals using this computer system without authority, or in excess of their authority, are subject to having all of their activities on this system monitored and recorded by system personnel.
Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity, system personnel may provide the evidence of such monitoring to law enforcement officials."

FILES=("/etc/motd" "/etc/issue" "/etc/issue.net")

for FILE in "${FILES[@]}"; do
    # 1. Update Content
    echo "$BANNER_TEXT" > "$FILE"

    # 2. Set Ownership and Permissions
    chown root:root "$FILE"
    chmod 0644 "$FILE"

    echo -e "  \e[32m[OK]\e[0m Configured content and permissions for $FILE."
done

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

