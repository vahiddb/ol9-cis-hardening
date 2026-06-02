#!/bin/bash
# Script: audit10.sh
# Purpose: Audit unnecessary Server Services and MTA configuration (CIS 2.1)

echo "=========================================================================="
echo " CIS Requirement: 2.1 Server Services"
echo " - Ensure unnecessary services are disabled or not installed."
echo " - Ensure MTA (Postfix) is configured for local-only mode."
echo " Oracle Context:"
echo " - Disabling 'nfs-server' does NOT affect RMAN backups using NFS Client."
echo " - Local-only MTA is fully compatible with Oracle Database email alerts."
echo "=========================================================================="

FAIL_COUNT=0
SERVICES=(
    autofs avahi-daemon dhcpd named dnsmasq smb vsftpd dovecot
    nfs-server rpcbind ypserv cups rsyncd snmpd telnet.socket
    tftp.socket squid httpd nginx xinetd
)

echo -e "\n[*] Auditing Unnecessary Services..."
for srv in "${SERVICES[@]}"; do
    if systemctl is-enabled "$srv" 2>/dev/null | grep -q 'enabled'; then
        echo -e "  \e[31m[FAIL]\e[0m Service $srv is ENABLED."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo -e "  \e[32m[PASS]\e[0m Service $srv is disabled/masked or not installed."
    fi
done

echo -e "\n[*] Auditing MTA (Postfix) listening interfaces..."
if ss -lntp | grep ':$25$' | grep -qvE '127.0.0.1|::1'; then
    echo -e "  \e[31m[FAIL]\e[0m MTA is listening on a non-loopback interface."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m MTA is configured securely (local-only or not listening)."
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

