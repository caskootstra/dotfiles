#!/usr/bin/env bash

set -e

# resolve shell-specifics
case "$(echo "$SHELL" | sed -E 's|/usr(/local)?||g')" in
    "/bin/zsh")
        RCPATH="$HOME/.zshrc"
        #SOURCE="${BASH_SOURCE[0]:-${(%):-%N}}"
    ;;
    *)
        RCPATH="$HOME/.bashrc"
        if [[ -f "$HOME/.bash_aliases" ]]; then
            RCPATH="$HOME/.bash_aliases"
        fi
        SOURCE="${BASH_SOURCE[0]}"
    ;;
esac

# get base dir regardless of execution location
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SOURCE=$([[ "$SOURCE" = /* ]] && echo "$SOURCE" || echo "$PWD/${SOURCE#./}")
basedir=$(dirname "$SOURCE")

# check curl
if ! [ -x "$(command -v curl)" ]; then
  output "* curl is required in order for this script to work."
  output "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

cd "$basedir"


# Always remove lib.sh, before downloading it
#rm -rf /tmp/lib.sh
#curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL"/"$GITHUB_SOURCE"/lib/lib.sh
# shellcheck source=lib/lib.sh
source "$basedir"/lib/lib.sh

# variables
GITHUB_USER="powercasgamer"
GITHUB_USERS=("$GITHUB_USER")


createtemp() {
    # Create a temp directory
    mkdir -p /tmp/dotfiles
    temp_dir=$(mktemp -d -t dotfiles-XXXXXXXXXX)
}

installzsh() {
    # Check if Zsh is already installed
    if [ -n "$(command -v zsh)" ]; then
        output "Zsh is already installed. Exiting."
        exit 0
    fi

    install_packages zsh

    # Install Oh My Zsh
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Change the default shell to Zsh
    echo "Changing default shell to Zsh..."
    chsh -s $(which zsh)

    # Adding my configs.
    cd "$temp_dir"
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    sh ./install.sh
    cd ..
    rm -rf fonts
    cd "$basedir"

    # copy "files/.dircolors to $HOME/.dircolors
    cp files/.dircolors "$HOME"/.dircolors
    cp files/.zshrc "$HOME"/.zshrc
    # add my ssh keys from github
    for user in "${GITHUB_USERS[@]}"; do
      curl -s https://github.com/"$user".keys >> "$HOME"/.ssh/authorized_keys
    done

    output "Zsh and Oh My Zsh installation completed. Please restart your terminal to apply changes."
}

installsdkman() {
  # Install SDKMAN
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk version
  output "SDKMAN installation completed."
}

install_zstd() {
    # Check if Zsh is already installed
    if [ -n "$(command -v zstd)" ]; then
        output "zstd is already installed. Exiting."
        exit 0
    fi

    install_packages zstd
}

exit() {
  # cleanup
  # delete the temp directory
  rm -rf "$temp_dir"
  unset RCPATH
  unset SOURCE
  unset basedir
}

# Install stuff
# Check the package manager
if [ -n "$(command -v apt-get)" ]; then
    # Ubuntu
    output "Detected Ubuntu. Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y git curl zip unzip sed
elif [ -n "$(command -v yum)" ]; then
    # CentOS
    output "Detected CentOS. Installing prerequisites..."
    sudo yum install -y git curl zip unzip sed
else
    output "Unsupported system. Please install prerequisites manually."
    exit 1
fi

output "hi"
success "hi"

# Create the temp dir
createtemp

# install zsh
installzsh
installsdkman
install_zstd

# exit
exit

