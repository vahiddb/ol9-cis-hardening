#!/bin/bash
# Script: audit_cis_1_1_1.sh
# Purpose: Audit Filesystem Kernel Modules (CIS 1.1.1)

MODULES=("cramfs" "freevxfs" "hfs" "hfsplus" "jffs2" "squashfs" "udf" "usb-storage")
FAIL_COUNT=0

# --- Audit Description Header ---
echo -e "\n=========================================================================="
echo -e "[+] AUDIT: CIS 1.1.1 - Filesystem Kernel Modules"
echo -e "--------------------------------------------------------------------------"
echo -e "CIS Requirement : Disable loading of unnecessary filesystem kernel modules"
echo -e "                  (cramfs, freevxfs, hfs, hfsplus, jffs2, squashfs, udf)"
echo -e "                  to reduce the attack surface."
echo -e "Oracle Context  : Fully compatible. No exceptions required for Oracle DB/RAC."
echo -e "==========================================================================\n"

for mod in "${MODULES[@]}"; do
    # Check if module loading is disabled
    LOAD_CHECK=$(modprobe -n -v "$mod" 2>/dev/null | grep -E "(install /bin/true|install /bin/false)")
    # Check if module is currently loaded in memory
    MEM_CHECK=$(lsmod | grep "^$mod ")

    if [[ -n "$LOAD_CHECK" ]] && [[ -z "$MEM_CHECK" ]]; then
        echo -e "  [PASS] Module '$mod' is securely disabled and not loaded."
    else
        echo -e "  [FAIL] Module '$mod' is NOT properly disabled or is currently loaded."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo -e "--------------------------------------------------------------------------"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "[+] AUDIT RESULT: PASSED (All unnecessary filesystem modules are disabled.)\n"
    exit 0
else
    echo -e "[-] AUDIT RESULT: FAILED ($FAIL_COUNT module(s) require remediation.)\n"
    exit 1
fi

