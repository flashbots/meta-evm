#!/bin/sh
# TODO: backend healchecks
HAPROXY_ENV_FILE=/etc/haproxy/haproxy.env
PRIV_KEY="${ACME_HOME}/key.pem"
CERT_FILE="${ACME_HOME}/cert.pem"
CSR_FILE="${ACME_HOME}/csr.pem"
LOG_FILE="$LOG_DIR/acme.sh.log"

source /etc/acme.sh/acme-le.env

function log() {
  date_log() {
    echo -n "$(date --iso-8601=seconds): "
  }
  echo "$(date_log)$1" | tee -a $SYSTEM_API_FIFO
}

# Builds `subj` and `subjectAltName` strings for openssl command
function subj_altnames_string_builder() {
  local dns_names="$1"
  local subj="$(echo "$dns_names" | cut -d',' -f1)"
  local subj_text="/O=BuilderNet/CN=${subj}"
  local subj_altnames_text="-subj \"${subj_text}\""

  local old_ifs="$IFS"
  IFS=','
  set -- $dns_names
  IFS="$old_ifs"

  if [ $# -ge 2 ]; then
    local altnames_text="-addext \"subjectAltName="

    for name in "$@"; do
      altnames_text="${altnames_text}DNS:${name},"
    done

    altnames_text="${altnames_text%?}\""
    subj_altnames_text="${subj_altnames_text} ${altnames_text}"
  fi

  echo "$subj_altnames_text"
}

# Builds `-d <DOMAIN>` string for acme.sh deploy hook
function acme_sh_deploy_string_builder() {
  local dns_names="$1"
  local deploy_string=""

  local old_ifs="$IFS"
  IFS=','
  set -- $dns_names
  IFS="$old_ifs"

  for name in "$@"; do
    deploy_string="${deploy_string} -d ${name}"
  done

  echo "$deploy_string"
}

mkdir -p $ACME_HOME
acme.sh --home $ACME_HOME \
  --register-account \
  -m webmaster@buildernet.org \
  --server letsencrypt \
  --log $LOG_FILE --log-level 1
grep -m 1 -o -E "ACCOUNT_THUMBPRINT='[^']*'" $LOG_FILE > $HAPROXY_ENV_FILE
chmod 644 $HAPROXY_ENV_FILE

if [ ! -f "$PRIV_KEY" ]; then
  openssl ecparam -name prime256v1 -genkey -noout -out $PRIV_KEY

  subj_altnames=$(subj_altnames_string_builder "$DNS_NAMES")
  openssl req -noenc -x509 -key $PRIV_KEY -out $CERT_FILE -sha256 -days 90 \
    $subj_altnames

  openssl x509 -x509toreq -signkey $PRIV_KEY -in $CERT_FILE -out $CSR_FILE

  acme.sh --home $ACME_HOME --sign-csr --csr $CSR_FILE --stateless \
    --server letsencrypt \
    --post-hook /etc/acme.sh/hooks/post-hook.sh \
    --log $LOG_FILE --log-level 1

  DEPLOY_HAPROXY_HOT_UPDATE=yes \
  DEPLOY_HAPROXY_STATS_SOCKET=UNIX:/var/run/haproxy/admin.sock \
  DEPLOY_HAPROXY_PEM_PATH=/etc/haproxy/certs \
    acme.sh --home $ACME_HOME --deploy $(acme_sh_deploy_string_builder "$DNS_NAMES") \
    --deploy-hook /etc/acme.sh/deploy/haproxy.sh \
    --log $LOG_FILE --log-level 1

  log "Issued and deployed TLS certificate for domains: $DNS_NAMES"
fi
