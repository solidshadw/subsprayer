#!/bin/bash

# Function to determine if sudo is available
get_sudo() {
  if command -v sudo &> /dev/null; then
    echo "sudo"
  else
    echo ""
  fi
}

SUDO=$(get_sudo)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print echo separators
section() { 
  printf "\n\n\e[92m+---------------------------------------------+\e[0m"
  printf "\n\e[92m|                                             |\e[0m"
  printf "\n\e[92m|   %s\e[0m" "$1"
  printf "\n\e[92m|                                             |\e[0m"
  printf "\n\e[92m+---------------------------------------------+\e[0m\n\n"
}

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif command -v apt &> /dev/null; then
    echo "debian"
  elif command -v pacman &> /dev/null; then
    echo "arch"
  else
    echo "unknown"
  fi
}

OS=$(detect_os)

# Install Homebrew if not present (macOS)
install_homebrew() {
  if [[ "$OS" == "macos" ]]; then
    if ! command -v brew &> /dev/null; then
      section "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Add Homebrew to PATH
      if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f "/usr/local/bin/brew" ]]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    else
      echo "Homebrew is already installed"
    fi
  fi
}

# Create and change to the Tools directory
setup_tools_directory() {
  mkdir -p $HOME/toolsSubsprayer
  cd $HOME/toolsSubsprayer || { echo "Error: Unable to change to Tools directory."; exit 1; }
}

# Update repositories 
update_repos() {
  section "Updating Repos"
  if [[ "$OS" == "macos" ]]; then
    brew update &>/dev/null
  elif command -v apt &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive $SUDO apt update &>/dev/null
  elif command -v pacman &> /dev/null; then
    $SUDO pacman -Syu --noconfirm &>/dev/null
  else
    echo "Error: No compatible package manager found."
    exit 1
  fi
}

# Install system tools and packages
install_system_tools() {
  section "Installing Additional Packages"
  
  if [[ "$OS" == "macos" ]]; then
    macos_tools=("git" "make" "python3" "curl" "wget" "jq" "ruby" "openssl" "libxml2" "libxslt" "gmp" "zlib" "findutils" "rename")
    
    for tool in "${macos_tools[@]}"; do
      if ! brew list $tool &> /dev/null; then
        echo "Installing $tool..."
        brew install $tool &>/dev/null || echo "Failed to install $tool"
      else
        echo "$tool is already installed, skipping..."
      fi
    done
    
    # Install Python packages via pip
    pip3 install dnspython requests &>/dev/null || echo "Failed to install some Python packages"
    
  elif command -v apt &> /dev/null; then
    debian_tools=("git" "make" "python3" "python3-pip" "python3-venv" "curl" "wget" "nano" "libcurl4-openssl-dev" "libxml2" "libxml2-dev" "libxslt1-dev" "ruby-dev" "build-essential" "libgmp-dev" "zlib1g-dev" "libssl-dev" "libffi-dev" "python3-dev" "libldns-dev" "jq" "ruby-full" "python3-setuptools" "python3-dnspython" "rename" "findutils" "python3-requests")
    
    tools_to_install=()
    for tool in "${debian_tools[@]}"; do
      if ! dpkg -l | grep -q "^ii  $tool "; then
        tools_to_install+=("$tool")
      else
        echo "$tool is already installed, skipping..."
      fi
    done
    
    if [ ${#tools_to_install[@]} -gt 0 ]; then
      echo "Installing Debian tools: ${tools_to_install[*]}"
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${tools_to_install[@]}" &>/dev/null || { echo "Installation of one or more tools failed"; exit 1; }
    fi
    
  elif command -v pacman &> /dev/null; then
    arch_tools=("git" "make" "python" "python-pip" "curl" "wget" "nano" "libxml2" "libxslt" "ruby" "base-devel" "gmp" "zlib" "openssl" "libffi" "argparse" "ldns" "jq" "python-setuptools" "python-dnspython" "perl-rename" "findutils" "python-requests")
    
    tools_to_install=()
    for tool in "${arch_tools[@]}"; do
      if ! pacman -Qq $tool &> /dev/null; then
        tools_to_install+=("$tool")
      else
        echo "$tool is already installed, skipping..."
      fi
    done
    
    if [ ${#tools_to_install[@]} -gt 0 ]; then
      echo "Installing Arch tools: ${tools_to_install[*]}"
      $SUDO pacman -S --noconfirm "${tools_to_install[@]}" &>/dev/null || { echo "Installation of one or more tools failed"; exit 1; }
    fi
  else
    echo "Error: No compatible package manager found."
    exit 1
  fi
}

# Function to install Golang
install_go() {
  section "Installing Go"
  
  if [[ "$OS" == "macos" ]]; then
    if ! command -v go &> /dev/null; then
      echo "Installing Go via Homebrew..."
      brew install go &>/dev/null
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}Go installed successfully${NC}"
        go version
      else
        echo -e "${RED}Go installation failed${NC}"
        exit 1
      fi
    else
      echo "Go is already installed"
      go version
    fi
  else
    # Linux installation (original code)
    if ! command -v /usr/local/go/bin/go &> /dev/null; then
      go_file=$(curl -s https://go.dev/dl/ | grep -o 'go[0-9]*.[0-9]*.[0-9]*.linux-amd64.tar.gz' | head -n 1)
      echo "Downloading $go_file"
      wget https://go.dev/dl/$go_file &>/dev/null

      if [ $? -eq 0 ]; then
        echo "Go download successful"
        $SUDO tar -C /usr/local -xzf $go_file &>/dev/null
        export PATH=$PATH:/usr/local/go/bin
        shellrc_file="$HOME/.${SHELL##*/}rc"

        if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" "$shellrc_file"; then
          echo 'export PATH=$PATH:/usr/local/go/bin' >> "$shellrc_file"
          source $shellrc_file
        fi
        rm $go_file
        echo -e "${GREEN}Go installed successfully${NC}"
        go version
      else
        echo -e "${RED}Go download failed${NC}"
        exit 1
      fi
    else
      echo "Go is already installed"
      go version
    fi
  fi
}

# Install Sublist3r
install_sublist3r() {
  section "Installing Sublist3r"
  if [ ! -d "$HOME/toolsSubsprayer/Sublist3r" ]; then
    git clone "https://github.com/aboul3la/Sublist3r.git" "$HOME/toolsSubsprayer/Sublist3r" &>/dev/null
    cd "$HOME/toolsSubsprayer/Sublist3r" || { echo "Error: Unable to change to Sublist3r directory."; exit 1; }
    python3 -m venv venv &>/dev/null
    # Use venv python directly
    venv_python="$HOME/toolsSubsprayer/Sublist3r/venv/bin/python3"
    if [ -f "requirements.txt" ]; then
      "$venv_python" -m pip install -q -r requirements.txt &>/dev/null
    fi
    # Install common dependencies that might be missing
    "$venv_python" -m pip install -q requests dnspython argparse &>/dev/null
    cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
    echo -e "${GREEN}Sublist3r installed successfully${NC}"
  else
    echo "Sublist3r is already installed"
    # Check if virtual environment exists and has required packages
    if [ -d "$HOME/toolsSubsprayer/Sublist3r/venv" ]; then
      venv_python="$HOME/toolsSubsprayer/Sublist3r/venv/bin/python3"
      if [ -f "$venv_python" ]; then
        "$venv_python" -c "import requests; import dns.resolver; import argparse" &>/dev/null
        if [ $? -ne 0 ]; then
          echo "Installing missing Python packages for Sublist3r..."
          "$venv_python" -m pip install -q requests dnspython argparse &>/dev/null
        fi
      else
        echo "Recreating Sublist3r venv..."
        cd "$HOME/toolsSubsprayer/Sublist3r" || { echo "Error: Unable to change to Sublist3r directory."; exit 1; }
        python3 -m venv venv &>/dev/null
        venv_python="$HOME/toolsSubsprayer/Sublist3r/venv/bin/python3"
        "$venv_python" -m pip install -q requests dnspython argparse &>/dev/null
        if [ -f "requirements.txt" ]; then
          "$venv_python" -m pip install -q -r requirements.txt &>/dev/null
        fi
        cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
      fi
    fi
  fi
}

# General function to clone a GitHub repository, set up a Python virtual environment, and install requirements
install_python_tool() {
  tool_name=$1
  repo_url=$2

  section "Installing $tool_name"
  if [ ! -d "$HOME/toolsSubsprayer/$tool_name" ]; then
    git clone "$repo_url" "$HOME/toolsSubsprayer/$tool_name" &>/dev/null
    cd "$HOME/toolsSubsprayer/$tool_name" || { echo "Error: Unable to change to $tool_name directory."; exit 1; }
    python3 -m venv venv &>/dev/null
    source venv/bin/activate
    if [ -f "requirements.txt" ]; then
      pip3 install -r requirements.txt &>/dev/null
    fi
    deactivate
    cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
    echo -e "${GREEN}$tool_name installed successfully${NC}"
  else
    echo "$tool_name is already installed"
  fi
}

# General function to install a Go tool
install_go_tool() {
  tool_name=$1
  repo_url=$2

  section "Installing $tool_name"
  if ! command -v "$tool_name" &> /dev/null; then
    if go install "$repo_url"@latest &>/dev/null; then
      # For macOS, the binary goes to $HOME/go/bin, ensure it's in PATH
      if [[ "$OS" == "macos" ]]; then
        # Add to PATH if not already there
        if ! echo "$PATH" | grep -q "$HOME/go/bin"; then
          echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zprofile
          export PATH=$PATH:$HOME/go/bin
        fi
      else
        $SUDO cp "$HOME/go/bin/$tool_name" "/usr/local/bin/$tool_name"
      fi
      echo -e "${GREEN}$tool_name installed successfully${NC}"
    else
      echo -e "${RED}Failed to install $tool_name${NC}"
    fi
  else
    echo "$tool_name is already installed"
  fi
}

# Install various tools
install_httpx() { install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"; }
install_gobuster() { install_go_tool "gobuster" "github.com/OJ/gobuster/v3"; }
install_github_search() {
  section "Installing github-search"
  if [ ! -d "$HOME/toolsSubsprayer/github-search" ]; then
    git clone "https://github.com/gwen001/github-search.git" "$HOME/toolsSubsprayer/github-search" &>/dev/null
    cd "$HOME/toolsSubsprayer/github-search" || { echo "Error: Unable to change to github-search directory."; exit 1; }
    python3 -m venv venv &>/dev/null
    # Use venv python directly
    venv_python="$HOME/toolsSubsprayer/github-search/venv/bin/python3"
    if [ -f "requirements.txt" ]; then
      "$venv_python" -m pip install -q -r requirements.txt &>/dev/null
    fi
    # Install common dependencies that might be missing
    "$venv_python" -m pip install -q requests dnspython argparse colored &>/dev/null
    cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
    echo -e "${GREEN}github-search installed successfully${NC}"
  else
    echo "github-search is already installed"
    # Check if virtual environment exists and has required packages
    if [ -d "$HOME/toolsSubsprayer/github-search/venv" ]; then
      venv_python="$HOME/toolsSubsprayer/github-search/venv/bin/python3"
      if [ -f "$venv_python" ]; then
        "$venv_python" -c "import requests; import colored; import argparse" &>/dev/null
        if [ $? -ne 0 ]; then
          echo "Installing missing Python packages for github-search..."
          "$venv_python" -m pip install -q requests dnspython argparse colored &>/dev/null
        fi
      else
        echo "Recreating github-search venv..."
        cd "$HOME/toolsSubsprayer/github-search" || { echo "Error: Unable to change to github-search directory."; exit 1; }
        python3 -m venv venv &>/dev/null
        venv_python="$HOME/toolsSubsprayer/github-search/venv/bin/python3"
        "$venv_python" -m pip install -q requests dnspython argparse colored &>/dev/null
        if [ -f "requirements.txt" ]; then
          "$venv_python" -m pip install -q -r requirements.txt &>/dev/null
        fi
        cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
      fi
    fi
  fi
}
install_subfinder() { install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"; }
install_amass() { install_go_tool "amass" "github.com/owasp-amass/amass/v4/..."@master; }

# Install crtsh
install_crtsh() {
  section "Installing crtsh"
  if [ ! -d "$HOME/toolsSubsprayer/crtsh" ]; then
    git clone https://github.com/YashGoti/crtsh.py.git "$HOME/toolsSubsprayer/crtsh" &>/dev/null
    cd "$HOME/toolsSubsprayer/crtsh" || { echo "Error: Unable to change to crtsh directory."; exit 1; }
    
    # Create virtual environment and install required packages
    python3 -m venv venv &>/dev/null
    venv_python="$HOME/toolsSubsprayer/crtsh/venv/bin/python3"
    "$venv_python" -m pip install -q requests argparse &>/dev/null
    
    cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
    echo -e "${GREEN}crtsh installed successfully${NC}"
  else
    echo "crtsh is already installed"
    # Check if virtual environment exists and has required packages
    if [ -d "$HOME/toolsSubsprayer/crtsh/venv" ]; then
      venv_python="$HOME/toolsSubsprayer/crtsh/venv/bin/python3"
      if [ -f "$venv_python" ]; then
        "$venv_python" -c "import requests, argparse" &>/dev/null
        if [ $? -ne 0 ]; then
          echo "Installing missing Python packages for crtsh..."
          "$venv_python" -m pip install -q requests argparse &>/dev/null
        fi
      else
        echo "Recreating crtsh venv..."
        cd "$HOME/toolsSubsprayer/crtsh" || { echo "Error: Unable to change to crtsh directory."; exit 1; }
        python3 -m venv venv &>/dev/null
        venv_python="$HOME/toolsSubsprayer/crtsh/venv/bin/python3"
        "$venv_python" -m pip install -q requests argparse &>/dev/null
        cd "$HOME/toolsSubsprayer" || { echo "Error: Unable to return to the parent directory."; exit 1; }
      fi
    fi
  fi
}

# Download wordlists
download_wordlists() {
  section "Downloading Assetnote DNS Wordlist"
  if [ ! -f "$HOME/toolsSubsprayer/best-dns-wordlist.txt" ]; then
    wget https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt -O $HOME/toolsSubsprayer/best-dns-wordlist.txt
    echo -e "${GREEN}best-dns-wordlist.txt downloaded successfully${NC}"
    echo "You can find it in $HOME/toolsSubsprayer/best-dns-wordlist.txt and use it as a wordlist"
  else
    echo "best-dns-wordlist.txt already exists"
  fi
}

# Setup PATH for macOS
setup_macos_path() {
  if [[ "$OS" == "macos" ]]; then
    section "Setting up PATH for macOS"
    
    # Ensure Go binaries are in PATH
    if ! echo "$PATH" | grep -q "$HOME/go/bin"; then
      echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zprofile
      export PATH=$PATH:$HOME/go/bin
      echo "Added $HOME/go/bin to PATH"
    fi
    
    # Source the profile to make changes take effect
    source ~/.zprofile
  fi
}

# Call all functions
install_homebrew
setup_tools_directory
update_repos
install_system_tools
install_go
install_sublist3r
install_httpx
install_amass
install_gobuster
install_github_search
install_subfinder
install_crtsh
download_wordlists
setup_macos_path

# Final instructions
section "Installation Complete"
echo -e "${GREEN}All tools have been installed successfully!${NC}"
echo ""
echo "To use the tools, you may need to restart your terminal or run:"
echo "source ~/.zprofile"
echo ""
echo "You can now run subsprayer.sh with:"
echo "./subsprayer.sh -t example.com -w $HOME/toolsSubsprayer/best-dns-wordlist.txt"
