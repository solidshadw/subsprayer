# Subsprayer

Subsprayer is a tool for enumerating and brute forcing subdomains of a given domain.

## Requirements

Before running Subsprayer, you need to have the following:

- Python 3.6 or higher
- A file with a list of domains to target
- A Github token if using certain features

## Installation

To install Subsprayer, run the `install.sh` script:

```sh
chmod +x install.sh
./install.sh
```
This will install the required tools to run subsprayer. If it fails run it again.

## Usage

To use Subsprayer, run the `subsprayer.sh` script:

Here's a brief explanation of the options you can use with subsprayer.sh:

-h: Show the help menu
-t: Set the target domain
-l: Provide a list of domains
-w: Specify a wordlist
-d: Enable deep mode
-f: Enable fast mode
-g: Provide a Github token
-i: Ignore directory splitting

Make it executable if you would like:
```bash
chmod +x subsprayer.sh
```
Single Domain
```bash
./subsprayer.sh -t <SINGLE DOMAIN> -f true -g <GITHUB TOKEN>
```
List of Domains
```bash
./subsprayer.sh -l <LIST DOMAINs> -f true -g <GITHUB TOKEN>
```