#!/bin/bash
# Script: remediation18.sh
# Purpose: Remediation Script for PAM & Authselect with Oracle Exclusions (CIS 5.3)

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[!] Please run as root\e[0m"
    exit 1
fi

echo "=========================================================================="
echo " Remediation Script for PAM Packages & Authselect Profile (CIS 5.3)"
echo " Action: Creating custom authselect profile to implement 'with-faillock'"
echo "         while explicitly excluding 'oracle' and 'grid' accounts."
echo "=========================================================================="

# Variables for custom profile
CUSTOM_PROFILE_NAME="oracle-sssd"
BASE_PROFILE="sssd"
CUSTOM_DIR="/etc/authselect/custom/$CUSTOM_PROFILE_NAME"

echo -e "\n[*] 1. Creating Custom Authselect Profile for Oracle..."
# Ensure any broken previous attempts are cleaned up
rm -rf "$CUSTOM_DIR"

echo "Creating custom profile '$CUSTOM_PROFILE_NAME' based on '$BASE_PROFILE'..."
# Without --symlinks to ensure physical files are copied and modifiable
authselect create-profile "$CUSTOM_PROFILE_NAME" -b "$BASE_PROFILE"

if [ ! -d "$CUSTOM_DIR" ]; then
    echo -e "\e[31m[!] Error: Failed to create custom authselect profile!\e[0m"
    exit 1
fi

echo -e "\n[*] 2. Injecting Faillock Bypass logic for 'oracle' and 'grid' users..."
BYPASS_RULE="auth        [success=1 default=ignore]                   pam_succeed_if.so user in oracle:grid"

for pam_file in system-auth password-auth; do
    FILE_PATH="$CUSTOM_DIR/$pam_file"
    if [ -f "$FILE_PATH" ]; then
        # Insert bypass rule right above the first occurrence of pam_faillock preauth
        sed -i "/pam_faillock.so preauth/i $BYPASS_RULE" "$FILE_PATH"
        
        # Insert bypass rule right above pam_faillock authfail
        sed -i "/pam_faillock.so authfail/i $BYPASS_RULE" "$FILE_PATH"
        
        # Insert bypass rule right above pam_faillock authsucc
        sed -i "/pam_faillock.so authsucc/i $BYPASS_RULE" "$FILE_PATH"
        
        echo " -> Injected successfully into $pam_file"
    else
        echo " -> Warning: File $pam_file not found in custom directory!"
    fi
done

echo -e "\n[*] 3. Applying the new Custom Oracle Profile..."
# Select the profile. In EL9 the path prefix 'custom/' is required.
authselect select "custom/$CUSTOM_PROFILE_NAME" with-faillock without-nullok --force

echo -e "\n[*] 4. Forcing Authselect changes to PAM stack..."
authselect apply-changes

echo -e "\n[*] Current Authselect Configuration:"
authselect current

echo "=========================================================================="
echo -e "\e[32m[+] Remediation completed.\e[0m"
echo -e "Please run audit18.sh to verify."

