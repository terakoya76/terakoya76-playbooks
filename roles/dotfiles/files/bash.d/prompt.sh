# add a blank line after each output
add_line () {
  if [ -z "${PS1_NEWLINE_LOGIN}" ]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
PROMPT_COMMAND='add_line'

# bash-completions
source /usr/local/etc/bash_completion

# bash-completions
source /usr/local/etc/bash_completion

# NOTE: need Menlo-for-Powerline
#   https://github.com/abertsch/Menlo-for-Powerline
# change prompt
source "$HOME/.git-prompt.sh"

# kube-ps1
source "$HOME/kube-ps1/kube-ps1.sh"

export PS1='\[\e[34m\][\t]\[\e[0m\]\[\e[35m\][jobs:\j]\[\e[0m\]\[\e[36m\][\w]\[\e[0m\]\[\e[30;47m\]\[\e[0m\] \[\e[30;47m\]$(__git_ps1 "\[\e[30m\][ %s]")\[\e[0m\]\n$(kube_ps1) \$ '
