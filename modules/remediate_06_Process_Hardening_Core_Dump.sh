#!/bin/bash
# Script: remediate_cis_1_5.sh
# Purpose: Apply Process Hardening and Core Dump Limits (CIS 1.5)

if [ "$EUID" -ne 0 ]; then echo "Please run as root"; exit 1; fi

echo -e "\n[+] Applying Remediation for Process Hardening (CIS 1.5)..."

# 1. System-wide and Oracle Specific Core Dump Limits
echo "[*] Configuring Core Dump limits with Oracle exceptions..."
cat <<EOF > /etc/security/limits.d/99-disable_core.conf
# CIS 1.5.1: Disable core dumps for all users to prevent info leaks
* hard core 0

# Oracle Exception: Required for Oracle Database / Grid Diagnostics (MOS)
oracle soft core unlimited
oracle hard core unlimited
grid soft core unlimited
grid hard core unlimited
EOF
echo "  [+] Set limits in /etc/security/limits.d/99-disable_core.conf"

# 2. Systemd Coredump Configuration (OL9 Requirement)
echo "[*] Configuring systemd-coredump..."
mkdir -p /etc/systemd/coredump.conf.d/
cat <<EOF > /etc/systemd/coredump.conf.d/99-cis.conf
[Coredump]
Storage=none
ProcessSizeMax=0
EOF
systemctl daemon-reload
echo "  [+] Set Storage=none in systemd coredump config."

# 3. Sysctl Parameters for ASLR and Ptrace
echo "[*] Configuring kernel parameters (ASLR & Ptrace)..."
cat <<EOF > /etc/sysctl.d/50-process-hardening.conf
# CIS 1.5.2: Enable ASLR
kernel.randomize_va_space = 2
# CIS 1.5.3: Restrict Ptrace
kernel.yama.ptrace_scope = 1
EOF

# Apply sysctl parameters
sysctl -q -p /etc/sysctl.d/50-process-hardening.conf
echo "  [+] Applied kernel.randomize_va_space=2 and kernel.yama.ptrace_scope=1"

echo -e "\n[+] Process hardening applied successfully."

