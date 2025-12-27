#!/bin/bash

# Quick fix script for Python dependencies

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;96m'
YELLOW='\033[0;93m'
NC='\033[0m' # No Color

TOOLS_DIR="$HOME/toolsSubsprayer"

print_section() {
    printf "\n${BLUE}##################################################${NC}"
    printf "\n   ${BLUE}%s${NC}" "$1"
    printf "\n${BLUE}##################################################${NC}\n\n"
}

fix_venv_deps() {
    local tool_name=$1
    local tool_dir="$TOOLS_DIR/$tool_name"
    local venv_python="$tool_dir/venv/bin/python3"
    
    if [ ! -d "$tool_dir" ]; then
        printf "${RED}✗ $tool_name not found at $tool_dir${NC}\n"
        printf "${YELLOW}  Run ./install.sh to install missing tools${NC}\n"
        return 1
    fi
    
    # Check if venv exists and python is actually executable
    if [ ! -f "$venv_python" ] || [ ! -x "$venv_python" ] || ! "$venv_python" --version >/dev/null 2>&1; then
        printf "${YELLOW}Creating/recreating venv for $tool_name...${NC}\n"
        if ! cd "$tool_dir" 2>/dev/null; then
            printf "${RED}✗ Cannot access $tool_dir${NC}\n"
            return 1
        fi
        
        # Remove old venv if it exists but is broken
        if [ -d "venv" ]; then
            printf "${YELLOW}  Removing broken venv...${NC}\n"
            rm -rf venv
        fi
        
        if ! python3 -m venv venv 2>&1; then
            printf "${RED}✗ Failed to create venv for $tool_name${NC}\n"
            cd - >/dev/null 2>&1
            return 1
        fi
        
        venv_python="$tool_dir/venv/bin/python3"
        if [ ! -f "$venv_python" ] || ! "$venv_python" --version >/dev/null 2>&1; then
            printf "${RED}✗ Venv created but python3 not working at $venv_python${NC}\n"
            cd - >/dev/null 2>&1
            return 1
        fi
        cd - >/dev/null 2>&1
    fi
    
    printf "${YELLOW}Fixing dependencies for $tool_name...${NC}\n"
    
    case "$tool_name" in
        "Sublist3r")
            if ! "$venv_python" -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1; then
                printf "${RED}✗ Failed to upgrade pip${NC}\n"
            fi
            if ! "$venv_python" -m pip install --upgrade requests dnspython argparse >/dev/null 2>&1; then
                printf "${RED}✗ Failed to install dependencies${NC}\n"
                return 1
            fi
            if [ -f "$tool_dir/requirements.txt" ]; then
                "$venv_python" -m pip install --upgrade -r "$tool_dir/requirements.txt" >/dev/null 2>&1
            fi
            # Verify
            if "$venv_python" -c "import dns.resolver; import requests; import argparse" 2>/dev/null; then
                printf "${GREEN}✓ Sublist3r dependencies fixed${NC}\n"
                return 0
            else
                printf "${RED}✗ Failed to verify Sublist3r dependencies${NC}\n"
                printf "${YELLOW}  Trying to reinstall...${NC}\n"
                "$venv_python" -m pip install --force-reinstall dnspython requests argparse >/dev/null 2>&1
                if "$venv_python" -c "import dns.resolver; import requests" 2>/dev/null; then
                    printf "${GREEN}✓ Sublist3r dependencies fixed after reinstall${NC}\n"
                    return 0
                else
                    return 1
                fi
            fi
            ;;
        "github-search")
            if ! "$venv_python" -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1; then
                printf "${RED}✗ Failed to upgrade pip${NC}\n"
            fi
            if ! "$venv_python" -m pip install --upgrade requests dnspython argparse colored >/dev/null 2>&1; then
                printf "${RED}✗ Failed to install dependencies${NC}\n"
                return 1
            fi
            if [ -f "$tool_dir/requirements.txt" ]; then
                "$venv_python" -m pip install --upgrade -r "$tool_dir/requirements.txt" >/dev/null 2>&1
            fi
            # Verify
            if "$venv_python" -c "import colored; import requests; import argparse" 2>/dev/null; then
                printf "${GREEN}✓ GitHub search dependencies fixed${NC}\n"
                return 0
            else
                printf "${RED}✗ Failed to verify GitHub search dependencies${NC}\n"
                "$venv_python" -m pip install --force-reinstall colored requests >/dev/null 2>&1
                if "$venv_python" -c "import colored; import requests" 2>/dev/null; then
                    printf "${GREEN}✓ GitHub search dependencies fixed after reinstall${NC}\n"
                    return 0
                else
                    return 1
                fi
            fi
            ;;
        "crtsh")
            if ! "$venv_python" -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1; then
                printf "${RED}✗ Failed to upgrade pip${NC}\n"
            fi
            if ! "$venv_python" -m pip install --upgrade requests argparse >/dev/null 2>&1; then
                printf "${RED}✗ Failed to install dependencies${NC}\n"
                return 1
            fi
            # Verify
            if "$venv_python" -c "import requests; import argparse" 2>/dev/null; then
                printf "${GREEN}✓ Crtsh dependencies fixed${NC}\n"
                return 0
            else
                printf "${RED}✗ Failed to verify Crtsh dependencies${NC}\n"
                return 1
            fi
            ;;
        *)
            printf "${RED}Unknown tool: $tool_name${NC}\n"
            return 1
            ;;
    esac
}

print_section "Fixing Python Dependencies"

# Fix each tool
fix_venv_deps "Sublist3r"
fix_venv_deps "github-search"
fix_venv_deps "crtsh"

print_section "Verification"

# Verify all tools
printf "${YELLOW}Verifying installations...${NC}\n\n"

for tool in "Sublist3r" "github-search" "crtsh"; do
    venv_python="$TOOLS_DIR/$tool/venv/bin/python3"
    if [ -f "$venv_python" ]; then
        case "$tool" in
            "Sublist3r")
                if "$venv_python" -c "import dns.resolver; import requests" 2>/dev/null; then
                    printf "${GREEN}✓ $tool: OK${NC}\n"
                else
                    printf "${RED}✗ $tool: FAILED${NC}\n"
                fi
                ;;
            "github-search")
                if "$venv_python" -c "import colored; import requests" 2>/dev/null; then
                    printf "${GREEN}✓ $tool: OK${NC}\n"
                else
                    printf "${RED}✗ $tool: FAILED${NC}\n"
                fi
                ;;
            "crtsh")
                if "$venv_python" -c "import requests" 2>/dev/null; then
                    printf "${GREEN}✓ $tool: OK${NC}\n"
                else
                    printf "${RED}✗ $tool: FAILED${NC}\n"
                fi
                ;;
        esac
    else
        printf "${RED}✗ $tool: venv not found${NC}\n"
    fi
done

printf "\n${GREEN}Done!${NC}\n"

