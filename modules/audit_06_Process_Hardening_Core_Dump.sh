#!/bin/bash
# Script: audit_cis_1_5.sh
# Purpose: Audit Process Hardening & Core Dumps (CIS 1.5)

echo "=========================================================================="
echo " CIS Requirement: 1.5 Process Hardening"
echo " - Ensure core dumps are restricted (systemd & limits.conf)."
echo " - Ensure ASLR is enabled (kernel.randomize_va_space=2)."
echo " - Ensure ptrace scope is restricted."
echo " Oracle Context:"
echo " 1. ASLR is fully supported and recommended by Oracle."
echo " 2. Core dumps MUST NOT be restricted for 'oracle' and 'grid' users."
echo "    They are required by Oracle Support for critical diagnostics (MOS)."
echo " 3. Restricting ptrace (scope=1) might require root privileges if DBA"
echo "    needs to run strace/pstack on running Oracle processes."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] 1. Checking Core Dump Limits (limits.conf)..."
# Using -h to hide filenames during grep, ensuring ^# works correctly.
LIMIT_CHECK=$(grep -h -r "^\s*\*\s\+hard\s\+core\s\+0" /etc/security/limits.conf /etc/security/limits.d/ 2>/dev/null)
if [ -n "$LIMIT_CHECK" ]; then
    echo -e "  \e[32m[PASS]\e[0m System-wide core dumps are disabled in limits.conf (* hard core 0)."
else
    echo -e "  \e[31m[FAIL]\e[0m System-wide core dumps are NOT explicitly disabled in limits.conf."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 2. Checking Oracle/Grid Core Dump Exceptions..."
ORA_LIMIT=$(grep -h -r "^\s*oracle\s\+hard\s\+core\s\+unlimited" /etc/security/limits.conf /etc/security/limits.d/ 2>/dev/null)
if [ -n "$ORA_LIMIT" ]; then
    echo -e "  \e[32m[PASS]\e[0m Oracle exceptions for core dumps are correctly configured."
else
    echo -e "  \e[33m[WARN]\e[0m Oracle exceptions for core dumps are missing. This impacts diagnostics."
    # Not failing the CIS check, but warning for Oracle context
fi

echo -e "\n[*] 3. Checking Systemd Coredump Configuration..."
# Checking both main conf and drop-in directories
SYSTEMD_CORE=$(grep -h -E "^\s*Storage\s*=\s*none" /etc/systemd/coredump.conf /etc/systemd/coredump.conf.d/*.conf 2>/dev/null)
if [ -n "$SYSTEMD_CORE" ]; then
    echo -e "  \e[32m[PASS]\e[0m Systemd coredump storage is set to 'none'."
else
    echo -e "  \e[31m[FAIL]\e[0m Systemd coredump storage is NOT set to 'none'."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 4. Checking ASLR (kernel.randomize_va_space)..."
ASLR=$(sysctl -n kernel.randomize_va_space 2>/dev/null)
if [ "$ASLR" == "2" ]; then
    echo -e "  \e[32m[PASS]\e[0m ASLR is enabled."
else
    echo -e "  \e[31m[FAIL]\e[0m ASLR is disabled or misconfigured (Current: $ASLR)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo -e "\n[*] 5. Checking Ptrace Scope (kernel.yama.ptrace_scope)..."
PTRACE=$(sysctl -n kernel.yama.ptrace_scope 2>/dev/null)
if [ "$PTRACE" -ge 1 ]; then
    echo -e "  \e[32m[PASS]\e[0m Ptrace scope is restricted (Current: $PTRACE)."
else
    echo -e "  \e[31m[FAIL]\e[0m Ptrace scope is NOT restricted (Current: $PTRACE)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

