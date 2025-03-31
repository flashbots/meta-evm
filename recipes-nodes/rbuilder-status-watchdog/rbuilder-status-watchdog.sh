#!/bin/sh
### BEGIN INIT INFO
# Provides:          rbuilder-status-watchdog
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: rbuilder status watchdog
# Description:       Checks the status of rbuilder in BuilderHub and toggles the service
### END INIT INFO

set -e

SYSTEM_API_FIFO="/var/volatile/system-api.fifo"
RBUILDER_PERSISTENT_DIR="/persistent/rbuilder"
RBUILDER_STATUS_FLAG_FILE="${RBUILDER_PERSISTENT_DIR}/rbuilder.enabled"
# locally exposed BuilderHub API proxied through CVM proxy
BHUB_URL_PROXIED="http://localhost:7937/api/l1-builder/v1/configuration"

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

case "$1" in
  start)
    BHUB_CONFIG=$(curl -fsSL --retry 3 --retry-delay 5 --retry-connrefused $BHUB_URL_PROXIED)

    if [ -z "${BHUB_CONFIG}" ]; then
      log "rbuilder-status-watchdog: Failed to fetch configuration."
      exit 1
    fi

    RBUILDER_ENABLED=$(echo "${BHUB_CONFIG}" | jq -r '.rbuilder.enabled')
    if [ ! -d "${RBUILDER_PERSISTENT_DIR}" ]; then
      umask 0022
      mkdir -p $RBUILDER_PERSISTENT_DIR
    fi

    umask 0133
    if [ "${RBUILDER_ENABLED}" = "true" ]; then
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
