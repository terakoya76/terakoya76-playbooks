# share history with each tab
share_history() {
  history -a
  history -c
  history -r
}
HISTFILE=~/.bash_history
HISTIGNORE=ls:history
PROMPT_COMMAND='share_history'
HISTSIZE=50000

# wrapper for history
export HISTCONTROL="ignoredups"
fzf_history() {
  READLINE_LINE=$(history | sed -e 's/^\s*[0-9]\+\s\+//' | awk '!a[$0]++' | fzf-tmux -m --reverse --query="$1")
  if [ -n "$READLINE_LINE" ] ; then
    echo "$READLINE_LINE" >&2
    eval "$READLINE_LINE"
    history -s "$READLINE_LINE"
  fi
}
alias fh="fzf_history"
