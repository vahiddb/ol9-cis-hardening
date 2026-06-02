#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

# 6.3.1.1
dnf install -y audit audit-libs

# 6.3.1.4
systemctl enable --now auditd

# 6.3.1.2 & 6.3.1.3 (GRUB)
grubby --update-kernel=ALL --args="audit=1 audit_backlog_limit=8192"

# 6.3.2 Data Retention (/etc/audit/auditd.conf)
sed -i 's/^max_log_file .*/max_log_file = 24/' /etc/audit/auditd.conf
sed -i 's/^max_log_file_action .*/max_log_file_action = keep_logs/' /etc/audit/auditd.conf
sed -i 's/^space_left .*/space_left = 25%/' /etc/audit/auditd.conf
# Note for Oracle: using SYSLOG instead of halt to prevent DB downtime
sed -i 's/^space_left_action .*/space_left_action = SYSLOG/' /etc/audit/auditd.conf
sed -i 's/^admin_space_left_action .*/admin_space_left_action = SYSLOG/' /etc/audit/auditd.conf

# Restart service
service auditd restart
