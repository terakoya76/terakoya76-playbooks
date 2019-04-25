PY2_VERSION="2.7.15"
PY3_VERSION="3.7.3"

pyenv global "$PY3_VERSION" "$PY2_VERSION"
export PATH="$HOME/.anyenv/envs/pyenv/shims/python2/:$PATH"
export PATH="$HOME/.anyenv/envs/pyenv/shims/python3/:$PATH"
