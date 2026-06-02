#!/bin/bash
# Script: audit9.sh
# Purpose: Audit GNOME Display Manager (GDM) and Boot Target (CIS 1.8)

echo "=========================================================================="
echo " CIS Requirement: 1.8 GNOME Display Manager"
echo " - Ensure GDM is removed or disabled."
echo " - Ensure default boot target is multi-user.target."
echo " Oracle Context:"
echo " - Highly Recommended. GUI is not needed for Oracle DB/RAC."
echo " - Removing GDM saves resources and reduces attack surface."
echo "=========================================================================="

FAIL_COUNT=0

echo -e "\n[*] Auditing GDM Package and Boot Target..."

# 1. Check if GDM is installed
if rpm -q gdm > /dev/null 2>&1; then
    echo -e "  \e[31m[FAIL]\e[0m GDM package is installed."
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo -e "  \e[32m[PASS]\e[0m GDM package is not installed."
fi

# 2. Check default boot target
CURRENT_TARGET=$(systemctl get-default)
if [ "$CURRENT_TARGET" == "multi-user.target" ]; then
    echo -e "  \e[32m[PASS]\e[0m System default target is $CURRENT_TARGET."
else
    echo -e "  \e[31m[FAIL]\e[0m Default target is $CURRENT_TARGET (Expected: multi-user.target)."
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n\e[32m[+] AUDIT RESULT: PASS\e[0m"
else
    echo -e "\n\e[31m[-] AUDIT RESULT: FAIL ($FAIL_COUNT issues found)\e[0m"
fi

