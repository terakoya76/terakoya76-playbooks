# Focus the herdr workspace for the current git repository, creating it on
# first use, then attach unless already inside herdr.
# workspace list does not expose cwd, so workspaces are matched by label
# (the repository directory name).
# HERDR_SESSION selects the session. It is passed as --session because inside
# a herdr pane HERDR_SOCKET_PATH would otherwise take precedence over it.
hw () {
  local root label id
  local -a session_args=()
  if [[ -n "${HERDR_SESSION}" ]]; then
    session_args=(--session "${HERDR_SESSION}")
  fi
  root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "hw: not inside a git repository" >&2
    return 1
  }
  label=$(basename "${root}")
  id=$(herdr "${session_args[@]}" workspace list | jq -r --arg l "${label}" \
    '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -n1)
  if [[ -n "${id}" ]]; then
    herdr "${session_args[@]}" workspace focus "${id}" >/dev/null || return 1
  else
    herdr "${session_args[@]}" workspace create --cwd "${root}" --label "${label}" --focus >/dev/null || return 1
  fi
  if [[ "${HERDR_ENV}" != "1" ]]; then
    herdr "${session_args[@]}"
  fi
}
