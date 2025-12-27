#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;96m'
YELLOW='\033[0;93m'
NC='\033[0m' # No Color

# Print formatted section headers
print_section() {
    printf "\n${BLUE}##################################################${NC}"
    printf "\n   ${BLUE}%s${NC}" "$1"
    printf "\n${BLUE}##################################################${NC}\n\n"
}

# Update a Go tool
update_go_tool() {
    local tool_name=$1
    local repo_url=$2
    
    printf "${YELLOW}Updating $tool_name...${NC}\n"
    if go install "$repo_url"@latest 2>&1; then
        printf "${GREEN}✓ $tool_name updated successfully${NC}\n"
        return 0
    else
        printf "${RED}✗ Failed to update $tool_name${NC}\n"
        return 1
    fi
}

# Check if Go is installed
if ! command -v go &> /dev/null; then
    printf "${RED}Error: Go is not installed. Please run install.sh first.${NC}\n"
    exit 1
fi

print_section "Updating Go Tools"

# List of Go tools to update (using arrays for bash 3.2 compatibility)
go_tool_names=("subfinder" "httpx" "gobuster" "amass")
go_tool_repos=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/OJ/gobuster/v3"
    "github.com/owasp-amass/amass/v4/..."
)

# Update each tool
updated=0
failed=0

for i in "${!go_tool_names[@]}"; do
    tool_name="${go_tool_names[$i]}"
    repo_url="${go_tool_repos[$i]}"
    if update_go_tool "$tool_name" "$repo_url"; then
        updated=$((updated + 1))
    else
        failed=$((failed + 1))
    fi
done

# Summary
printf "\n${BLUE}##################################################${NC}\n"
printf "${GREEN}Updated: $updated tools${NC}\n"
if [ $failed -gt 0 ]; then
    printf "${RED}Failed: $failed tools${NC}\n"
fi
printf "${BLUE}##################################################${NC}\n\n"

# Show current versions
print_section "Current Tool Versions"

for tool_name in "${go_tool_names[@]}"; do
    if command -v "$tool_name" &> /dev/null; then
        version=$("$tool_name" -version 2>/dev/null || "$tool_name" version 2>/dev/null || echo "version unknown")
        printf "${GREEN}$tool_name:${NC} $version\n"
    else
        printf "${RED}$tool_name:${NC} not found\n"
    fi
done

printf "\n${GREEN}Update complete!${NC}\n"

