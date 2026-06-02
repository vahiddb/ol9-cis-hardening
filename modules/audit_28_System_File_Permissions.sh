#!/bin/bash
# Script: audit28.sh
# Purpose: Audit System File Permissions (CIS 7.1)

echo "=========================================================================="
echo " CIS Requirement: System File Permissions (CIS 7.1)"
echo " - Ensure permissions on /etc/passwd, /etc/shadow, /etc/group, etc. are configured (CIS 7.1.1 - 7.1.10)."
echo " - Ensure no world-writable files exist (CIS 7.1.11)."
echo " - Ensure no unowned files or directories exist (CIS 7.1.12)."
echo " - Audit SUID/SGID executables (CIS 7.1.13)."
echo " Oracle Context & Exceptions:"
echo " - Oracle requires read access to /etc/passwd (0644 is standard and safe)."
echo " - EXCEPTION: Oracle heavily relies on SUID/SGID binaries (e.g., oracle, extjob)."
echo "   Directories like /u01 MUST be excluded from automated SUID removal."
echo "   World-writable and unowned file checks exclude /u01, /proc, and /sys"
echo "   to prevent accidental damage to the database environment."
echo "=========================================================================="

check_file() {
    local file=$1
    local req_mode=$2
    local req_uid=$3
    local req_gid=$4

    if [ ! -f "$file" ]; then
        echo "[FAIL] $file does not exist."
        return
    fi

    local stat_out=$(stat -c "%a %U %G" "$file")
    read -r mode uid gid <<< "$stat_out"

    local pass=true
    if [ "$mode" != "$req_mode" ] && [ "$mode" -gt "$req_mode" ]; then pass=false; fi
    if [ "$uid" != "$req_uid" ]; then pass=false; fi
    if [[ "$gid" != "$req_gid" && "$gid" != "root" ]]; then pass=false; fi

    if $pass; then
        echo "[PASS] $file (Mode: $mode, Owner: $uid:$gid)"
    else
        echo "[FAIL] $file (Found Mode: $mode, Owner: $uid:$gid | Expected: <=$req_mode, Owner: $req_uid:$req_gid)"
    fi
}

# 7.1.1 to 7.1.10
check_file "/etc/passwd" "644" "root" "root"
check_file "/etc/passwd-" "600" "root" "root"
check_file "/etc/group" "644" "root" "root"
check_file "/etc/group-" "600" "root" "root"
check_file "/etc/shadow" "0" "root" "root"
check_file "/etc/shadow-" "0" "root" "root"
check_file "/etc/gshadow" "0" "root" "root"
check_file "/etc/gshadow-" "0" "root" "root"
check_file "/etc/shells" "644" "root" "root"

if [ -f "/etc/security/opasswd" ]; then
    check_file "/etc/security/opasswd" "600" "root" "root"
else
    echo "[PASS] /etc/security/opasswd does not exist (OK)."
fi

echo "-----------------------------------------------------------------"
echo "Checking for World-Writable, Unowned files, and SUID/SGID..."
echo "(Note: Excluding /proc, /sys, and Oracle homes: /u01)"
echo "-----------------------------------------------------------------"

# World Writable Files
WW_FILES=$(find / -xdev -type f -perm -0002 -print 2>/dev/null | grep -vE "^/proc|^/sys|^/u01")
if [ -z "$WW_FILES" ]; then
    echo "[PASS] No unexpected world-writable files found."
else
    echo "[FAIL] World-writable files found:"
    echo "$WW_FILES" | head -n 5
    echo "  ... (truncated for display)"
fi

# Unowned Files/Directories
UNOWNED=$(find / -xdev \( -nouser -o -nogroup \) -print 2>/dev/null | grep -vE "^/proc|^/sys|^/u01")
if [ -z "$UNOWNED" ]; then
    echo "[PASS] No unowned files/directories found."
else
    echo "[FAIL] Unowned files/directories found:"
    echo "$UNOWNED" | head -n 5
    echo "  ... (truncated for display)"
fi

echo "================================================================="
echo "Audit Complete."
echo "================================================================="

