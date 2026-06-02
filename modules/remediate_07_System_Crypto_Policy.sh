#!/bin/bash
# Script: remediate_cis_1_6.sh
# Purpose: Configure System-wide Crypto Policy based on CIS (CIS 1.6)
# Context: Oracle Linux 9 (Database/RAC compatible)

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Applying System-wide Crypto Policy (CIS 1.6)..."

# 1. Remove hardcoded crypto settings from SSH configs (CIS 1.6.2)
echo "[*] Cleaning up hardcoded crypto settings from sshd_config..."
sed -ri 's/^\s*(Ciphers|MACs|KexAlgorithms|GSSAPIKexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedKeyTypes)/# \1/' /etc/ssh/sshd_config
if ls /etc/ssh/sshd_config.d/*.conf 1> /dev/null 2>&1; then
    sed -ri 's/^\s*(Ciphers|MACs|KexAlgorithms|GSSAPIKexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedKeyTypes)/# \1/' /etc/ssh/sshd_config.d/*.conf
fi

# 2. Create custom policy module for SSH restrictions (CIS 1.6.4 to 1.6.7)
echo "[*] Creating custom module /etc/crypto-policies/policies/modules/CIS-SSH.pmod..."
cat <<EOF > /etc/crypto-policies/policies/modules/CIS-SSH.pmod
# Disable CBC and ChaCha20-Poly1305 for SSH
cipher@ssh = -*CBC -CHACHA20-POLY1305

# Disable MACs less than 128 bits
mac@ssh = -*MD5* -*UMAC-64*
EOF

# 3. Apply the Crypto Policy (CIS 1.6.1, 1.6.3)
echo "[*] Applying DEFAULT:NO-SHA1:CIS-SSH policy..."
update-crypto-policies --set DEFAULT:NO-SHA1:CIS-SSH

# 4. Restart SSHD to apply changes
echo "[*] Restarting SSHD service..."
systemctl restart sshd

echo -e "\n[+] Crypto policy updated and SSHD restarted successfully."

