#!/bin/bash
# Script: audit_cis_1_1_2.sh
# Purpose: Audit Filesystem Partitions and Mount Options (CIS 1.1.2 - 1.1.8)

FAIL_COUNT=0

echo -e "\n=========================================================================="
echo -e "[+] AUDIT: CIS 1.1.2 to 1.1.8 - Partitions & Mount Options"
echo -e "--------------------------------------------------------------------------"
echo -e "CIS Requirement : Separate partitions for /tmp, /dev/shm, /home, /var,"
echo -e "                  /var/tmp, /var/log, /var/log/audit."
echo -e "                  Mount options: nodev, nosuid, noexec (where applicable)."
echo -e "Oracle Context  : CRITICAL EXCEPTION! /dev/shm MUST NOT have 'noexec'."
echo -e "                  Oracle DB/RAC requires execution rights on /dev/shm."
echo -e "                  /tmp also might need exec during Oracle installation,"
echo -e "                  but can be noexec post-install. Assuming post-install."
echo -e "==========================================================================\n"

# Format: "Partition:Required_Options"
declare -A PART_REQS=(
    ["/tmp"]="nodev,nosuid,noexec"
    ["/dev/shm"]="nodev,nosuid"  # EXCEPTION: noexec is omitted for Oracle
    ["/home"]="nodev,nosuid"
    ["/var"]="nodev,nosuid"
    ["/var/tmp"]="nodev,nosuid,noexec"
    ["/var/log"]="nodev,nosuid,noexec"
    ["/var/log/audit"]="nodev,nosuid,noexec"
)

for part in "${!PART_REQS[@]}"; do
    req_opts="${PART_REQS[$part]}"
    MOUNT_INFO=$(findmnt -n -o OPTIONS "$part" 2>/dev/null)

    if [ -z "$MOUNT_INFO" ]; then
        echo -e "  [FAIL] $part is NOT a separate partition!"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        # Check each required option
        IFS=',' read -ra OPTS <<< "$req_opts"
        MISSING_OPTS=""
        for opt in "${OPTS[@]}"; do
            if ! echo "$MOUNT_INFO" | grep -qw "$opt"; then
                MISSING_OPTS="$MISSING_OPTS $opt"
            fi
        done

        if [ -n "$MISSING_OPTS" ]; then
            echo -e "  [FAIL] $part exists but missing options:$MISSING_OPTS (Current: $MOUNT_INFO)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        else
            echo -e "  [PASS] $part exists with secure options ($req_opts)"
        fi
    fi
done

echo -e "--------------------------------------------------------------------------"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "[+] AUDIT RESULT: PASSED (All partitions and mount options are secure.)\n"
    exit 0
else
    echo -e "[-] AUDIT RESULT: FAILED ($FAIL_COUNT issue(s) detected.)\n"
    exit 1
fi

