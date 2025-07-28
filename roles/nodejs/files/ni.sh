# yarn
export PATH="$HOME/.yarn/bin:$PATH"
# yarn end

# pnpm
export PNPM_HOME="/home/terakoya76/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
