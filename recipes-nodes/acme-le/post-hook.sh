#!/bin/sh
set -eux -o pipefail

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
  http://localhost:7937/api/l1-builder/v1/register_credentials/instance || (

  err_msg="Failed to register TLS certificate with BuilderHub."
  log "$err_msg" | tee -a "$LOG_FILE"
  exit 1
)
log "TLS certificate registered successfully with BuilderHub."

# Export cert expiration date as a metric
EXPIRATION_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
EXPIRATION_DATE_UNIX_SECONDS=$(date -d "$EXPIRATION_DATE" +%s)
METRICS_FILE="/var/lib/node_exporter/textfile_collector/acme_le_cert_expiration.prom"
printf "# HELP acme_le_cert_expiration_seconds The expiration date of the ACME certificate in Unix time.
# TYPE acme_le_cert_expiration_seconds gauge
acme_le_cert_expiration_seconds{domain=\"$MAIN_DOMAIN\"} $EXPIRATION_DATE_UNIX_SECONDS\n" > "$METRICS_FILE"
chmod 644 "$METRICS_FILE"

ln -fsr "$PRIV_KEY" "$(dirname $CERT_PATH)/${MAIN_DOMAIN}.key"
