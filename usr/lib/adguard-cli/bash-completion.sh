# adguard-cli bash completion script

_adguard_cli_common_opts="--help --help-all"
_adguard_cli_opts="configure cert activate reset-license start stop restart status license config check-update update filters dns userscripts export-logs export-settings import-settings speed install-browser-integration --version"

_adguard_cli_start() {
  local opts="--no-fork --ppid-file --pid-file --log-to-file ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_config() {
  local opts=" show set get list-add list-remove reset ${_adguard_cli_common_opts}"
  local subcmd_opts=""

  case "${COMP_WORDS[2]}" in
    reset)
      subcmd_opts="--all ${_adguard_cli_common_opts}"
      ;;
    show|list-add|list-remove)
      subcmd_opts="--list-file ${_adguard_cli_common_opts}"
      ;;
  esac

  if [[ -n "$subcmd_opts" ]]; then
    COMPREPLY=($(compgen -W "${subcmd_opts}" -- "$cur"))
  else
    COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
  fi
}

_adguard_cli_filters() {
  local opts="list add install remove enable disable update set-title set-trusted ${_adguard_cli_common_opts}"
  local subcmd_opts=""

  case "${COMP_WORDS[2]}" in
      list)
        subcmd_opts="--all ${_adguard_cli_common_opts}"
        ;;
      install)
        subcmd_opts="--title --trusted ${_adguard_cli_common_opts}"
        ;;
    esac

  if [[ -n "$subcmd_opts" ]]; then
    COMPREPLY=($(compgen -W "${subcmd_opts}" -- "$cur"))
  else
    COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
  fi
}

_adguard_cli_dns() {
  local opts="filters ${_adguard_cli_common_opts}"
  local subcmd_opts=""
  local filter_opts="list add install remove enable disable set-title ${_adguard_cli_common_opts}"

  # Check if we're at dns level or dns filters level
  if [[ "${COMP_WORDS[2]}" == "filters" ]]; then
    case "${COMP_WORDS[3]}" in
      list)
        subcmd_opts="--all ${_adguard_cli_common_opts}"
        ;;
      install)
        subcmd_opts="--title ${_adguard_cli_common_opts}"
        ;;
    esac

    if [[ -n "$subcmd_opts" ]]; then
      COMPREPLY=($(compgen -W "${subcmd_opts}" -- "$cur"))
    else
      COMPREPLY=($(compgen -W "${filter_opts}" -- "$cur"))
    fi
  else
    COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
  fi
}

_adguard_cli_export_logs() {
  local opts="--output ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_export_settings() {
  local opts="--output ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_import_settings() {
  local opts="--input ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_cert() {
  local opts="--firefox-profile ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_speed() {
  local opts="--json --chunk ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_userscripts() {
  local opts="list install remove enable disable ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_install_browser_integration() {
  local opts="--uninstall ${_adguard_cli_common_opts}"
  COMPREPLY=($(compgen -W "${opts}" -- "$cur"))
}

_adguard_cli_completion() {
  local cur prev command
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Find the main command in the input
  # shellcheck disable=SC2066
  for word in "${COMP_WORDS[1]}"; do
    case "$word" in
      configure|cert|activate|reset-license|start|stop|restart|status|license|config|check-update|update|filters|dns|userscripts|export-logs|export-settings|import-settings|speed)
        command="$word"
        break
        ;;
    esac
  done

  # Call the appropriate function based on the main command found
  case "$command" in
    start)
      _adguard_cli_start
      ;;
    config)
      _adguard_cli_config
      ;;
    filters)
      _adguard_cli_filters
      ;;
    dns)
      _adguard_cli_dns
      ;;
    export-logs)
      _adguard_cli_export_logs
      ;;
    export-settings)
      _adguard_cli_export_settings
      ;;
    import-settings)
      _adguard_cli_import_settings
      ;;
    cert)
      _adguard_cli_cert
      ;;
    speed)
      _adguard_cli_speed
      ;;
    userscripts)
      _adguard_cli_userscripts
      ;;
    install-browser-integration)
      _adguard_cli_install_browser_integration
      ;;
    *)
      if [[ $COMP_CWORD -eq 1 ]]; then
        local main_opts="${_adguard_cli_opts}"
        COMPREPLY=($(compgen -W "${main_opts}" -- "$cur"))
      else
        local main_opts="${_adguard_cli_common_opts}"
        COMPREPLY=($(compgen -W "${main_opts}" -- "$cur"))
      fi
      ;;
  esac
}

if [ -n "$ZSH_VERSION" ]; then
  if ! (which compinit &> /dev/null); then
    autoload -U +X compinit && compinit
    autoload -U +X bashcompinit && bashcompinit
  fi
fi

complete -F _adguard_cli_completion adguard-cli
