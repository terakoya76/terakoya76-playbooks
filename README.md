# terakoya76-playbooks

Setup develop environment w/ ansible

### Install/Update

For MacOS

```shell
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) mac
```

For Ubuntu

```shell
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) ubuntu
```

### Apply Dotfiles

```shell
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) dot
```

### When failed
use `--start-at-task` opt
```bash
$ ansible-playbook playbooks/setup_ubuntu.yml -i inventory/ubuntu-local.yml --start-at-task="ruby : Set prefix"
```
