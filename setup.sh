#!/bin/sh

set -eu

REPOSITORY_PATH="$HOME/terakoya76-playbooks"

if [ $# -gt 2 ]; then
  echo "you can only pass 0~1 args" 1>&2
  exit 1
fi

if ! which brew 2>&1 > /dev/null ;then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo 'Installed Homebrew'
fi

version=$(/usr/local/bin/ansible-playbook --version | head -n1 | awk '{print $2}' | cut -d '.' -f 1-2) # バージョンの上二桁を取得
if ! which /usr/local/bin/ansible-playbook 2>&1 > /dev/null || [[ `echo "$version >= 2.6" | bc` = 0 ]] ;then
  brew update
  brew install ansible
  echo 'Installed ansible'
fi

cd "$REPOSITORY_PATH"

if [ $# -eq 0 ]; then
  ansible-playbook playbooks/setup_macos.yml -i inventory/mac-local.yml
else
  case "$1" in
    -m)
      ansible-playbook playbooks/setup_macos_dotfiles.yml -i inventory/mac-local.yml ;;
    *)
      ansible-playbook playbooks/setup_macos.yml -i inventory/mac-local.yml ;;
  esac
fi
