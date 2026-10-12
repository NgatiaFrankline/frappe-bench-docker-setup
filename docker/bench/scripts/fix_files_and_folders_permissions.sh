#!/bin/bash
set -euo pipefail
LOGS_DIR="/logs"
BACKUP_DIR="/backup"
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
log "INFO" "Fix files and folders ownership/permission script"
echo "Current user: $(whoami)"
sleep 3


echo
log "INFO" "Validating ENV variables..."
[[ -z "${SCRIPT_SOURCE}" ]] && { log "ERROR" "SCRIPT_SOURCE cannot be empty. Exiting..."; exit 1; }
[[ -z "${ENV}" ]] && { log "ERROR" "ENV cannot be empty. Exiting..."; exit 1; }
[[ -z "${BUILD_ENV}" ]] && { log "ERROR" "BUILD_ENV cannot be empty. Exiting..."; exit 1; }
[[ -z "${BENCH_DIR}" ]] && { log "ERROR" "BENCH_DIR cannot be empty. Exiting..."; exit 1; }
log "INFO" "Good! All ENV variables are set."
sleep 1


echo
echo "Checking for an existing installation"
if [ ! -d ${BENCH_DIR}/sites ]; then
  log "ERROR" "Ooops!!! App codebase not found!"
  echo "Please bootstrap the app before using script."
  echo "Bye..."
  exit 0
fi
log "INFO" "Found an app installation at ${BENCH_DIR}"
sleep 1


echo
log "INFO" "Setting logs backup permissions"
sudo mkdir -p "${LOGS_DIR}" "${BACKUP_DIR}"
sudo chown -R nobody:nogroup "${LOGS_DIR}" "${BACKUP_DIR}"
sudo chmod -R 777 "${LOGS_DIR}" "${BACKUP_DIR}"
echo "Done!"
sleep 1


echo
echo "Setting folders and files ownership/permissions..."
log "INFO" "Environment: ${ENV}"
if [ "${ENV}" = "dev" ]; then
  echo "Granting frappe ownership to all folders and files"
  sudo chown -R frappe:frappe ${BENCH_DIR}
  echo "You are in 'dev' environment, making all files and folders editable."
  sudo chmod 777 -R ${BENCH_DIR}
  echo "Done!"

  echo
  echo "Fixing private and public keys permissions"
  sudo find ${BENCH_DIR} -type f -name "*private.key" -exec chmod 600 {} +
  sudo find ${BENCH_DIR} -type f -name "*public.key" -exec chmod 660 {} +
  echo "Done!"
else
  log "INFO" "You are in 'prod' environment, we will set the correct folders and files ownership/permissions"
  chown -R frappe:frappe ${BENCH_DIR}
  sudo find ${BENCH_DIR} -type f -exec chmod 644 {} +
  sudo find ${BENCH_DIR} -type d -exec chmod 755 {} +
  echo "Done!"

  echo
  log "INFO" "Fixing private and public keys permissions"
  sudo find ${BENCH_DIR} -type f -name "*private.key" -exec chmod -v 600 {} +
  sudo find ${BENCH_DIR} -type f -name "*public.key" -exec chmod -v 660 {} +
  echo "Done!"

  echo
  log "INFO" "Make py executable"
  sudo chmod +x "${BENCH_DIR}/env/bin/*"
  sudo chmod +x "${BENCH_DIR}/apps/frappe/frappe/utils/*.py" 2>/dev/null
  echo "Done!"
fi
sleep 1


echo
log "INFO" "Showing ownership/permission status for: ${BENCH_DIR}"
stat -c '%a %h %U %G %s %y %n' ${BENCH_DIR}/*
echo


echo
echo "End of setting folders and files ownership/permission"
echo "Adios gringo!"
sleep 3
