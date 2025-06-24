# SubSprayer - Subdomain Enumeration Tool

A comprehensive subdomain enumeration tool that combines multiple techniques to discover subdomains of target domains.

## Features

- **Multiple Enumeration Techniques:**
  - Subfinder (passive DNS enumeration)
  - Sublist3r (OSINT-based enumeration)
  - Amass (comprehensive enumeration)
  - Crtsh (certificate transparency logs)
  - Gobuster (brute force DNS)
  - GitHub subdomain search

- **Live Host Detection:**
  - HTTPX for checking live hosts
  - Port scanning (80, 443, 8080, 8000, 8081, 8008, 8888, 8443, 9000, 9001, 9090)
  - Title and status code extraction

- **Cross-Platform Support:**
  - macOS (with Homebrew)
  - Linux (Debian/Ubuntu)
  - Linux (Arch)

## Installation

### macOS Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd subsprayer
   ```

2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

   The script will:
   - Install Homebrew (if not present)
   - Install all required system packages
   - Install Go programming language
   - Install all subdomain enumeration tools
   - Download wordlists
   - Set up PATH environment variables

3. **Restart your terminal or source the profile:**
   ```bash
   source ~/.zprofile
   ```

### Linux Installation

The same installation script works for Linux systems with apt (Debian/Ubuntu) or pacman (Arch) package managers.

## Usage

### Basic Usage

```bash
# Single domain enumeration
./subsprayer.sh -t example.com -w /path/to/wordlist.txt

# Multiple domains from file
./subsprayer.sh -l domains.txt -w /path/to/wordlist.txt

# With GitHub token for enhanced search
./subsprayer.sh -t example.com -w /path/to/wordlist.txt -g YOUR_GITHUB_TOKEN
```

### Parameters

- `-t`: Target domain (single domain)
- `-l`: List of domains (file containing domains)
- `-w`: Wordlist for brute force enumeration
- `-g`: GitHub token for enhanced subdomain search
- `-h`: Show help menu

### Examples

```bash
# Using the included wordlist
./subsprayer.sh -t apple.com -w $HOME/toolsSubsprayer/best-dns-wordlist.txt

# Multiple domains with GitHub token
./subsprayer.sh -l targets.txt -w $HOME/toolsSubsprayer/best-dns-wordlist.txt -g ghp_xxxxxxxxxxxxx
```

## Output Structure

Results are organized in the following structure:

```
resultSubsprayer/
└── domain.com/
    └── YYYY-MM-DD/
        ├── all-subdomains.txt      # Combined unique subdomains
        ├── live-hosts.txt          # Live hosts with HTTP details
        ├── domain-subfinder.txt    # Subfinder results
        ├── domain-sublist3r.txt    # Sublist3r results
        ├── domain-crtsh.txt        # Certificate transparency results
        ├── domain-gobuster.txt     # Brute force results (if wordlist provided)
        └── domain-github.txt       # GitHub search results (if token provided)
```

## Tools Installed

The installation script installs the following tools:

### Core Tools
- **Subfinder**: Fast passive subdomain enumeration
- **Sublist3r**: OSINT-based subdomain enumeration
- **Amass**: Comprehensive subdomain enumeration
- **Crtsh**: Certificate transparency log search
- **Gobuster**: DNS brute force tool
- **HTTPX**: HTTP probe tool for live host detection

### System Dependencies
- Go programming language
- Python 3 with required packages
- Git, curl, wget, jq, and other utilities

## GitHub Token Setup

For enhanced subdomain discovery, you can use a GitHub token:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with appropriate permissions
3. Use the token with the `-g` parameter

## Troubleshooting

### macOS Issues

1. **PATH not found errors:**
   ```bash
   source ~/.zprofile
   ```

2. **Homebrew not found:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Go binaries not found:**
   ```bash
   export PATH=$PATH:$HOME/go/bin
   ```

### Permission Issues

If you encounter permission issues, ensure the scripts are executable:

```bash
chmod +x install.sh
chmod +x subsprayer.sh
```

## Requirements

- macOS 10.15+ or Linux
- Internet connection for tool downloads
- Sufficient disk space (~500MB for tools and wordlists)

## Disclaimer

This tool is for educational and authorized security testing purposes only. Always ensure you have proper authorization before scanning any domain.

## License

This project is open source. Please check individual tool licenses for compliance.