# tmux adapt utf8
alias tmux="tmux -u"

# exa(ls)
alias ls=exa

# fdfind(fd)
alias fd=fdfind

# cat(bat)
export BAT_THEME="Github"
alias cat=bat

# wrapper for lsec2
lssh () {
  IP=$(lsec2 "$@" | fzf-tmux -m --reverse | awk -F '\t' '{print $2}')
  if [ "$IP" != "" ] ; then
    echo "$IP"
    ssh -i "$PUBKEY" "hajime-terasawa@$IP"
  fi
}

# fzf kill
function fzf-kill() {
  ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -15
}
alias fk="fzf-kill"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
function fe() {
  file=$(fzf --query="$1" --select-1 --exit-0)
  if [ -f "$file" ] ; then
    nvim "$file"
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
