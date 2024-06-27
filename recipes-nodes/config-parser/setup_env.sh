#!/bin/sh

if [ -f /etc/config.json ]; then
    eval "$(/bin/sh /usr/bin/config_parser.sh /etc/config.json)"
else
    echo "Warning: /etc/config.json not found. Environment variables not set." >&2
fi