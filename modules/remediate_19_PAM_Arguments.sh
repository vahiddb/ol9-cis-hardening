#!/bin/bash

# =====================================================================
# OS Security Standard Remediation Script - Section 19
# Oracle Context: Strict password policies and lockout mechanisms.
# Oracle Exception: High faillock deny counts could lock out 'oracle' 
# or 'grid'.
# =====================================================================

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m[ERROR] This script must be run as root.\033[0m"
  exit 1
fi

echo -e "\033[36m--- Configuring faillock.conf ---\033[0m"
FAILLOCK_CONF="/etc/security/faillock.conf"
sed -i -E 's/^\s*#?\s*deny\s*=.*/deny = 5/' $FAILLOCK_CONF
sed -i -E 's/^\s*#?\s*unlock_time\s*=.*/unlock_time = 900/' $FAILLOCK_CONF
sed -i -E 's/^\s*#?\s*even_deny_root.*/even_deny_root/' $FAILLOCK_CONF
grep -q "^deny = 5" $FAILLOCK_CONF || echo "deny = 5" >> $FAILLOCK_CONF
grep -q "^unlock_time = 900" $FAILLOCK_CONF || echo "unlock_time = 900" >> $FAILLOCK_CONF
grep -q "^even_deny_root" $FAILLOCK_CONF || echo "even_deny_root" >> $FAILLOCK_CONF

echo -e "\033[36m--- Configuring pwquality.conf ---\033[0m"
PWQUAL_CONF="/etc/security/pwquality.conf"
sed -i -E 's/^\s*#?\s*difok\s*=.*/difok = 8/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*minlen\s*=.*/minlen = 14/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*minclass\s*=.*/minclass = 4/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*maxrepeat\s*=.*/maxrepeat = 3/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*maxsequence\s*=.*/maxsequence = 3/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*dictcheck\s*=.*/dictcheck = 1/' $PWQUAL_CONF
sed -i -E 's/^\s*#?\s*enforce_for_root.*/enforce_for_root/' $PWQUAL_CONF
grep -q "^maxsequence = 3" $PWQUAL_CONF || echo "maxsequence = 3" >> $PWQUAL_CONF

echo -e "\033[36m--- Configuring Custom Authselect Profile (oracle-sssd) ---\033[0m"
CUSTOM_PROFILE_DIR="/etc/authselect/custom/oracle-sssd"

if [ ! -d "$CUSTOM_PROFILE_DIR" ]; then
    echo -e "\033[33m[WARN] Custom profile 'oracle-sssd' not found. Creating it from sssd...\033[0m"
    authselect create-profile oracle-sssd -b sssd --symlinks
fi

for pam_file in "$CUSTOM_PROFILE_DIR/system-auth" "$CUSTOM_PROFILE_DIR/password-auth"; do
    if [ -f "$pam_file" ]; then
        # 1. Update pam_unix.so to use yescrypt instead of sha512
        sed -i 's/\bsha512\b/yescrypt/g' "$pam_file"

        # 2. Add remember=5 and enforce_for_root to pam_pwhistory.so
        # First ensure the line has the required parameters, if not, append them
        if grep -q "pam_pwhistory.so" "$pam_file"; then
            sed -i -E 's/(pam_pwhistory\.so.*)/\1/' "$pam_file"
            # Safely add remember=5 if missing
            if ! grep -q "pam_pwhistory.so.*remember=" "$pam_file"; then
                sed -i 's/pam_pwhistory.so/pam_pwhistory.so remember=5/g' "$pam_file"
            fi
            # Safely add enforce_for_root if missing
            if ! grep -q "pam_pwhistory.so.*enforce_for_root" "$pam_file"; then
                sed -i 's/pam_pwhistory.so/pam_pwhistory.so enforce_for_root/g' "$pam_file"
            fi
        fi
    fi
done

echo -e "\033[36m--- Applying Authselect Changes ---\033[0m"
# Re-apply the custom profile with required features
authselect select custom/oracle-sssd with-faillock without-nullok with-pwhistory --force
authselect apply-changes

echo -e "\033[32m[OK] Section 19 Remediation completed.\033[0m"

