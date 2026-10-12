#!/bin/bash
set -euo pipefail
END='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

log() {
  local type=$1 message=$2 timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local color=

  case $type in
    "INFO") color=$GREEN ;;
    "ERROR") color=$RED ;;
    "WARN"|"WARNING") color=$YELLOW ;;
    "DEBUG") color=$CYAN ;;
    "SUCCESS") color=$GREEN ;;
    *) color=$WHITE ;;
  esac
  echo -e "${color}[$type - $timestamp] $message${END}"
}


echo
log "INFO" "Docker entrypoint script"
log "" "You are running script as: $(whoami)"
sleep 1

echo
log "INFO" "Validating ENV variables..."
[[ -z "${SCRIPT_SOURCE}" ]] && { log "ERROR" "SCRIPT_SOURCE cannot be empty. Exiting..."; exit 1; }
[[ -z "${ENV}" ]] && { log "ERROR" "ENV cannot be empty. Exiting..."; exit 1; }
[[ -z "${BUILD_ENV}" ]] && { log "ERROR" "BUILD_ENV cannot be empty. Exiting..."; exit 1; }
[[ -z "${BENCH_DIR}" ]] && { log "ERROR" "BENCH_DIR cannot be empty. Exiting..."; exit 1; }
log "INFO" "Good! All ENV variables are set."
sleep 1


if [[ "${BOOTSTRAP:-false}" =~ ^(1|true|yes)$ ]]; then
  echo
  echo "==== Bootstrap (BOOTSTRAP=true) ====="
  bash "${SCRIPT_SOURCE}/bootstrap_bench.sh"
  bash "${SCRIPT_SOURCE}/bootstrap_site.sh"
  echo "==== End                         ====="
fi

echo
echo "==== Extra Configuration Scripts ====="
source "${SCRIPT_SOURCE}/fix_files_and_folders_permissions.sh"
echo "==== End                         ====="


echo
log "INFO" "You are in environment: ${RED}${ENV}"
if [ "${ENV}" = "dev" ]; then
  sleep infinity
else
  echo "Running production commands"
fi
