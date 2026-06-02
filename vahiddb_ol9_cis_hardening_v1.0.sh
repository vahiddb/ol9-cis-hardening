#!/bin/bash

# ==============================================================================
# Oracle Linux 9 CIS Hardening Orchestrator (vahiddb)
# Description: Wrapper script to execute Audit and Remediation modules.
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

MODULES_DIR="modules"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR] This script must be run as root.${NC}"
   exit 1
fi

# Ensure modules directory exists
if [[ ! -d "$MODULES_DIR" ]]; then
   echo -e "${RED}[ERROR] Modules directory '$MODULES_DIR' not found! Make sure it exists in the same directory as this script.${NC}"
   exit 1
fi

# Function to run all scripts of a specific type (audit or remediate)
run_all() {
    local type=$1
    echo -e "${CYAN}Starting All $type Modules...${NC}"
    # Look inside the modules directory
    for script in "$MODULES_DIR"/${type}_*.sh; do
        if [[ -f "$script" && -x "$script" ]]; then
            echo -e "${YELLOW}Executing: $script${NC}"
            "$script"
            echo "--------------------------------------------------"
        fi
    done
    echo -e "${GREEN}All $type Modules Completed.${NC}"
}

# Function to run a specific module
run_specific() {
    local type=$1
    echo -e "\n${YELLOW}Available ${type^} Modules:${NC}"

    # List all matching scripts, extract number and name, and format them clearly
    for script in "$MODULES_DIR"/${type}_*.sh; do
        if [[ -f "$script" ]]; then
            # Extract filename without the path
            filename=$(basename "$script")
            # Extract number and name (e.g., from audit_01_Name.sh to 01 - Name)
            module_info=$(echo "$filename" | sed -E "s/^${type}_([0-9]{2})_(.*)\.sh$/\1 - \2/")
            # Replace underscores with spaces for readability
            module_info=$(echo "$module_info" | tr '_' ' ')
            echo "  $module_info"
        fi
    done

    echo ""
    read -p "Enter module number (e.g., 01, 15, 29): " num

    # Pad single digits with zero
    if [[ ${#num} -eq 1 ]]; then
        num="0${num}"
    fi

    # Find the specific script in the modules directory
    script=$(ls "$MODULES_DIR"/${type}_${num}_*.sh 2>/dev/null | head -n 1)

    if [[ -f "$script" && -x "$script" ]]; then
        echo -e "${CYAN}Executing: $script${NC}"
        "$script"
        echo -e "${GREEN}Module $num execution completed.${NC}"
    else
        echo -e "${RED}[ERROR] Module $num not found or not executable in '$MODULES_DIR/'.${NC}"
        echo -e "${YELLOW}Hint: Ensure the file exists and has execute permissions (chmod +x $MODULES_DIR/*.sh)${NC}"
    fi
}

# Interactive Menu
show_menu() {
    while true; do
        echo -e "\n${CYAN}=================================================${NC}"
        echo -e "${CYAN}    Oracle Linux 9 CIS Hardening Framework       ${NC}"
        echo -e "${CYAN}              (By Vahid Nowrouzi)                ${NC}"
        echo -e "${CYAN}=================================================${NC}"
        echo "1) Run ALL Audits"
        echo "2) Run ALL Remediations"
        echo "3) Run a Specific Audit Module"
        echo "4) Run a Specific Remediation Module"
        echo "5) Exit"
        echo -e "${CYAN}=================================================${NC}"
        read -p "Select an option [1-5]: " choice

        case $choice in
            1) run_all "audit" ;;
            2)
               echo -e "${RED}[WARNING] Running all remediations may alter system configurations.${NC}"
               read -p "Are you sure you want to proceed? (y/n): " confirm
               if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                   run_all "remediate"
               fi
               ;;
            3) run_specific "audit" ;;
            4) run_specific "remediate" ;;
            5) echo "Exiting..."; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

# Main execution
show_menu

