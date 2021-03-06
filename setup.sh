#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
  echo "you must pass 1 args" 1>&2
  exit 1
fi

# setup ansible
case "$1" in
  mac)
    if ! brew -v > /dev/null 2>&1 ; then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    if ! which ansible > /dev/null 2>&1 ; then
      brew install ansible
    fi;;
  ubuntu)
    sudo apt update
    sudo apt install -y software-properties-common git ansible ;;
esac

# setup direnv
case "$1" in
  mac)
    if ! which direnv > /dev/null 2>&1 ; then
      brew install direnv
    fi;;
  ubuntu)
    wget -O direnv https://github.com/direnv/direnv/releases/download/v2.6.0/direnv.linux-amd64
    chmod +x direnv
    sudo cp direnv /usr/local/bin/
    sudo rm direnv ;;
esac

REPOSITORY_PATH="$HOME/terakoya76-playbooks"
rm -fr "$REPOSITORY_PATH"
git clone git@github.com:terakoya76/terakoya76-playbooks.git
cd "$REPOSITORY_PATH"

case "$1" in
  dot)
    ansible-playbook playbooks/setup_dotfiles.yml -i inventory/mac-local.yml ;;
  mac)
    ansible-playbook playbooks/setup_mac.yml -i inventory/mac-local.yml ;;
  ubuntu)
    ansible-playbook playbooks/setup_ubuntu.yml -i inventory/ubuntu-local.yml ;;
esac
