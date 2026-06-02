#!/bin/bash
# Script: remediate_cis_6_3_3.sh
# Purpose: Harden Auditd Rules

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

RULES_FILE="/etc/audit/rules.d/50-cis.rules"
echo -e "\n[+] Configuring Audit Rules in $RULES_FILE..."

cat << 'INNER_EOF' > $RULES_FILE
# 6.3.3.1 sudoers
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope

# 6.3.3.2 actions as another user
-a always,exit -F arch=b64 -C euid!=uid -F auid>=1000 -F auid!=unset -S execve -k suexec
-a always,exit -F arch=b32 -C euid!=uid -F auid>=1000 -F auid!=unset -S execve -k suexec

# 6.3.3.3 sudo log (Fixed key to match audit)
-w /var/log/sudo.log -p wa -k sudo_log_file

# 6.3.3.4 date and time
-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change
-w /etc/localtime -p wa -k time-change

# 6.3.3.5 network environment
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale

# 6.3.3.7 unsuccessful file access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=unset -k access
-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=unset -k access

# 6.3.3.8 user/group information
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# 6.3.3.9 DAC permission
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=unset -k perm_mod
-a always,exit -F arch=b64 -S chown,fchown,fchownat,lchown -F auid>=1000 -F auid!=unset -k perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=unset -k perm_mod

# 6.3.3.10 mounts
-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=unset -k mounts

# 6.3.3.11 & 12 sessions and logins
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins

# 6.3.3.13 file deletion
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=unset -k delete

# 6.3.3.14 MAC
-w /etc/selinux/ -p wa -k MAC-policy

# 6.3.3.19 kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules
INNER_EOF

# Add Privileged Commands dynamically (6.3.3.6 and 6.3.3.15 to 18)
# Added arch=b64 to prevent performance warnings during augenrules
echo "[*] Discovering and adding privileged commands rules..."
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print "-a always,exit -F arch=b64 -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=unset -k privileged" }' >> $RULES_FILE

# 6.3.3.20 Make configuration immutable
# Changed to -e 1 to accommodate Oracle environment exceptions
echo "-e 1" > /etc/audit/rules.d/99-finalize.rules

# Load rules into running config
echo "[*] Loading new auditd rules..."
augenrules --load

echo -e "[+] Auditd Rules applied successfully.\n"
