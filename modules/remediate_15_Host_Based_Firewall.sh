#!/bin/bash
# Script: remediation15.sh
# Purpose: Configure firewalld with nftables and Oracle RAC Rules (CIS 4)

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

echo "=========================================================================="
echo " Applying Remediation for CIS 4 (Firewall)"
echo " Oracle Context: Setting nftables, opening RAC Public ports,"
echo " and prompting for RAC Private Interconnect setup."
echo "=========================================================================="

echo -e "\n[*] Configuring firewalld..."

# 1. Ensure firewalld is running
systemctl unmask firewalld >/dev/null 2>&1
systemctl enable --now firewalld >/dev/null 2>&1
echo -e "  \e[32m[OK]\e[0m Enabled and started firewalld."

# 2. Enforce FirewallBackend=nftables
sed -i 's/^FirewallBackend=.*/FirewallBackend=nftables/' /etc/firewalld/firewalld.conf
systemctl restart firewalld
echo -e "  \e[32m[OK]\e[0m FirewallBackend set to nftables."

# 3. Add Required Oracle RAC/Grid and SSH ports
# 1521 (Listener), 1522 (SCAN), 6200 (ONS), 3872 (OEM), 7654 (Custom), 22/22022 (SSH)
PORTS=("22/tcp" "22022/tcp" "1521/tcp" "1522/tcp" "6200/tcp" "7654/tcp" "3872/tcp")

for PORT in "${PORTS[@]}"; do
    firewall-cmd --permanent --add-port="$PORT" >/dev/null 2>&1
done
echo -e "  \e[32m[OK]\e[0m Added standard Oracle RAC and admin ports."

# 4. RAC Private Interconnect Handling
echo -e "\n\e[33m[?] Do you want to add a Private Interface (Interconnect) to the 'trusted' zone for RAC? (y/n)\e[0m"
read -r add_trusted
if [[ "$add_trusted" =~ ^[Yy]$ ]]; then
    echo -e "Enter the private interface name (e.g., eth1, ens192):"
    read -r priv_iface
    if [ -n "$priv_iface" ]; then
        firewall-cmd --permanent --zone=trusted --add-interface="$priv_iface" >/dev/null 2>&1
        echo -e "  \e[32m[OK]\e[0m Added $priv_iface to trusted zone."
    fi
fi

# 5. Reload and Show
firewall-cmd --reload >/dev/null 2>&1
echo -e "\n\e[32m[+] REMEDIATION APPLIED SUCCESSFULLY\e[0m"

echo -e "\nActive Ports in default zone:"
firewall-cmd --list-ports
echo "Trusted Interfaces:"
firewall-cmd --zone=trusted --list-interfaces

