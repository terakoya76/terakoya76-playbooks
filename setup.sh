#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
  echo "you must pass 1 args" 1>&2
  exit 1
fi

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
