#!/bin/sh
### BEGIN INIT INFO
# Provides:          fetch-config
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Fetch init configuration JSON file
# Description:       Fetch configuration JSON file and render the templates of the services
### END INIT INFO

set -e

INIT_CONFIG_FILE="/etc/init-config.json"
TEMPLATED_CONFIG_FILES="/etc/td-agent-bit/td-agent-bit.conf /etc/process-exporter/process-exporter.yaml /etc/prometheus/prometheus.yml /etc/rclone.conf /etc/orderflow-proxy.conf /etc/system-api/systemapi-config.toml /etc/rbuilder-bidding/rbuilder-bidding-token /etc/haproxy/haproxy.cfg /etc/td-agent-bit/aws-auth /etc/acme.sh/acme-le.env /etc/rbuilder.env"
TEMPLATED_CONFIG_FILES_UNSAFE="/etc/rbuilder-bidding/bidding-service.toml /etc/disk-encryption/key /etc/rbuilder.config"
OPTIONAL_TEMPLATES="/etc/disk-encryption/key"
SYSTEM_API_FIFO=/var/volatile/system-api.fifo

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

optional_template() {
    file="$1"

    for optional in $OPTIONAL_TEMPLATES; do
        if [ "$file" = "$optional" ]; then
            log "Skipping optional template $file"
            return 0
        fi
    done

    log "Failed to render required template $file"
    exit 1
}

case "$1" in
  start)
    log "Fetching configuration..."

    (umask 0177 && touch "${INIT_CONFIG_FILE}")
    curl -fsSL --retry 3 --retry-delay 60 --retry-connrefused \
      -o "${INIT_CONFIG_FILE}" http://localhost:7937/api/l1-builder/v1/configuration
    if [ ! -s "${INIT_CONFIG_FILE}" ]; then
      log "Failed to fetch configuration."
      exit 1
    fi
    for file in $TEMPLATED_CONFIG_FILES; do
      /usr/bin/render-config.sh "${INIT_CONFIG_FILE}" "${file}.mustache" > "${file}" || optional_template $file
      log "Rendered ${file}."
    done
    for file in $TEMPLATED_CONFIG_FILES_UNSAFE; do
      /usr/bin/render-config.sh --unsafe "${INIT_CONFIG_FILE}" "${file}.mustache" > "${file}" || optional_template $file
      log "Rendered ${file}."
    done
    chmod 600 /etc/disk-encryption/key
    log "All configs rendered successfully"
    rm -f "${INIT_CONFIG_FILE}"
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
