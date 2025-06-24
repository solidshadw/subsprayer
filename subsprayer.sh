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
    source "$TOOLS_DIR/Sublist3r/venv/bin/activate"
    python3 "$TOOLS_DIR/Sublist3r/sublist3r.py" -d "$domain" -v \
        -o "$output_dir/$domain-sublist3r.txt" || handle_error "Sublist3r failed"
    deactivate
}

# Run amass
run_amass() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Amass Passive Scan" "$domain"
    ~/go/bin/amass enum -passive -norecursive -d "$domain" -o "$output_dir/$domain-amass-enum.txt" || handle_error "Amass enum failed"
    
    print_section "Amass Intel Scan" "$domain"
    ~/go/bin/amass intel -whois -d "$domain" -o "$output_dir/$domain-amass-intel.txt" || handle_error "Amass intel failed"
}

run_crtsh() {
    local domain=$1
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Crtsh" "$domain"
    source "$TOOLS_DIR/crtsh/venv/bin/activate"
    python3 "$TOOLS_DIR/crtsh/crtsh.py" -d "$domain" | tee "$output_dir/$domain-crtsh.txt" || handle_error "Crtsh failed"
    deactivate
}

# Run gobuster
run_gobuster() {
    local domain=$1
    local wordlist=$2
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Gobuster" "$domain"
    ~/go/bin/gobuster dns -d "$domain" -w "$wordlist" -t 30 -o "$output_dir/$domain-gobuster.txt" || handle_error "Gobuster failed"
}

# Run github subdomain search
run_github_search() {
    local domain=$1
    local token=$2
    local output_dir="resultSubsprayer/$domain/$DATE"
    
    print_section "Github Subdomain Search" "$domain"
    source "$TOOLS_DIR/github-search/venv/bin/activate"
    python3 "$TOOLS_DIR/github-search/github-subdomains.py" \
        -d "$domain" -t "$token" -v | tee "$output_dir/$domain-github.txt" || \
        handle_error "Github search failed"
    deactivate
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
    cat all-subdomains.txt | ~/go/bin/httpx -silent -fr -ports 80,443,8080,8000,8081,8008,8888,8443,9000,9001,9090 \
        -title -status-code -content-length -nc -threads 100 | sort -u > "live-hosts.txt"
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

[${GREEN}Examples${NC}]:

${YELLOW}Single Domain:${NC}
./subsprayer.sh -t example.com -w /path/to/wordlist -g GITHUB_TOKEN

${YELLOW}Multiple Domains:${NC}
./subsprayer.sh -l domains.txt -w /path/to/wordlist -g GITHUB_TOKEN
"
}

# Main execution function
main() {
    local domain wordlist token domains_file
    
    # Parse command line arguments
    while getopts "h:t:l:w:g:" opt; do
        case $opt in
            h) show_help; exit 0 ;;
            t) domain="$OPTARG" ;;
            l) domains_file="$OPTARG" ;;
            w) wordlist="$OPTARG" ;;
            g) token="$OPTARG" ;;
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
        #run_amass "$domain" "$domain"
        run_crtsh "$domain" "$domain"
        [[ -n $wordlist ]] && run_gobuster "$domain" "$wordlist" "$domain"
        [[ -n $token ]] && run_github_search "$domain" "$token" "$domain"
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
            #run_amass "$domain" "$domain"
            run_crtsh "$domain" "$domain"
            [[ -n $wordlist ]] && run_gobuster "$domain" "$wordlist" "$domain"
            [[ -n $token ]] && run_github_search "$domain" "$token" "$domain"
            process_results "$domain" "$domain"
        done < "$domains_file"
    fi
    
    printf "\n${GREEN}Subdomain enumeration completed successfully!${NC}\n"
}

# Execute main function
main "$@"
