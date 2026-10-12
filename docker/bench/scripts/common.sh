#!/bin/bash
# Shared helpers. Source this file; do not execute it.
END='\033[0m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; WHITE='\033[0;37m'

log() {
  local type=$1 message=$2 timestamp color
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  case $type in
    INFO|SUCCESS) color=$GREEN ;;
    ERROR) color=$RED ;;
    WARN|WARNING) color=$YELLOW ;;
    DEBUG) color=$CYAN ;;
    *) color=$WHITE ;;
  esac
  echo -e "${color}[$type - $timestamp] $message${END}"
}

require_env() {
  local name
  for name in "$@"; do
    [[ -z "${!name:-}" ]] && { log ERROR "$name cannot be empty. Exiting..."; exit 1; }
  done
  return 0
}

is_true() { [[ "${1:-}" =~ ^(1|true|TRUE|yes|YES)$ ]]; }

# "https://github.com/frappe/helpdesk.git#develop" -> source / branch / app name
app_source() { echo "${1%%#*}"; }
app_branch() { [[ "$1" == *"#"* ]] && echo "${1#*#}" || echo ""; }
app_name() { local s; s=$(app_source "$1"); s=${s%/}; s=${s##*/}; echo "${s%.git}"; }

# Defaults shared by all bootstrap scripts
FRAPPE_VERSION="${FRAPPE_VERSION:-version-15}"
FRAPPE_APPS="${FRAPPE_APPS:-}"
FRAPPE_APPS="${FRAPPE_APPS//,/ }"
SITE_NAME="${SITE_NAME:-support}"
DB_HOST="${DB_HOST:-mariadb}"
DB_ROOT_USER="${DB_ROOT_USER:-root}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-admin123}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
