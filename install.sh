#!/bin/bash

# Check if $SUDO is available
if command -v sudo &> /dev/null
then
    SUDO=sudo
else
    SUDO=""
fi

# Create a function to print echo separators
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
  if command -v apt &> /dev/null
  then
    DEBIAN_FRONTEND=noninteractive $SUDO apt update
  elif command -v pacman &> /dev/null
  then
    $SUDO pacman -Syu --noconfirm
  else
    echo "Error: No compatible package manager found (apt or pacman)."
    exit 1
  fi
}

# Install system tools and packages
install_system_tools() {
  section "Installing Additional Packages"
  
  # Define an array of tools to install for Debian-based systems
  debian_tools=("git" "python3" "python3-pip" "python3-venv" "curl" "wget" "nano" "libcurl4-openssl-dev" "libxml2" "libxml2-dev" "libxslt1-dev" "ruby-dev" "build-essential" "libgmp-dev" "zlib1g-dev" "build-essential" "libssl-dev" "libffi-dev" "python-dev" "libldns-dev" "jq" "ruby-full" "python3-setuptools" "python3-dnspython" "rename" "findutils" "python3-pip" "python3-requests")

  # Define an array of tools to install for Arch-based systems
  arch_tools=("git" "python" "python-pip" "curl" "wget" "nano" "curl" "libxml2" "libxslt" "ruby" "base-devel" "gmp" "zlib" "openssl" "libffi" "python" "argparse" "ldns" "jq" "ruby" "python-setuptools" "python-dnspython" "perl-rename" "findutils" "python-pip" "python-requests")
  # Determine the package manager and install the appropriate tools
  if command -v apt &> /dev/null
  then
    for tool in "${debian_tools[@]}"; do
      echo "Installing $tool"
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y $tool || { echo "Installation of $tool failed"; exit 1; }
    done
  elif command -v pacman &> /dev/null
  then
    for tool in "${arch_tools[@]}"; do
      echo "Installing $tool"
      $SUDO pacman -S --noconfirm $tool || { echo "Installation of $tool failed"; exit 1; }
    done
  else
    echo "Error: No compatible package manager found (apt or pacman)."
    exit 1
  fi
}

# Install Golang
install_go() {
  #section "Installing Go..."
  if ! command -v /usr/local/go/bin/go; then
    # Extract the Go file name from the official website
    go_file=$(curl -s https://go.dev/dl/ | grep -o 'go[0-9]*.[0-9]*.[0-9]*.linux-amd64.tar.gz' | head -n 1)
    echo "Go file name: $go_file"

    # Download the Go file
    wget https://go.dev/dl/$go_file

    # Check if wget command was successful
    if [ $? -eq 0 ]; then
      echo "Go download successful"
    else
      echo "Go download failed"
      exit 1
    fi

    # Extract and install Go
    $SUDO tar -C /usr/local -xzf $go_file
    
    # Add Go to the PATH
    export PATH=$PATH:/usr/local/go/bin

    # Determine the user's shell
    current_shell=$(ps -p $$ -ocomm=)

    if [[ "$current_shell" == *"bash"* ]]; then
      # User is using bash
      echo "User is using bash"
      shellrc_file="$HOME/.bashrc"
    elif [[ "$current_shell" == *"zsh"* ]]; then
      # User is using zsh
      echo "User is using zsh"    
      shellrc_file="$HOME/.zshrc"
    else
      echo "Unknown shell. Unable to configure the environment. Please add Go to your PATH manually."
      return 1
    fi

    # Check if the export line is already present in the user's shell configuration file
    if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" "$shellrc_file"; then
      echo 'export PATH=$PATH:/usr/local/go/bin' >> "$shellrc_file"
      source $shellrc_file
    fi

    # Clean up the downloaded tar.gz file
    rm go*.linux-amd64.tar.gz
    echo "Go installed successfully!"
    go version
  else
    echo -e "${BLUE}Go is already installed${NC}"
    go version
  fi
}

# Install Sublist3r
install_sublist3r() {
  section "Sublist3r Installing"
  git clone https://github.com/aboul3la/Sublist3r.git $HOME/toolsSubsprayer/Sublist3r
  cd $HOME/toolsSubsprayer/Sublist3r || { echo "Error: Unable to change to Sublist3r directory."; exit 1; }
  python3 -m venv venv
  source venv/bin/activate
  pip3 install -r requirements.txt
  deactivate
  cd ../ || { echo "Error: Unable to return to the parent directory."; exit 1; }
}

install_httpx() {
  section "Installing httpx..."
  # Check if httpx is found in ~/go/bin/httpx
  if [ -x "$HOME/go/bin/httpx" ]; then
      echo -e "${BLUE}httpx is already installed in $HOME/go/bin${NC}"
      
      # If not found in /usr/local/bin, copy it there. So, that you are aware of what go tools you have installed
      if [ ! -x "/usr/local/bin/httpx" ]; then
          $SUDO cp "$HOME/go/bin/httpx" "/usr/local/bin/httpx"
          echo "httpx copied to /usr/local/bin"
      fi
  fi

  # Check if httpx is found in /usr/local/bin/httpx
  if [ -x "/usr/local/bin/httpx" ]; then
      echo -e "${BLUE}httpx is already installed in /usr/local/bin${NC}"
      
      # If not found in ~/go/bin, copy it there
      if [ ! -x "$HOME/go/bin/httpx" ]; then
          cp "/usr/local/bin/httpx" "$HOME/go/bin/httpx"
          echo "httpx copied to $HOME/go/bin"
      fi
  fi

  #If not installed in either location, install it
  if [ ! -x "$HOME/go/bin/httpx" ] && [ ! -x "/usr/local/bin/httpx" ]; then    
      if ! command -v httpx; then
          if error_message=$(go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>&1 >/dev/null); then
              $SUDO cp $HOME/go/bin/httpx /usr/local/bin
              echo "httpx installed successfully!"
              successful_tools+=("httpx")
          else
              echo -e "${RED}Failed to install httpx.${NC}"
              failed_tools+=("httpx: $error_message")
          fi
      else
          echo -e "${BLUE}httpx is already installed${NC}"
      fi
      
  fi
}

# Install gobuster
install_gobuster() {
  section "Installing gobuster..."

  #check if gobuster is found in /go/bin/gobuster
  if [ -x "$HOME/go/bin/gobuster" ]; then
      echo -e "${BLUE}gobuster is already installed in $HOME/go/bin${NC}"
      
      # If not found in /usr/local/bin, copy it there. So, that you are aware of what go tools you have installed
      if [ ! -x "/usr/local/bin/gobuster" ]; then
          $SUDO cp "$HOME/go/bin/gobuster" "/usr/local/bin/gobuster"
          echo "gobuster copied to /usr/local/bin"
      fi
  fi

  #check if gobuster is found in /usr/local/bin/gobuster
  if [ -x "/usr/local/bin/gobuster" ]; then
      echo -e "${BLUE}gobuster is already installed in /usr/local/bin${NC}"
      
      # If not found in ~/go/bin, copy it there
      if [ ! -x "$HOME/go/bin/gobuster" ]; then
          cp "/usr/local/bin/gobuster" "$HOME/go/bin/gobuster"
          echo "gobuster copied to $HOME/go/bin"
      fi
  fi

  #if not installed in either location, install it
  if [ ! -x "$HOME/go/bin/gobuster" ] && [ ! -x "/usr/local/bin/gobuster" ]; then
      if ! command -v gobuster; then
          if error_message=$(go install github.com/OJ/gobuster/v3@latest 2>&1 >/dev/null); then
              $SUDO cp $HOME/go/bin/gobuster /usr/local/bin
              echo "gobuster installed successfully!"
              successful_tools+=("gobuster")
          else
              echo -e "${RED}Failed to install gobuster.${NC}"
              failed_tools+=("gobuster: $error_message")
          fi
      else
          echo -e "${BLUE}gobuster is already installed${NC}"
      fi
  fi
}

# Install Github-Search
install_github_search() {
  section "Github-Search Installing"
  git clone https://github.com/gwen001/github-search.git $HOME/toolsSubsprayer/github-search
  cd $HOME/toolsSubsprayer/github-search
  python3 -m venv venv
  source venv/bin/activate
  pip3 install -r requirements.txt
  deactivate
  cd ../ || { echo "Error: Unable to return to the parent directory."; exit 1; }
}

install_subfinder() {
  section "Installing subfinder..."

  # Check if subfinder is found in ~/go/bin/subfinder
  if [ -x "$HOME/go/bin/subfinder" ]; then
      echo -e "${BLUE}subfinder is already installed in $HOME/go/bin${NC}"
      
      # If not found in /usr/local/bin, copy it there. So, that you are aware of what go tools you have installed
      if [ ! -x "/usr/local/bin/subfinder" ]; then
          $SUDO cp "$HOME/go/bin/subfinder" "/usr/local/bin/subfinder"
          echo "subfinder copied to /usr/local/bin"
      fi
  fi

  # Check if subfinder is found in /usr/local/bin/subfinder
  if [ -x "/usr/local/bin/subfinder" ]; then
      echo -e "${BLUE}subfinder is already installed in /usr/local/bin${NC}"
      
      # If not found in ~/go/bin, copy it there
      if [ ! -x "$HOME/go/bin/subfinder" ]; then
          cp "/usr/local/bin/subfinder" "$HOME/go/bin/subfinder"
          echo "subfinder copied to $HOME/go/bin"
      fi
  fi

  #If not installed in either location, install it
  if [ ! -x "$HOME/go/bin/subfinder" ] && [ ! -x "/usr/local/bin/subfinder" ]; then    
      if ! command -v subfinder; then
          if error_message=$(go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>&1 >/dev/null); then
              $SUDO cp $HOME/go/bin/subfinder /usr/local/bin
              echo "subfinder installed successfully!"
              successful_tools+=("subfinder")
          else
              echo -e "${RED}Failed to install subfinder.${NC}"
              failed_tools+=("subfinder: $error_message")
          fi
      else
          echo -e "${BLUE}subfinder is already installed${NC}"
      fi
      
  fi
}

install_amass() {
  section "Installing amass..."
  # Check if amass is found in ~/go/bin/amass
  if [ -x "$HOME/go/bin/amass" ]; then
      echo -e "${BLUE}amass is already installed in $HOME/go/bin${NC}"
      
      #If not found in /usr/local/bin, copy it there. So, that you are aware of what go tools you have installed
      if [ ! -x "/usr/local/bin/amass" ]; then
            $SUDO cp "$HOME/go/bin/amass" "/usr/local/bin/amass"
            echo "amass copied to /usr/local/bin"
      fi
  fi

  # Check if amass is found in /usr/local/bin/amass
  if [ -x "/usr/local/bin/amass" ]; then
      echo -e "${BLUE}amass is already installed in /usr/local/bin${NC}"
      
      #If not found in ~/go/bin, copy it there
      if [ ! -x "$HOME/go/bin/amass" ]; then
          cp "/usr/local/bin/amass" "$HOME/go/bin/amass"
          echo "amass copied to $HOME/go/bin"
      fi
  fi

  #If not installed in either location, install it
  if [ ! -x "$HOME/go/bin/amass" ] && [ ! -x "/usr/local/bin/amass" ]; then    
      if ! command -v amass; then
          if error_message=$(go install -v github.com/owasp-amass/amass/v4/...@master 2>&1 >/dev/null); then
              $SUDO cp $HOME/go/bin/amass /usr/local/bin
              echo "amass installed successfully!"
              successful_tools+=("amass")
          else
              echo -e "${RED}Failed to install amass.${NC}"
              failed_tools+=("amass: $error_message")
          fi
      else
          echo -e "${BLUE}amass is already installed${NC}"
      fi
      
  fi
}

# Install Knockpy
install_knockpy() {
  section "Knockpy Installing"
  git clone https://github.com/guelfoweb/knock.git $HOME/toolsSubsprayer/knock
  cd $HOME/toolsSubsprayer/knock
  python3 -m venv venv
  source venv/bin/activate
  pip3 install -r requirements.txt
  deactivate
  cd ../ || { echo "Error: Unable to return to the parent directory."; exit 1; }
}

# Install crtsh
install_crtsh() {
  section "Installing crtsh..."
  git clone https://github.com/YashGoti/crtsh.py.git $HOME/toolsSubsprayer/crtsh
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
install_knockpy
install_crtsh