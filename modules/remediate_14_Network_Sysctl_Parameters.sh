#!/bin/bash

echo "Applying Network & Sysctl Hardening..."

# 3.1 Disable Wireless & Bluetooth
nmcli radio all off
systemctl disable --now bluetooth.service 2>/dev/null

# 3.2 Disable Network Kernel Modules
cat <<EOF > /etc/modprobe.d/cis_network_modules.conf
install dccp /bin/true
install tipc /bin/true
install rds /bin/true 
install sctp /bin/true
EOF

# 3.3 Configure Network Kernel Parameters (sysctl)
cat <<EOF > /etc/sysctl.d/60-cis-network.conf
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF

sysctl --system
echo "Network & Kernel parameters hardened successfully."
