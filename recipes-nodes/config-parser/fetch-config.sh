#!/bin/sh
### BEGIN INIT INFO
# Provides:          fetch-config
# Required-Start:    $network
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Fetch configuration JSON file
# Description:       Fetch configuration JSON file and set up environment variables
### END INIT INFO

set -e

# Source the configuration file
source /etc/cloud-init-config.conf

case "$1" in
  start)
    echo "Fetching configuration..."
    if curl -o /etc/config.json "${CONFIG_URL}"; then
      echo "Configuration fetched successfully."
      # Parse the config and write to a file
      /usr/bin/config_parser.sh /etc/config.json > /etc/cloud-init-env
      # Make the file readable only by root
      chmod 600 /etc/cloud-init-env
      # Source the file to set variables for this session
      source /etc/cloud-init-env
    else
      echo "Failed to fetch configuration."
    fi
    ;;
  stop)
    echo "Nothing to stop."
    ;;
  restart|reload)
    $0 stop
    $0 start
    ;;
  status)
    if [ -f /etc/config.json ]; then
      echo "Configuration file exists."
    else
      echo "Configuration file does not exist."
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0