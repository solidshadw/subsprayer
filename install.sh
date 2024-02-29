#!/bin/bash

# Create a function to print section separators
section() {
  printf "\n\n\e[92m=============================================\e[0m"
  printf "\n\n\e[92m%s\e[0m" "$1"
  printf "\n\n\e[92m=============================================\e[0m\n\n"
}

# Create and change to the Tools directory
mkdir -p Tools
cd Tools || { echo "Error: Unable to change to Tools directory."; exit 1; }

# Update repositories
section "Updating Repos"
sudo apt update

# Define an array of tools to install
tools=("git" "python3" "python3-pip" "python2")

# Iterate over the array and install each tool
for tool in "${tools[@]}"; do
    echo "Installing $tool"
    sudo apt-get install -y $tool || { echo "Installation of $tool failed"; exit 1; }
done

# Install Golang
section "Installing Golang"
sudo apt -y install golang

# Install additional packages
section "Installing Additional Packages"
sudo apt -y install libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev build-essential libgmp-dev zlib1g-dev build-essential libssl-dev libffi-dev python-dev libldns-dev jq ruby-full python3-setuptools python3-dnspython rename findutils

# Install Sublist3r
section "Sublist3r Installing"
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r/ || { echo "Error: Unable to change to Sublist3r directory."; exit 1; }
pip3 install -r requirements.txt
cd ../ || { echo "Error: Unable to return to the parent directory."; exit 1; }

# Install httpx in golang
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# Install other tools
sudo apt -y install amass subfinder gobuster
pip3 install requests
pip3 install dnspython
pip3 install argparse 

# Install httpx in golang
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
mv /root/go/bin/httpx /usr/bin/

# Install Github-Search
section "Github-Search Installing"
git clone https://github.com/gwen001/github-search.git
cd github-search
pip3 install -r requirements.txt
cd ../ || { echo "Error: Unable to return to the parent directory."; exit 1; }

# Install Knockpy
section "Knockpy Installing"
git clone https://github.com/guelfoweb/knock.git
cd knock
pip3 install -r requirements.txt
cd ../ || { echo "Error: Unable to return to the parent directory.";


# Install crtsh
git clone https://github.com/YashGoti/crtsh.py.git crtsh

