#!/bin/sh
set -eu

if ! which brew > /dev/null 2>&1 ;then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo 'Installed Homebrew'
fi

version=$(/usr/local/bin/ansible-playbook --version | head -n1 | awk '{print $2}' | cut -d '.' -f 1-2) # バージョンの上二桁を取得
if ! which /usr/local/bin/ansible-playbook > /dev/null 2>&1 || [ $(echo "$version >= 2.6" | bc) = 0 ] ;then
  brew update
  brew install ansible
  echo 'Installed ansible'
fi
