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
  IP=$(lsec2 "$@" | fzf-tmux -m --reverse | awk -F '\t' '{print $2}')
  if [ "$IP" != "" ] ; then
    echo "$IP"
    ssh -i "$PUBKEY" "hajime-terasawa@$IP"
  fi
}

# ssh to multiple sc2 instances
xssh() {
IPS=$(lsec2 | fzf -m | awk -F "\t" '{print $2}')
if [[ $? == 0 && "${IPS}" != "" ]]; then
  echo "$IPS" | xpanes --ssh
fi
}

# fzf kill
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
    exists "kubens" && kubens
  fi
}
alias fe="eks-write-config"

# add a blank line after each output
add_line () {
  if [ -z "${PS1_NEWLINE_LOGIN}" ]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
PROMPT_COMMAND='add_line'

source ~/z/z.sh

# NOTE: need Menlo-for-Powerline
#   https://github.com/abertsch/Menlo-for-Powerline
# change prompt
source ~/.git-prompt.sh
source /usr/local/opt/kube-ps1/share/kube-ps1.sh
export PS1='\[\e[34m\][\t]\[\e[0m\]\[\e[35m\][jobs:\j]\[\e[0m\]\[\e[36m\][\w]\[\e[0m\]\[\e[30;47m\]\[\e[0m\] \[\e[30;47m\]$(__git_ps1 "\[\e[30m\][ %s]")\[\e[0m\]\n$(kube_ps1) \$ '
