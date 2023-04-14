# enable z
. "$HOME/z/z.sh"

# exa(ls)
alias ls=exa
alias ll="ls -l"

# cat(bat)
export BAT_THEME="Github"
alias cat=bat

# wrapper for lsec2
# ssh to ec2 instance
lssh () {
  local ip=$(lsec2 "$@" | fzf-tmux -m --reverse | awk '{print $2}')
  if [ "$ip" != "" ] ; then
    echo "$ip"
    ssh "$ip"
  fi
}

# ssh to multiple sc2 instances
xssh() {
  local ips=$(lsec2 | fzf -m | awk -F "\t" '{print $2}')
  if [[ $? == 0 && "${ips}" != "" ]]; then
    echo "$ips" | xpanes --ssh
  fi
}

fzf-kill() {
  ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -15
}
alias fk="fzf-kill"

fzf-find() {
  local file=$(fd | fzf)
  if [[ "${file}" != '' ]]; then
    vim ${file}
  fi
}
alias ffd="fzf-find"

fzf-z-search() {
  local res=$(z | sort -rn | cut -c 12- | fzf)
  if [ -n "$res" ]; then
      BUFFER+="cd $res"
      zle accept-line
  else
      return 1
  fi
}
alias fz="fzf-z-search"

capture() {
  ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs -I{} sudo dtrace -p {} -qn '
    syscall::write*:entry
    /pid == $target && arg0 == 1/ {
        printf("%s", copyinstr(arg1, arg2));
    }
  '
}
