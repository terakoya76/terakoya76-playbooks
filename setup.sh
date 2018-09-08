#!/bin/sh

set -eu

REPOSITORY_PATH="$HOME/ansible-playbooks"

if ! which brew 2>&1 > /dev/null ;then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo 'installed homebrew'
fi

version=$(/usr/local/bin/ansible-playbook --version | head -n1 | awk '{print $2}' | cut -d '.' -f 1-2) # バージョンの上二桁を取得
if ! which /usr/local/bin/ansible-playbook 2>&1 > /dev/null || [[ `echo "$version >= 2.6" | bc` = 0 ]] ;then
  brew update
  brew install ansible
  echo 'installed ansible'
fi

cd ~/terakoya76-playbooks
ansible-playbook playbooks/setup_macos.yml -i inventory/mac-local.yml
