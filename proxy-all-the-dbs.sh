#!/bin/sh

#set -euo pipefail

###############################################################################
# Function: db_port_from_app_name <app>
# Deterministically derive an ephemeral port (10240-49151) from app name.
###############################################################################

db_port_from_app_name() {
  if [ $# -ne 1 ]; then
    echo "Usage: db_port_from_app_name <project name> <app-name>" >&2
    return 1
  fi
  local project="$1"
  local name="$2"
  local min=10240
  local max=49151
  local range=$((max - min + 1))
  # Use shasum (mac) / sha256sum (linux fallback)
  if command -v shasum >/dev/null 2>&1; then
    local hash=$(printf '%s' "$project/$name" | shasum -a 256 | awk '{print $1}')
  else
    local hash=$(printf '%s' "$project/$name" | sha256sum | awk '{print $1}')
  fi
  # Convert a slice of hash to number.
  # shellcheck disable=SC2005
  echo $(printf '%s' "$hash" | head -c 8 | xxd -r -p | od -An -tu4 | head -n1 | awk -v min=$min -v range=$range '{print ($1 % range) + min}')
}

###############################################################################
# Function: find_all_dev_db_names
# Echo list of database names found in .nais manifests (deduplicated, sorted).
###############################################################################

find_all_dev_db_names() {
   #Requirements: yq (mikefarah or python wrapper). Avoids startswith()/test() to support older versions.
   # Find all db names: Only .metadata.name from manifests with sqlInstances of type POSTGRES
  FILTER='select(.spec.gcp.sqlInstances[]? | select((.type // "" | tostring | split("_")[0]) == "POSTGRES")) | .metadata.name'

  find . -maxdepth 3 -type d -name ".nais" -print0 | while IFS= read -r -d '' naisapp; do
    find "$naisapp" -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \) -print0 | while IFS= read -r -d '' name; do
      sed '/{{.*}}/d' "$name" \
        | yq -r "$FILTER" 2>/dev/null \
        | grep -v '^null$' \
        | grep -v '^$'
    done
  done | sort -u
}

###############################################################################
# Function: start_proxies
# Iterate db names, grant access, and start nais postgres proxy in background.
###############################################################################

start_proxies() {
  local sleep_between=${1:-10}
  local dbnames
  dbnames=$(find_all_dev_db_names)
  if [ -z "$dbnames" ]; then
    echo "No database names found" >&2
    return 1
  fi
  local context=$(kubectx -c)
  local namespace=$(kubens -c)
  echo "Databases to proxy for context $context in namespace $namespace:"
  echo "$dbnames" | sed 's/^/  - /'
  echo
  for db in $dbnames; do
    local port
    port=$(db_port_from_app_name "$context/$namespace/$db")
    echo "Using local port $port for app $db"

    # one-time commands
    #nais postgres prepare $db
    #nais postgres grant "$db"

    # the actual target command
    nais postgres proxy --port "$port" "$db" &
    # we sleep because the above nais command returns before it is ready
    sleep "$sleep_between"
  done

  echo "IntelliJ IDEA connection strings for all databases"
  echo "--------------------------------------------------"
  echo "Copy and paste these into IntelliJ IDEA to connect to the databases:"
  # Derive user from current shell user (lowercased) and append encoded domain
  user="$(whoami | tr '[:upper:]' '[:lower:]')%40nav.no"
  echo "username=$user and password='' (blank)"
  for db in $dbnames; do
      actual_db=$(echo $db|sed 's/^statistikk$/hendelser/'|sed 's/^api-intern$/api/')
      local port
      port=$(db_port_from_app_name "$context/$namespace/$db")
      echo "jdbc:postgresql://localhost:$port/$actual_db"
  done

}

###############################################################################
# cleanup on exit (kill background nais processes we started)
###############################################################################

_cleanup() {
  pkill -f "nais postgres proxy" >/dev/null 2>&1 || true
}
trap _cleanup EXIT INT TERM

###############################################################################
# Main execution
###############################################################################


echo "If you need to do nais login, do that now. Otherwise press any key to continue...". 
echo "kubectx and yq must be installed."
read wait
delay=${1:-10}
start_proxies "$delay"
echo "All proxies started."
wait
