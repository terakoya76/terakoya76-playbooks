#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
  echo "you must pass 1 args" 1>&2
  exit 1
fi

# setup ansible
case "$1" in
  mac)
    if ! which brew > /dev/null 2>&1 ;then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew install ansible ;;
  ubuntu)
    sudo apt-get update
    sudo apt-get install software-properties-common
    sudo apt-add-repository ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install ansible ;;
esac

# setup direnv
case "$1" in
  mac)
    brew install direnv ;;
  ubuntu)
    wget -O direnv https://github.com/direnv/direnv/releases/download/v2.6.0/direnv.linux-amd64
    chmod +x direnv
    sudo cp direnv /usr/local/bin/
    sudo rm direnv ;;
esac

REPOSITORY_PATH="$HOME/terakoya76-playbooks"
cd "$REPOSITORY_PATH"

case "$1" in
  dot)
    ansible-playbook playbooks/setup_dotfiles.yml -i inventory/mac-local.yml ;;
  mac)
    ansible-playbook playbooks/setup_mac.yml -i inventory/mac-local.yml ;;
  ubuntu)
    ansible-playbook playbooks/setup_ubuntu.yml -i inventory/ubuntu-local.yml ;;
esac
