#!/bin/bash
# Script: remediation10.sh
# Purpose: Disable unnecessary services and configure MTA (CIS 2.1)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 2.1 (Server Services & MTA)"
echo " Oracle Context: Safe for DB/RAC. NFS Client & DB Alerts remain functional."
echo "=========================================================================="

SERVICES=(
    autofs avahi-daemon dhcpd named dnsmasq smb vsftpd dovecot
    nfs-server rpcbind ypserv cups rsyncd snmpd telnet.socket
    tftp.socket squid httpd nginx xinetd
)

echo -e "\n[*] Stopping and Masking unnecessary services..."
for srv in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$srv" 2>/dev/null; then
        systemctl stop "$srv"
        echo -e "  \e[32m[OK]\e[0m Stopped $srv"
    fi
    if ! systemctl is-enabled --quiet "$srv" 2>/dev/null | grep -q 'masked'; then
        systemctl mask "$srv" 2>/dev/null
        echo -e "  \e[32m[OK]\e[0m Masked $srv"
    fi
done

echo -e "\n[*] Removing X Window Server packages (if any)..."
dnf remove -y xorg-x11-server-common > /dev/null 2>&1
echo -e "  \e[32m[OK]\e[0m X Window packages removed."

echo -e "\n[*] Configuring MTA (Postfix) for local-only mode..."
if rpm -q postfix > /dev/null 2>&1; then
    sed -i 's/^inet_interfaces =.*/inet_interfaces = loopback-only/' /etc/postfix/main.cf
    systemctl restart postfix
    echo -e "  \e[32m[OK]\e[0m Postfix set to loopback-only."
else
    echo -e "  \e[32m[OK]\e[0m Postfix is not installed."
fi

echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

