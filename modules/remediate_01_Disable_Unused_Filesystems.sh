#!/bin/bash
# Script: remediate_cis_1_1_1.sh
# Purpose: Remediate Filesystem Kernel Modules (CIS 1.1.1)

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

MODULES=("cramfs" "freevxfs" "hfs" "hfsplus" "jffs2" "squashfs" "udf" "usb-storage")
CONF_DIR="/etc/modprobe.d"

echo -e "\n[+] Applying Remediation for CIS 1.1.1: Filesystem Kernel Modules..."

for mod in "${MODULES[@]}"; do
    CONF_FILE="$CONF_DIR/cis_1_1_1_${mod}.conf"
    
    # Create configuration file to disable module
    echo "install $mod /bin/true" > "$CONF_FILE"
    echo "blacklist $mod" >> "$CONF_FILE"
    chmod 644 "$CONF_FILE"
    
    # Unload the module if it is currently loaded in the kernel
    if lsmod | grep -q "^$mod "; then
        rmmod "$mod" 2>/dev/null || modprobe -r "$mod" 2>/dev/null
        echo "  [*] Unloaded active module: $mod"
    fi
    
    echo "  [+] Disabled and blacklisted: $mod"
done

echo -e "[+] Remediation applied successfully. (Run audit script to verify)\n"
