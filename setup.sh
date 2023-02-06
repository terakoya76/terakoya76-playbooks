#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
  echo "you must pass 1 args" 1>&2
  exit 1
fi

# setup ansible
dist=$(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"')
if [ ${dist} = "Ubuntu" ]; then
  sudo apt update
  sudo apt install -y software-properties-common git ansible
elif [ ${dist} ]
case "${dist}" in
  mac)
    if ! brew -v > /dev/null 2>&1 ; then
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    if ! which ansible > /dev/null 2>&1 ; then
      brew install ansible
    fi;;
  ubuntu)
esac

REPOSITORY_PATH="$HOME/terakoya76-playbooks"
rm -fr "$REPOSITORY_PATH"
git clone git@github.com:terakoya76/terakoya76-playbooks.git
cd "$REPOSITORY_PATH"

ansible-playbook -i inventories/all.yml playbooks/development.yml
