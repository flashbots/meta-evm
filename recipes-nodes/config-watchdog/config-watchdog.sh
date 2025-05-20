#!/bin/sh
### BEGIN INIT INFO
# Provides:          config-watchdog
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: config watchdog
# Description:       Pulls the config from BuilderHub and reloads repsective services
### END INIT INFO

set -e

SYSTEM_API_FIFO="/var/volatile/system-api.fifo"
RBUILDER_PERSISTENT_DIR="/persistent/rbuilder"
RBUILDER_STATUS_FLAG_FILE="${RBUILDER_PERSISTENT_DIR}/rbuilder.enabled"
# locally exposed BuilderHub API proxied through CVM proxy
BHUB_URL_PROXIED="http://localhost:7937/api/l1-builder/v1/configuration"
BHUB_CONFIG_FILE="/etc/init-config-watchdog.json"

function cleanup() {
  rm -f "${BHUB_CONFIG_FILE}"
}

trap cleanup EXIT

log() {
    if [ -p $SYSTEM_API_FIFO ]; then
        date_log() {
            echo -n ""
        }
    else
        date_log() {
            echo -n "$(date --iso-8601=seconds): "
        }
    fi
    echo "$(date_log)$1" | tee -a $SYSTEM_API_FIFO
}

function toggle_rbuilder() {
  local bhub_config_file="$1"
  local rbuilder_enabled=$(cat "${bhub_config_file}" | jq -r '.rbuilder.enabled')
  if [ ! -d "${RBUILDER_PERSISTENT_DIR}" ]; then
    umask 0022
    mkdir -p $RBUILDER_PERSISTENT_DIR
  fi

  umask 0133
  if [ "$rbuilder_enabled" = "true" ]; then
    if [ ! -f "${RBUILDER_STATUS_FLAG_FILE}" ]; then
      touch "${RBUILDER_STATUS_FLAG_FILE}"
      log "rbuilder-status-watchdog: rbuilder is enabled in BuilderHub"
      service rbuilder restart
    fi
  else
    if [ -f "${RBUILDER_STATUS_FLAG_FILE}" ]; then
      rm -f "${RBUILDER_STATUS_FLAG_FILE}"
      log "rbuilder-status-watchdog: rbuilder is disabled in BuilderHub"
      service rbuilder stop
    fi
  fi
}

function update_subsidies_config() {
  local bhub_config_file="$1"
  /usr/bin/render-config.sh --unsafe "${bhub_config_file}" /etc/rbuilder-bidding/bidding-service.toml.mustache > /tmp/bidding-service.toml.tmp

  if ! diff -q /tmp/bidding-service.toml.tmp /etc/rbuilder-bidding/bidding-service.toml > /dev/null; then
    mv /tmp/bidding-service.toml.tmp /etc/rbuilder-bidding/bidding-service.toml
    podman kill --signal=SIGHUP rbuilder-bidding
    log "update-subsisidies-config: Updated bidding service config"
  fi
}

case "$1" in
  start)
    (umask 0177 && touch "${BHUB_CONFIG_FILE}")
    curl -fsSL -o "${BHUB_CONFIG_FILE}"  --retry 3 --retry-delay 5 --retry-connrefused "${BHUB_URL_PROXIED}"

    if [ ! -s "${BHUB_CONFIG_FILE}" ]; then
      log "rbuilder-status-watchdog: Failed to fetch configuration."
      exit 1
    fi

    toggle_rbuilder "${BHUB_CONFIG_FILE}"

    update_subsidies_config "${BHUB_CONFIG_FILE}"

    ;;
  stop)
    echo "Nothing to stop."
    ;;
  restart|reload)
    $0 stop
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

exit 0
