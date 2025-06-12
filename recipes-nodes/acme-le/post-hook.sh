#!/bin/sh
source /etc/acme.sh/acme-le.env

LOG_FILE="$LOG_DIR/acme.sh.log"

function log() {
  date_log() {
    echo -n "$(date --iso-8601=seconds): "
  }
  echo "$(date_log)$1" | tee -a $SYSTEM_API_FIFO
}

MAIN_DOMAIN=$(echo "$DNS_NAMES" | cut -d',' -f1)
CERT_PATH=$(find "$ACME_HOME" -name "${MAIN_DOMAIN}.cer" | head -n 1)
# sed puts '\\n' at the end of every line, then tr removes the newlines.
CERT_ESCAPED=$(sed 's/$/\\n/g' "$CERT_PATH" | tr -d '\n')

# Register the certificate with BuilderHub
curl -fsSL --retry 3 --retry-delay 60 --retry-connrefused \
  -H "Content-Type: application/json" \
  -d "{\"tls_cert\": \"$CERT_ESCAPED\"}" \
  http://localhost:7937/api/l1-builder/v1/register_credentials/instance

if [ $? -ne 0 ]; then
  err_msg="Failed to register TLS certificate with BuilderHub."
  log "$err_msg" | tee -a "$LOG_FILE"
  exit 1
fi

log "TLS certificate registered successfully with BuilderHub."
