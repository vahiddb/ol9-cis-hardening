#!/bin/bash

# 5.4.3.1 Remove nologin from /etc/shells
sed -i '/nologin/d' /etc/shells

# 5.4.3.2 Configure TMOUT (900 seconds) in a profile drop-in
cat << 'EOF' > /etc/profile.d/tmout.sh
readonly TMOUT=900
export TMOUT
EOF
chmod 0644 /etc/profile.d/tmout.sh

# 5.4.3.3 Configure default umask
cat << 'EOF' > /etc/profile.d/umask.sh
if [ $UID -gt 199 ] && [ "`/usr/bin/id -gn`" = "`/usr/bin/id -un`" ]; then
    umask 002
else
    umask 027
fi
EOF
chmod 0644 /etc/profile.d/umask.sh

# 5.4.2.7 & 5.4.2.8 Lock system accounts and set shell to nologin
MIN_UID=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
for user in $(awk -F: -v uid="$MIN_UID" '$3 < uid && $1 != "root" && $1 != "sync" && $1 != "shutdown" && $1 != "halt" {print $1}' /etc/passwd); do
    usermod -s /sbin/nologin "$user"
    usermod -L "$user"
done

# Ensure oracle/grid umask bypass (Oracle DBA Note)
for o_user in oracle grid; do
    if id "$o_user" &>/dev/null; then
        grep -q "umask 022" /home/$o_user/.bash_profile || echo "umask 022" >> /home/$o_user/.bash_profile
    fi
done

echo "System accounts and default environment secured."
