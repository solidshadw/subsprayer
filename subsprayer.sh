#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;96m'
YELLOW='\033[0;93m'
NC='\033[0m' # No Color

# Global variables
DATE=$(date +'%Y-%m-%d')
TOOLS_DIR="$HOME/toolsSubsprayer"

# Print formatted section headers
print_section() {
    printf "\n${BLUE}##################################################${NC}"
    printf "\n   ${BLUE}%s${NC} ${RED}%s${NC}" "$1" "$2"
    printf "\n${BLUE}##################################################${NC}\n\n"
}

# Error handling function
handle_error() {
    printf "\n${RED}Error: $1${NC}\n"
}

# Validate domain format
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}$ ]]; then
        handle_error "Invalid domain format: $domain"
    fi
}

# Create output directory structure
setup_output_dir() {
    local domain=$1
    local target="resultSubsprayer/$domain/$DATE"
    mkdir -p "$target" || handle_error "Could not create output directory"
}

# Run subfinder
run_subfinder() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Subfinder" "$domain"
    ~/go/bin/subfinder -d "$domain" -o "$output_dir/$domain-subfinder.txt" || \
        handle_error "Subfinder failed"
}

# Run sublist3r
run_sublist3r() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Sublist3r" "$domain"
    
    # Use venv python directly instead of activating
    local venv_python="$TOOLS_DIR/Sublist3r/venv/bin/python3"
    
    if [ ! -f "$venv_python" ]; then
        handle_error "Sublist3r venv not found. Please run install.sh first."
        return 1
    fi
    
    # Ensure dnspython is installed in venv
    "$venv_python" -c "import dns.resolver" 2>/dev/null || {
        printf "${YELLOW}Installing missing dependencies for Sublist3r...${NC}\n"
        "$venv_python" -m pip install -q dnspython requests argparse 2>/dev/null || true
    }
    
    "$venv_python" "$TOOLS_DIR/Sublist3r/sublist3r.py" -d "$domain" -v \
        -o "$output_dir/$domain-sublist3r.txt" || handle_error "Sublist3r failed"
}

# Run amass
run_amass() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Amass Passive Scan" "$domain"
    ~/go/bin/amass enum -norecursive -d "$domain" -o "$output_dir/$domain-amass-enum.txt" || handle_error "Amass enum failed"
    
    print_section "Amass Intel Scan" "$domain"
    ~/go/bin/amass intel -whois -d "$domain" -o "$output_dir/$domain-amass-intel.txt" || handle_error "Amass intel failed"
}

run_crtsh() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Crtsh" "$domain"
    
    # Use venv python directly
    local venv_python="$TOOLS_DIR/crtsh/venv/bin/python3"
    
    if [ ! -f "$venv_python" ]; then
        handle_error "Crtsh venv not found. Please run install.sh first."
        return 1
    fi
    
    "$venv_python" "$TOOLS_DIR/crtsh/crtsh.py" -d "$domain" | tee "$output_dir/$domain-crtsh.txt" || handle_error "Crtsh failed"
}

# Run gobuster
run_gobuster() {
    local domain=$1
    local wordlist=$2
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Gobuster" "$domain"
    ~/go/bin/gobuster dns --domain "$domain" -w "$wordlist" -t 30 -o "$output_dir/$domain-gobuster.txt" || handle_error "Gobuster failed"
}

# Run github subdomain search
run_github_search() {
    local domain=$1
    local token=$2
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Github Subdomain Search" "$domain"
    
    # Use venv python directly
    local venv_python="$TOOLS_DIR/github-search/venv/bin/python3"
    
    if [ ! -f "$venv_python" ]; then
        handle_error "GitHub search venv not found. Please run install.sh first."
        return 1
    fi
    
    # Ensure colored is installed in venv
    "$venv_python" -c "import colored" 2>/dev/null || {
        printf "${YELLOW}Installing missing dependencies for GitHub search...${NC}\n"
        "$venv_python" -m pip install -q colored requests dnspython argparse 2>/dev/null || true
    }
    
    # Add delay before GitHub search to avoid rate limiting
    # GitHub allows 30 requests per minute for authenticated users, 10 for unauthenticated
    # Adding a 5-10 second delay helps space out requests
    printf "${YELLOW}Waiting 5 seconds before GitHub search to avoid rate limiting...${NC}\n"
    sleep 5
    
    # Run GitHub search and capture output
    local temp_output=$(mktemp)
    local rate_limited=0
    
    if "$venv_python" "$TOOLS_DIR/github-search/github-subdomains.py" \
        -d "$domain" -t "$token" -v 2>&1 | tee "$temp_output"; then
        # Check if we got rate limited
        if grep -qi "rate limit\|403\|429" "$temp_output"; then
            rate_limited=1
            printf "\n${YELLOW}⚠ GitHub rate limit detected. Results may be incomplete.${NC}\n"
            printf "${YELLOW}   Tip: Wait a few minutes or use a token with higher rate limits.${NC}\n"
        fi
    else
        # Check for rate limit in error output
        if grep -qi "rate limit\|403\|429" "$temp_output"; then
            rate_limited=1
            printf "\n${RED}✗ GitHub rate limit exceeded!${NC}\n"
            printf "${YELLOW}   GitHub API allows 30 requests/minute for authenticated users.${NC}\n"
            printf "${YELLOW}   Please wait a few minutes before running again.${NC}\n"
            printf "${YELLOW}   Or use a GitHub token with higher rate limits.${NC}\n"
        else
            handle_error "Github search failed"
        fi
    fi
    
    # Save output if we got any results
    if [ -s "$temp_output" ] && ! grep -qi "rate limit exceeded" "$temp_output"; then
        grep -v "rate limit\|403\|429" "$temp_output" > "$output_dir/$domain-github.txt" 2>/dev/null || \
            cp "$temp_output" "$output_dir/$domain-github.txt"
    elif [ $rate_limited -eq 1 ]; then
        # Save partial results even if rate limited
        grep -v "rate limit exceeded\|403\|429" "$temp_output" > "$output_dir/$domain-github.txt" 2>/dev/null || true
        printf "${YELLOW}   Partial results saved to $output_dir/$domain-github.txt${NC}\n"
    fi
    
    rm -f "$temp_output"
}

# Process results
process_results() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    cd "$output_dir" || handle_error "Could not change to output directory"
    
    print_section "Processing Results" "$domain"
    
    # Combine and sort unique subdomains
    cat *.txt 2>/dev/null | sort -u | grep -i "$domain" > "all-subdomains.txt"
    
    # Check for live hosts
    print_section "Checking Live Hosts" "$domain"
    cat all-subdomains.txt | ~/go/bin/httpx -silent -fr -ports 80,443,3000,8080,8000,8081,8008,8888,8443,9000,9001,9090 \
        -title -status-code -fr -td -content-length -threads 100 | sort -u > "live-hosts.txt"
    awk '{print $1}' live-hosts.txt | sort -u > "live-hosts-clean.txt"
    
    cd - >/dev/null || handle_error "Could not return to previous directory"
}

# Display help menu
show_help() {
    printf "
[${GREEN}Usage${NC}]:

${RED}-h${NC}  =>  Help Menu
${RED}-t${NC}  =>  Target Domain
${RED}-l${NC}  =>  Domains List
${RED}-w${NC}  =>  Wordlist
${RED}-g${NC}  =>  Github Token
${RED}-u${NC}  =>  Update all Go tools

[${GREEN}Examples${NC}]:

${YELLOW}Single Domain:${NC}
./subsprayer.sh -t example.com -w /path/to/wordlist -g GITHUB_TOKEN

${YELLOW}Multiple Domains:${NC}
./subsprayer.sh -l domains.txt -w /path/to/wordlist -g GITHUB_TOKEN

${YELLOW}Update Tools:${NC}
./subsprayer.sh -u
or
./update_tools.sh
"
}

# Update Go tools
update_tools() {
    if [ -f "$(dirname "$0")/update_tools.sh" ]; then
        "$(dirname "$0")/update_tools.sh"
    else
        printf "${YELLOW}Running inline update...${NC}\n"
        # Inline update if script not found
        declare -A go_tools=(
            ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
            ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx"
            ["gobuster"]="github.com/OJ/gobuster/v3"
            ["amass"]="github.com/owasp-amass/amass/v4/..."
        )
        
        for tool in "${!go_tools[@]}"; do
            printf "${YELLOW}Updating $tool...${NC}\n"
            go install "${go_tools[$tool]}"@latest 2>&1 && \
                printf "${GREEN}✓ $tool updated${NC}\n" || \
                printf "${RED}✗ $tool update failed${NC}\n"
        done
    fi
    exit 0
}

# Main execution function
main() {
    local domain wordlist token domains_file
    
    # Parse command line arguments
    while getopts "h:t:l:w:g:u" opt; do
        case $opt in
            h) show_help; exit 0 ;;
            t) domain="$OPTARG" ;;
            l) domains_file="$OPTARG" ;;
            w) wordlist="$OPTARG" ;;
            g) token="$OPTARG" ;;
            u) update_tools ;;
            *) show_help; exit 1 ;;
        esac
    done
    
    # Validate inputs
    if [[ -z $domain && -z $domains_file ]]; then
        show_help
        exit 1
    fi
    
    # Process single domain
    if [[ -n $domain ]]; then
        validate_domain "$domain"
        setup_output_dir "$domain"
        run_subfinder "$domain" "$domain"
        run_sublist3r "$domain" "$domain"
        run_amass "$domain" "$domain"
        run_crtsh "$domain" "$domain"
        [[ -n $wordlist ]] && run_gobuster "$domain" "$wordlist" "$domain"
        # Run GitHub search last and with delay to minimize rate limiting
        if [[ -n $token ]]; then
            run_github_search "$domain" "$token" "$domain"
        fi
        process_results "$domain" "$domain"
    fi
    
    # Process domain list
    if [[ -n $domains_file ]]; then
        while IFS= read -r domain || [[ -n "$domain" ]]; do
            domain=$(echo "$domain" | tr -d '[:space:]')
            [[ -z $domain ]] && continue
            
            validate_domain "$domain"
            setup_output_dir "$domain"
            run_subfinder "$domain" "$domain"
            run_sublist3r "$domain" "$domain"
            run_amass "$domain" "$domain"
            run_crtsh "$domain" "$domain"
            [[ -n $wordlist ]] && run_gobuster "$domain" "$wordlist" "$domain"
            # Run GitHub search last and with delay to minimize rate limiting
            # Add extra delay between domains when processing a list
            if [[ -n $token ]]; then
                run_github_search "$domain" "$token" "$domain"
                # Add delay between domains to avoid rate limiting
                printf "${YELLOW}Waiting 10 seconds before next domain to avoid GitHub rate limits...${NC}\n"
                sleep 10
            fi
            process_results "$domain" "$domain"
        done < "$domains_file"
    fi
    
    printf "\n${GREEN}Subdomain enumeration completed successfully!${NC}\n"
}

# Execute main function
main "$@"
