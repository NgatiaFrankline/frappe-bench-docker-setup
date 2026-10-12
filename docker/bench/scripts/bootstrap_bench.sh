#!/bin/bash
# Creates the bench (or switches Frappe to FRAPPE_VERSION) and fetches FRAPPE_APPS.
#   FRAPPE_VERSION  frappe branch/tag, e.g. version-15, version-16, develop
#   FRAPPE_APPS     comma separated: name | git-url, optional "#branch" suffix
#                   e.g. "erpnext#version-15,https://github.com/frappe/helpdesk#develop"
#   PYTHON_BIN      python interpreter used for the virtualenv (default python3)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_env BENCH_DIR

NEED_REQUIREMENTS=0
env_is_healthy() { [[ -x "${BENCH_DIR}/env/bin/python" ]] && "${BENCH_DIR}/env/bin/python" -c "import sys" 2>/dev/null; }
frappe_installed() { "${BENCH_DIR}/env/bin/python" -c "import frappe" 2>/dev/null; }

log INFO "Bootstrapping bench in ${BENCH_DIR} (frappe: ${FRAPPE_VERSION})"
mkdir -p "$(dirname "${BENCH_DIR}")"

if [[ ! -d "${BENCH_DIR}/apps/frappe/.git" ]]; then
  # Remove leftovers (e.g. a venv that is not usable inside the container)
  if [[ -d "${BENCH_DIR}" ]]; then
    log WARN "Incomplete bench found, recreating it"
    cd "$(dirname "${BENCH_DIR}")"
    rm -rf "${BENCH_DIR}"
  fi
  bench init "${BENCH_DIR}" --frappe-branch "${FRAPPE_VERSION}" --python "${PYTHON_BIN}" \
    --skip-redis-config-generation --verbose
  cd "${BENCH_DIR}"
else
  cd "${BENCH_DIR}"
  if ! env_is_healthy; then
    log WARN "Virtualenv is unusable, recreating it"
    rm -rf env
    "${PYTHON_BIN}" -m venv env
    env/bin/pip install -q -U pip wheel
    NEED_REQUIREMENTS=1
  fi

  current=$(git -C apps/frappe rev-parse --abbrev-ref HEAD)
  if [[ "${current}" != "${FRAPPE_VERSION}" ]]; then
    log INFO "Switching frappe ${current} -> ${FRAPPE_VERSION}"
    git -C apps/frappe config core.fileMode false
    git -C apps/frappe remote get-url upstream >/dev/null 2>&1 || \
      git -C apps/frappe remote add upstream https://github.com/frappe/frappe.git
    git -C apps/frappe fetch upstream "${FRAPPE_VERSION}" --depth 1
    git -C apps/frappe checkout -B "${FRAPPE_VERSION}" FETCH_HEAD
    NEED_REQUIREMENTS=1
  fi
  frappe_installed || NEED_REQUIREMENTS=1
fi

# apps.txt must only list apps usable with this frappe version, otherwise every
# bench command fails (e.g. an app requiring a newer Python than the venv has)
{
  echo frappe
  for entry in ${FRAPPE_APPS}; do
    name=$(app_name "${entry}")
    if [[ -d "apps/${name}" ]]; then echo "${name}"; fi
  done
} | awk '!seen[$0]++' > sites/apps.txt
log INFO "apps.txt: $(tr '\n' ' ' < sites/apps.txt)"

# bench commands exec the venv python, so frappe must be installed first
if [[ "${NEED_REQUIREMENTS}" == "1" ]]; then
  log INFO "Installing requirements"
  bench setup requirements
  NEED_REQUIREMENTS=0
fi

# Keep the bench's redis/db settings pointed at the compose services
bench set-config -g db_host "${DB_HOST}"
bench set-config -g redis_cache "redis://redis-cache:6379"
bench set-config -g redis_queue "redis://redis-queue:6379"
bench set-config -g redis_socketio "redis://redis-queue:6379"

for entry in ${FRAPPE_APPS}; do
  name=$(app_name "${entry}")
  if [[ -d "apps/${name}" ]]; then
    log INFO "App ${name} already present, skipping download"
    grep -qx "${name}" sites/apps.txt || echo "${name}" >> sites/apps.txt
    "${BENCH_DIR}/env/bin/pip" show "${name}" >/dev/null 2>&1 || bench setup requirements --python
    continue
  fi
  branch=$(app_branch "${entry}")
  log INFO "Fetching app ${name} ${branch:+(branch ${branch})}"
  bench get-app ${branch:+--branch "${branch}"} "$(app_source "${entry}")" --skip-assets
done

log INFO "Building assets"
bench build
log SUCCESS "Bench bootstrap complete"
