# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# Load bash flagment
if [ -d "${HOME}/.bash.d" ] ; then
    for f in "${HOME}"/.bash.d/*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Load local env file
if [ -f ~/.env ]; then
	. ~/.env
fi

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH
