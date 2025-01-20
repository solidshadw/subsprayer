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

# Create and change to the Tools directory
setup_tools_directory() {
  mkdir -p $HOME/toolsSubsprayer
  cd $HOME/toolsSubsprayer || { echo "Error: Unable to change to Tools directory."; exit 1; }
}

# Update repositories 
update_repos() {
  section "Updating Repos"
  if command -v apt &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive $SUDO apt update &>/dev/null
  elif command -v pacman &> /dev/null; then
    $SUDO pacman -Syu --noconfirm &>/dev/null
  else
    echo "Error: No compatible package manager found (apt or pacman)."
    exit 1
  fi
}

# Install system tools and packages
install_system_tools() {
  section "Installing Additional Packages"
  
  debian_tools=("git" "make" "python3" "python3-pip" "python3-venv" "curl" "wget" "nano" "libcurl4-openssl-dev" "libxml2" "libxml2-dev" "libxslt1-dev" "ruby-dev" "build-essential" "libgmp-dev" "zlib1g-dev" "libssl-dev" "libffi-dev" "python3-dev" "libldns-dev" "jq" "ruby-full" "python3-setuptools" "python3-dnspython" "rename" "findutils" "python3-requests")
  arch_tools=("git" "make" "python" "python-pip" "curl" "wget" "nano" "libxml2" "libxslt" "ruby" "base-devel" "gmp" "zlib" "openssl" "libffi" "argparse" "ldns" "jq" "python-setuptools" "python-dnspython" "perl-rename" "findutils" "python-requests")

  tools_to_install=()

  if command -v apt &> /dev/null; then
    for tool in "${debian_tools[@]}"; do
      if ! dpkg -l | grep -q "^ii  $tool "; then
        tools_to_install+=("$tool")
      else
        echo "$tool is already installed, skipping..."
      fi
    done
  elif command -v pacman &> /dev/null; then
    for tool in "${arch_tools[@]}"; do
      if ! pacman -Qq $tool &> /dev/null; then
        tools_to_install+=("$tool")
      else
        echo "$tool is already installed, skipping..."
      fi
    done
  else
    echo "Error: No compatible package manager found (apt or pacman)."
    exit 1
  fi

  if [ ${#tools_to_install[@]} -eq 0 ]; then
    echo "All tools are already installed, skipping bulk installation."
  else
    if command -v apt &> /dev/null; then
      echo "Installing Debian tools: ${tools_to_install[*]}"
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${tools_to_install[@]}" &>/dev/null || { echo "Installation of one or more tools failed"; exit 1; }
    elif command -v pacman &> /dev/null; then
      echo "Installing Arch tools: ${tools_to_install[*]}"
      $SUDO pacman -S --noconfirm "${tools_to_install[@]}" &>/dev/null || { echo "Installation of one or more tools failed"; exit 1; }
    fi
  fi
}

# Function to install Golang
install_go() {
  section "Installing Go"
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
    pip3 install -r requirements.txt &>/dev/null
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

      $SUDO cp "$HOME/go/bin/$tool_name" "/usr/local/bin/$tool_name"
      echo -e "${GREEN}$tool_name installed successfully${NC}"
    else
      echo -e "${RED}Failed to install $tool_name${NC}"
    fi
  else
    echo "$tool_name is already installed"
  fi
}

# Install various tools
install_sublist3r() { install_python_tool "Sublist3r" "https://github.com/aboul3la/Sublist3r.git"; }
install_httpx() { install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"; }
install_gobuster() { install_go_tool "gobuster" "github.com/OJ/gobuster/v3"; }
install_github_search() { install_python_tool "github-search" "https://github.com/gwen001/github-search.git"; }
install_subfinder() { install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"; }
install_amass() { install_go_tool "amass" "github.com/owasp-amass/amass/v4/..."@master; }

# Install crtsh
install_crtsh() {
  section "Installing crtsh"
  if [ ! -d "$HOME/toolsSubsprayer/crtsh" ]; then
    git clone https://github.com/YashGoti/crtsh.py.git "$HOME/toolsSubsprayer/crtsh" &>/dev/null
    echo -e "${GREEN}crtsh installed successfully${NC}"
  else
    echo "crtsh is already installed"
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

# Call all functions
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
