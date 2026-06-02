#!/bin/bash

# CIS 6.1.1: Install AIDE
if ! rpm -q aide &>/dev/null; then
    dnf install -y aide
fi

# CIS 6.1.3: Protect Audit Tools
AIDE_CONF="/etc/aide.conf"
if ! grep -q "/sbin/auditctl" "$AIDE_CONF"; then
    echo "" >> "$AIDE_CONF"
    echo "# CIS 6.1.3: Protect Audit Tools" >> "$AIDE_CONF"
    echo "/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
    echo "/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
    echo "/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
    echo "/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
    echo "/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
    echo "/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512" >> "$AIDE_CONF"
fi

# Oracle/Grid Exclusion
if ! grep -q "!/u01" "$AIDE_CONF"; then
    echo "" >> "$AIDE_CONF"
    echo "# Exclude Oracle Database and Grid Paths to prevent I/O overhead and false positives" >> "$AIDE_CONF"
    echo "!/u01" >> "$AIDE_CONF"
    echo "!/u02" >> "$AIDE_CONF"
    echo "!/opt/oracle" >> "$AIDE_CONF"
fi

# Initialize AIDE Database if not exists
if [ ! -f /var/lib/aide/aide.db.gz ]; then
    echo "Initializing AIDE database (This may take a while)..."
    aide --init
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

# CIS 6.1.2: Configure Regular Checks (Cron)
CRON_FILE="/etc/cron.d/aide"
if [ ! -f "$CRON_FILE" ]; then
    echo "0 5 * * * root /usr/sbin/aide --check" > "$CRON_FILE"
    chmod 0644 "$CRON_FILE"
fi

echo "AIDE configured successfully."
