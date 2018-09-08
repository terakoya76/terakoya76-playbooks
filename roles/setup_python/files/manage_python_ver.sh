PY2_VERSION="2.7.15"
PY3_VERSION="3.6.5"

pyenv global "$PY3_VERSION" "$PY2_VERSION"
export PATH="$HOME/.pyenv/versions/$PY3_VERSION/bin/:$PATH"
export PATH="$HOME/.pyenv/versions/$PY2_VERSION/bin/:$PATH"
