#!/bin/bash

set -e

output() {
    echo -e '\e[34m'$1'\e[0m'
}

# check curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

createtemp() {
    # Create a temp directory
    mkdir -p /tmp/dotfiles
    temp_dir=$(mktemp -d -t dotfiles-XXXXXXXXXX)
    cd $temp_dir
}

installzsh() {
    # Check if Zsh is already installed
    if [ -n "$(command -v zsh)" ]; then
        echo "Zsh is already installed. Exiting."
        exit 0
    fi

    # Check the package manager
    if [ -n "$(command -v apt-get)" ]; then
        # Ubuntu
        echo "Detected Ubuntu. Installing Zsh..."
        sudo apt-get update
        sudo apt-get install -y zsh
    elif [ -n "$(command -v yum)" ]; then
        # CentOS
        echo "Detected CentOS. Installing Zsh..."
        sudo yum install -y zsh
    else
        echo "Unsupported system. Please install Zsh manually."
        exit 1
    fi

    # Install Oh My Zsh
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Change the default shell to Zsh
    echo "Changing default shell to Zsh..."
    chsh -s $(which zsh)

    # Adding my configs.
    cd $temp_dir
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    sh ./install.sh
    cd ..
    rm -rf fonts

    echo "Zsh and Oh My Zsh installation completed. Please restart your terminal to apply changes."
}

createtemp
zsh