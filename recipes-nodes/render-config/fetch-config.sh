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

source /etc/init-config.conf

INIT_CONFIG_FILE="/etc/init-config.json"
TEMPLATED_CONFIG_FILES="/etc/td-agent-bit/td-agent-bit.conf /etc/process-exporter/process-exporter.yaml /etc/prometheus/prometheus.yml /etc/rbuilder.config /etc/rclone.conf"

case "$1" in
  start)
    echo "Fetching configuration..."
    echo "Fetching configuration..." > /var/volatile/system-api.fifo

    (umask 0177 && touch "${INIT_CONFIG_FILE}")
    curl -fsSL --proxy http://localhost:7937 --retry 3 --retry-delay 60 --retry-connrefused \
      -H "Metadata: true" -o "${INIT_CONFIG_FILE}" "${INIT_CONFIG_URL}"
    if [ ! -s "${INIT_CONFIG_FILE}" ]; then
      echo "Failed to fetch configuration."
      exit 1
    fi
    for file in $TEMPLATED_CONFIG_FILES; do
      /usr/bin/render-config.sh "${INIT_CONFIG_FILE}" "${file}.mustache" > "${file}"
    done
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
