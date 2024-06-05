#!/usr/bin/env bash

# Apps to be installed via apt-get
debian_apps=(
	'zsh'
	'git'
	# 'neovim'
	# 'tmux' # sounds good 

	# CLI misc
	'bat' 		# Better cat
	# 'fzf' 	# rather use the git install	# Fuzzy file finder
	'ripgrep'  	# Searching within files
	# 'sd' 		# RegEx find and replace
	'tree' 	# Directory listings as tree sturcture
	# 'zoxide' 	# only after Ubuntu22, will use git clone
	'tldr'		# better man
	'fd-find'
	'dnsutils'

	# dev toolkits
	'openssl'

	# monitoring
	# 'btop' 	# Live system resource monitoring

	# random
	# 'neofetch'
)

# Colors
PURPLE='\033[0;35m'
YELLOW='\033[0;93m'
CYAN_B='\033[1;96m'
LIGHT='\x1b[2m'
RESET='\033[0m'

PROMPT_TIMEOUT=15 # When user is prompted for input, skip after x seconds

# If set to auto-yes - then don't wait for user reply
if [[ $* == *"--auto-yes"* ]]; then
  PROMPT_TIMEOUT=0
  REPLY='Y'
fi

# Print intro message
echo -e "Starting apt  package install & update script"

# Check if running as root, and prompt for password if not
if [ "$EUID" -ne 0 ]; then
  echo -e "${PURPLE}Elevated permissions are required to adjust system settings."
  echo -e "${CYAN_B}Please enter your password...${RESET}"
  sudo -v
  if [ $? -eq 1 ]; then
    echo -e "${YELLOW}Exiting, as not being run as sudo${RESET}"
    exit 1
  fi
fi

# Check apt-get actually installed
if ! hash apt 2> /dev/null; then
  echo "${YELLOW_B}apt doesn't seem to be present on your system. Exiting...${RESET}"
  exit 1
fi

# Enable upstream package repositories
echo -e "${CYAN_B}Would you like to enable listed repos? (y/N)${RESET}\n"
read -t $PROMPT_TIMEOUT -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if ! hash add-apt-repository 2> /dev/null; then
    sudo apt install --reinstall software-properties-common
  fi
  # If Ubuntu, add Ubuntu repos
  if lsb_release -a 2>/dev/null | grep -q 'Ubuntu'; then
    for repo in ${ubuntu_repos[@]}; do
      echo -e "${PURPLE}Enabling ${repo} repo...${RESET}"
      sudo add-apt-repository $repo
    done
  else
    # Otherwise, add Debian repos
    for repo in ${debian_repos[@]}; do
      echo -e "${PURPLE}Enabling ${repo} repo...${RESET}"
	sudo add-apt-repository $repo
    done
  fi
fi

# Prompt user to update package database
echo -e "${CYAN_B}Would you like to update package database? (y/N)${RESET}\n"
read -t $PROMPT_TIMEOUT -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${PURPLE}Updating database...${RESET}"
  sudo apt update
fi

# Prompt user to install all listed apps
echo -e "${CYAN_B}Would you like to install listed apps? (y/N)${RESET}\n"
read -t $PROMPT_TIMEOUT -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${PURPLE}Starting install...${RESET}"
  for app in ${debian_apps[@]}; do
    if hash "${app}" 2> /dev/null; then
      echo -e "${YELLOW}[Skipping]${LIGHT} ${app} is already installed${RESET}"
    elif hash flatpak 2> /dev/null && [[ ! -z $(echo $(flatpak list --columns=ref | grep $app)) ]]; then
      echo -e "${YELLOW}[Skipping]${LIGHT} ${app} is already installed via Flatpak${RESET}"
    else
      echo -e "${PURPLE}[Installing]${LIGHT} Downloading ${app}...${RESET}"
      sudo apt install ${app} --assume-yes
    fi
  done
fi

echo -e "${PURPLE}Installing from git.${RESET}"
echo -e "${PURPLE}Installing fzf.${RESET}"
if hash "zoxide" 2> /dev/null; then
	echo -e "${YELLOW} Zoxide is already installed"
else
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
fi

echo -e "${PURPLE}Intalling zoxide from git with install.sh"
if hash "zoxide" 2> /dev/null; then
	echo -e "${YELLOW} Zoxide is already installed"
else
	curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh  
	if [[ ":$PATH:" == *":${HOME}/.local/bin:"* ]]; then
		echo -e "${YELLOW}~/.local/bin is already added to path."
	else
		echo -e "${PURPLE}Adding ~/.local/bin to path"
		export PATH=$PATH:${HOME}/.local/bin/
	fi
fi

echo -e "${PURPLE}Installing oh-my-zsh."
if test -d ${HOME}/.oh-my-zsh; then
	echo -e "${YELLOW}Oh-my-zsh already installed."
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo -e "${PURPLE}Installing navi."
if hash "navi" 2> /dev/null; then
	echo -e "${YELLOW}Navi already installed."
else
	curl -sL https://raw.githubusercontent.com/denisidoro/navi/master/scripts/install
fi

echo -e "${PURPLE}Finished installing / updating Debian packages.${RESET}"
