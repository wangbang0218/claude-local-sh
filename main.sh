# shellcheck shell=zsh

# Claude Code provider switcher.
# Public commands:
#   cc-list
#   cc-current
#   cc-use <provider>
#   cc-reload

_CC_MAIN_FILE="${${(%):-%N}:A}"
_CC_MAIN_DIR="${_CC_MAIN_FILE:h}"

export CLAUDE_LOCAL_SH_HOME="${CLAUDE_LOCAL_SH_HOME:-$_CC_MAIN_DIR}"
export CLAUDE_CODE_PROVIDER_DIR="${CLAUDE_CODE_PROVIDER_DIR:-$CLAUDE_LOCAL_SH_HOME/providers}"
export CLAUDE_CODE_STATE_DIR="${CLAUDE_CODE_STATE_DIR:-$CLAUDE_LOCAL_SH_HOME/state}"
export CLAUDE_CODE_PROVIDER_FILE="${CLAUDE_CODE_PROVIDER_FILE:-$CLAUDE_CODE_STATE_DIR/current-provider}"

typeset -ga _CC_PROVIDER_NAMES
typeset -gA _CC_PROVIDER_BASE_URL
typeset -gA _CC_PROVIDER_AUTH_TOKEN
typeset -gA _CC_PROVIDER_MODEL
typeset -gA _CC_PROVIDER_OPUS_MODEL
typeset -gA _CC_PROVIDER_SONNET_MODEL
typeset -gA _CC_PROVIDER_HAIKU_MODEL
typeset -gA _CC_PROVIDER_SUBAGENT_MODEL
typeset -gA _CC_PROVIDER_EFFORT_LEVEL

function _cc_provider_exists() {
  local provider="$1"
  [[ -n "${_CC_PROVIDER_BASE_URL[$provider]}" || -n "${_CC_PROVIDER_AUTH_TOKEN[$provider]}" ]]
}

function cc_register_provider() {
  local provider="$1"

  if [[ -z "$provider" ]]; then
    echo "cc_register_provider requires a provider name." >&2
    return 2
  fi

  if ! _cc_provider_exists "$provider"; then
    _CC_PROVIDER_NAMES+=("$provider")
  fi

  _CC_PROVIDER_BASE_URL[$provider]="$2"
  _CC_PROVIDER_AUTH_TOKEN[$provider]="$3"
  _CC_PROVIDER_MODEL[$provider]="$4"
  _CC_PROVIDER_OPUS_MODEL[$provider]="$5"
  _CC_PROVIDER_SONNET_MODEL[$provider]="$6"
  _CC_PROVIDER_HAIKU_MODEL[$provider]="$7"
  _CC_PROVIDER_SUBAGENT_MODEL[$provider]="$8"
  _CC_PROVIDER_EFFORT_LEVEL[$provider]="$9"
}

function _cc_join_provider_names() {
  local separator="${1:- }"
  local joined=""
  local provider

  for provider in "${_CC_PROVIDER_NAMES[@]}"; do
    if [[ -z "$joined" ]]; then
      joined="$provider"
    else
      joined="$joined$separator$provider"
    fi
  done

  echo "$joined"
}

function _cc_load_provider_file() {
  local provider_file="$1"
  local provider="${provider_file:t:r}"
  local ANTHROPIC_BASE_URL=""
  local ANTHROPIC_AUTH_TOKEN=""
  local ANTHROPIC_MODEL=""
  local ANTHROPIC_DEFAULT_OPUS_MODEL=""
  local ANTHROPIC_DEFAULT_SONNET_MODEL=""
  local ANTHROPIC_DEFAULT_HAIKU_MODEL=""
  local CLAUDE_CODE_SUBAGENT_MODEL=""
  local CLAUDE_CODE_EFFORT_LEVEL=""

  source "$provider_file"

  cc_register_provider "$provider" \
    "$ANTHROPIC_BASE_URL" \
    "$ANTHROPIC_AUTH_TOKEN" \
    "$ANTHROPIC_MODEL" \
    "$ANTHROPIC_DEFAULT_OPUS_MODEL" \
    "$ANTHROPIC_DEFAULT_SONNET_MODEL" \
    "$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
    "$CLAUDE_CODE_SUBAGENT_MODEL" \
    "$CLAUDE_CODE_EFFORT_LEVEL"
}

function _cc_load_providers() {
  local provider_file

  _CC_PROVIDER_NAMES=()
  _CC_PROVIDER_BASE_URL=()
  _CC_PROVIDER_AUTH_TOKEN=()
  _CC_PROVIDER_MODEL=()
  _CC_PROVIDER_OPUS_MODEL=()
  _CC_PROVIDER_SONNET_MODEL=()
  _CC_PROVIDER_HAIKU_MODEL=()
  _CC_PROVIDER_SUBAGENT_MODEL=()
  _CC_PROVIDER_EFFORT_LEVEL=()

  if [[ ! -d "$CLAUDE_CODE_PROVIDER_DIR" ]]; then
    return 0
  fi

  for provider_file in "$CLAUDE_CODE_PROVIDER_DIR"/*.zsh(N); do
    _cc_load_provider_file "$provider_file"
  done
}

function _cc_set_optional_env() {
  local name="$1"
  local value="$2"

  if [[ -n "$value" ]]; then
    export "$name=$value"
  else
    unset "$name"
  fi
}

function _cc_export_provider() {
  local provider="$1"

  if ! _cc_provider_exists "$provider"; then
    echo "Unknown Claude Code provider: $provider" >&2
    echo "Available providers: $(_cc_join_provider_names)" >&2
    return 1
  fi

  if [[ -z "${_CC_PROVIDER_BASE_URL[$provider]}" || -z "${_CC_PROVIDER_AUTH_TOKEN[$provider]}" ]]; then
    echo "Claude Code provider '$provider' is not configured yet." >&2
    echo "Please fill its ANTHROPIC_BASE_URL and ANTHROPIC_AUTH_TOKEN in $CLAUDE_CODE_PROVIDER_DIR/$provider.zsh first." >&2
    return 1
  fi

  export CLAUDE_CODE_PROVIDER="$provider"
  export ANTHROPIC_BASE_URL="${_CC_PROVIDER_BASE_URL[$provider]}"
  export ANTHROPIC_AUTH_TOKEN="${_CC_PROVIDER_AUTH_TOKEN[$provider]}"
  unset ANTHROPIC_API_KEY

  _cc_set_optional_env ANTHROPIC_MODEL "${_CC_PROVIDER_MODEL[$provider]}"
  _cc_set_optional_env ANTHROPIC_DEFAULT_OPUS_MODEL "${_CC_PROVIDER_OPUS_MODEL[$provider]}"
  _cc_set_optional_env ANTHROPIC_DEFAULT_SONNET_MODEL "${_CC_PROVIDER_SONNET_MODEL[$provider]}"
  _cc_set_optional_env ANTHROPIC_DEFAULT_HAIKU_MODEL "${_CC_PROVIDER_HAIKU_MODEL[$provider]}"
  _cc_set_optional_env CLAUDE_CODE_SUBAGENT_MODEL "${_CC_PROVIDER_SUBAGENT_MODEL[$provider]}"
  _cc_set_optional_env CLAUDE_CODE_EFFORT_LEVEL "${_CC_PROVIDER_EFFORT_LEVEL[$provider]}"
}

function cc-use() {
  local provider="$1"

  if [[ -z "$provider" ]]; then
    echo "Usage: cc-use <provider>" >&2
    echo "Available providers: $(_cc_join_provider_names)" >&2
    return 2
  fi

  if ! _cc_export_provider "$provider"; then
    return 1
  fi

  mkdir -p "$CLAUDE_CODE_STATE_DIR"
  printf "%s\n" "$provider" > "$CLAUDE_CODE_PROVIDER_FILE"
  echo "Claude Code provider switched to: $provider"
}

function cc-current() {
  echo "CLAUDE_CODE_PROVIDER=${CLAUDE_CODE_PROVIDER:-unknown}"
  echo "ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-unset}"
  echo "ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-unset}"
  echo "ANTHROPIC_DEFAULT_OPUS_MODEL=${ANTHROPIC_DEFAULT_OPUS_MODEL:-unset}"
  echo "ANTHROPIC_DEFAULT_SONNET_MODEL=${ANTHROPIC_DEFAULT_SONNET_MODEL:-unset}"
  echo "ANTHROPIC_DEFAULT_HAIKU_MODEL=${ANTHROPIC_DEFAULT_HAIKU_MODEL:-unset}"
  echo "CLAUDE_CODE_SUBAGENT_MODEL=${CLAUDE_CODE_SUBAGENT_MODEL:-unset}"
  echo "CLAUDE_CODE_EFFORT_LEVEL=${CLAUDE_CODE_EFFORT_LEVEL:-unset}"

  if [[ -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
    echo "ANTHROPIC_AUTH_TOKEN=***"
  else
    echo "ANTHROPIC_AUTH_TOKEN=unset"
  fi
}

function cc-list() {
  local provider

  for provider in "${_CC_PROVIDER_NAMES[@]}"; do
    echo "$provider"
  done
}

function cc-reload() {
  local provider="${CLAUDE_CODE_PROVIDER:-}"

  _cc_load_providers

  if [[ -n "$provider" ]]; then
    _cc_export_provider "$provider" >/dev/null
  fi
}

_cc_load_providers
_cc_selected_provider="$(cat "$CLAUDE_CODE_PROVIDER_FILE" 2>/dev/null)"
_cc_selected_provider="${_cc_selected_provider:-${_CC_PROVIDER_NAMES[1]}}"

if [[ -n "$_cc_selected_provider" ]]; then
  _cc_export_provider "$_cc_selected_provider" >/dev/null
fi

unset _cc_selected_provider
