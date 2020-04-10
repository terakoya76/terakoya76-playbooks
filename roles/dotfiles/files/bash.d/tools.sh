# tmux adapt utf8
alias tmux="tmux -u"

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

eks-write-config() {
  local cluster=$(eksctl get cluster | fzf | awk '{print $1}')
  if [[ $cluster != '' ]]; then
    eksctl utils write-kubeconfig --name "${cluster}"
  fi
}
alias fe="eks-write-config"

capture() {
  ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs -I{} sudo dtrace -p {} -qn '
    syscall::write*:entry
    /pid == $target && arg0 == 1/ {
        printf("%s", copyinstr(arg1, arg2));
    }
  '
}

# add a blank line after each output
add_line () {
  if [ -z "${PS1_NEWLINE_LOGIN}" ]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
PROMPT_COMMAND='add_line'

. "$HOME/z/z.sh"

# bash-completions
. /usr/local/etc/bash_completion
. <(kubectl completion bash)
complete -o default -F __start_kubectl k

# NOTE: need Menlo-for-Powerline
#   https://github.com/abertsch/Menlo-for-Powerline
# change prompt
. "$HOME/.git-prompt.sh"
. /usr/local/opt/kube-ps1/share/kube-ps1.sh
export PS1='\[\e[34m\][\t]\[\e[0m\]\[\e[35m\][jobs:\j]\[\e[0m\]\[\e[36m\][\w]\[\e[0m\]\[\e[30;47m\]\[\e[0m\] \[\e[30;47m\]$(__git_ps1 "\[\e[30m\][ %s]")\[\e[0m\]\n$(kube_ps1) \$ '
