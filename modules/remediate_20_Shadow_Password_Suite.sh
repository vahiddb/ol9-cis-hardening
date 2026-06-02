#!/bin/bash

# 1. Update /etc/login.defs
sed -i -E 's/^\s*PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs
sed -i -E 's/^\s*PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
sed -i -E 's/^\s*PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs
sed -i -E 's/^\s*ENCRYPT_METHOD.*/ENCRYPT_METHOD YESCRYPT/' /etc/login.defs

# 2. Update inactive password lock (useradd default)
useradd -D -f 30

# 3. Apply changes to existing users (excluding oracle, grid, root, opc)
for user in $(awk -F: '($3 == "" || $3 > 0) && $1 != "root" && $1 != "oracle" && $1 != "grid" && $1 != "opc" {print $1}' /etc/shadow); do
    chage --maxdays 365 --mindays 1 --warndays 7 --inactive 30 "$user"
done

# Fix any users with future password change dates to today
CURRENT_DAY=$(($(date +%s) / 86400))
for user in $(awk -F: -v today="$CURRENT_DAY" '$3 > today {print $1}' /etc/shadow); do
    chage --lastday "$CURRENT_DAY" "$user"
done

echo "Configuration applied successfully. Note: 'oracle' and 'grid' users were explicitly excluded from password aging."
