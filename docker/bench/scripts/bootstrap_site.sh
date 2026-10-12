#!/bin/bash
# Creates SITE_NAME and installs FRAPPE_APPS on it.
#   SITE_NAME         site to create (default support)
#   RESET_SITE        true => drop the site database/user and files first (DESTRUCTIVE)
#   DB_HOST / DB_ROOT_USER / DB_ROOT_PASSWORD / ADMIN_PASSWORD
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_env BENCH_DIR SITE_NAME DB_ROOT_PASSWORD
cd "${BENCH_DIR}"

mysql_root() { mariadb -h "${DB_HOST}" -u"${DB_ROOT_USER}" -p"${DB_ROOT_PASSWORD}" "$@"; }

drop_site() {
  local site=$1 cfg="sites/$1/site_config.json" db_name db_user
  if [[ -f "${cfg}" ]]; then
    db_name=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('db_name',''))" "${cfg}")
    db_user=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(d.get('db_user') or d.get('db_name',''))" "${cfg}")
    if [[ -n "${db_name}" ]]; then
      log WARN "Dropping database ${db_name}"
      mysql_root -e "DROP DATABASE IF EXISTS \`${db_name}\`; DROP USER IF EXISTS '${db_user}'@'%'; DROP USER IF EXISTS '${db_user}'@'localhost'; FLUSH PRIVILEGES;"
    fi
  fi
  rm -rf "sites/${site}"
}

if is_true "${RESET_SITE:-false}"; then
  log WARN "RESET_SITE=true: dropping site ${SITE_NAME}"
  drop_site "${SITE_NAME}"
fi

if [[ -d "sites/${SITE_NAME}" ]]; then
  log INFO "Site ${SITE_NAME} already exists, skipping creation"
else
  log INFO "Creating site ${SITE_NAME}"
  bench new-site "${SITE_NAME}" --db-root-username "${DB_ROOT_USER}" --db-root-password "${DB_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" --mariadb-user-host-login-scope='%'
fi

bench use "${SITE_NAME}"
bench --site "${SITE_NAME}" set-config developer_mode 1

installed=$(bench --site "${SITE_NAME}" list-apps 2>/dev/null | awk '{print $1}')
for entry in ${FRAPPE_APPS}; do
  name=$(app_name "${entry}")
  if grep -qx "${name}" <<<"${installed}"; then
    log INFO "${name} already installed on ${SITE_NAME}"
  else
    log INFO "Installing ${name} on ${SITE_NAME}"
    bench --site "${SITE_NAME}" install-app "${name}"
  fi
done

bench --site "${SITE_NAME}" migrate
bench --site "${SITE_NAME}" clear-cache
log SUCCESS "Site ${SITE_NAME} ready"
