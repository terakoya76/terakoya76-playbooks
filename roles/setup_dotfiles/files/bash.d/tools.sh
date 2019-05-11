# tmux adapt utf8
alias tmux="tmux -u"

# exa(ls)
alias ls=exa

# fdfind(fd)
alias fd=fdfind

# cat(bat)
export BAT_THEME="iceberg"
alias cat=bat

# wrapper for lsec2
lssh () {
  IP=$(lsec2 "$@" | fzf-tmux -m --reverse | awk -F '\t' '{print $2}')
  if [ "$IP" != "" ] ; then
    echo "$IP"
    ssh -i "$PUBKEY" "hajime-terasawa@$IP"
  fi
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

# NOTE: need Menlo-for-Powerline
#   https://github.com/abertsch/Menlo-for-Powerline
# change prompt
source ~/.git-prompt.sh
export PS1='\[\e[34m\][\t]\[\e[0m\]\[\e[35m\][jobs:\j]\[\e[0m\]\[\e[36m\][\w]\[\e[0m\]\n\[\e[30;47m\] \W \[\e[0m\] \[\e[30;47m\]$(__git_ps1 "\[\e[30m\][ %s]")\[\e[0m\] \$ '
