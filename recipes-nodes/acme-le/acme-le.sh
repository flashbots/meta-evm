#!/bin/sh
### BEGIN INIT INFO
# Provides:          acme-le
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage LetsEncrypt TLS certificate
# Description:       Manage LetsEncrypt certificate for user orderflow
### END INIT INFO

set -e

source /etc/acme.sh/acme-le.env

HAPROXY_ENV_FILE=/etc/haproxy/haproxy.env
LOG_FILE="$LOG_DIR/acme.sh.log"

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
  local subj_altnames_text="-subj ${subj_text}"

  local old_ifs="$IFS"
  IFS=','
  set -- $dns_names
  IFS="$old_ifs"

  if [ $# -ge 2 ]; then
    local altnames_text="-addext subjectAltName="

    for name in "$@"; do
      altnames_text="${altnames_text}DNS:${name},"
    done
  fi

  altnames_text="${altnames_text%?}"
  subj_altnames_text="${subj_altnames_text} ${altnames_text}"

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

case "$1" in
  start)

    mkdir -p $ACME_HOME
    acme.sh --home $ACME_HOME --set-default-ca  --server letsencrypt
    acme.sh --home $ACME_HOME \
      --register-account \
      -m webmaster@buildernet.org \
      --log $LOG_FILE --log-level 1
    find $ACME_HOME -name ca.conf -exec grep ACCOUNT_URL {} \; > $HAPROXY_ENV_FILE
    service haproxy restart

    if [ -f "$PRIV_KEY" ]; then
      log "Found existing private key. Skipping key generation."
      exit 0
    fi

    openssl ecparam -name prime256v1 -genkey -noout -out $PRIV_KEY

    subj_altnames=$(subj_altnames_string_builder "$DNS_NAMES")
    openssl req -noenc -x509 -key $PRIV_KEY -out $CERT_FILE -sha256 -days 3650 \
      $subj_altnames

    openssl x509 -x509toreq -signkey $PRIV_KEY -in $CERT_FILE -out $CSR_FILE \
      -copy_extensions copy

    acme.sh --home $ACME_HOME --sign-csr --csr $CSR_FILE --dns dns_cf \
      --challenge-alias buildernet-org-acme-validation.org \
      --post-hook /etc/acme.sh/hooks/post-hook.sh \
      --log $LOG_FILE --log-level 1

    DEPLOY_HAPROXY_HOT_UPDATE=yes \
    DEPLOY_HAPROXY_STATS_SOCKET=UNIX:/var/run/haproxy/admin.sock \
    DEPLOY_HAPROXY_PEM_PATH=/usr/local/etc/haproxy/certs \
      acme.sh --home $ACME_HOME --deploy $(acme_sh_deploy_string_builder "$DNS_NAMES") \
      --deploy-hook haproxy \
      --log $LOG_FILE --log-level 1

    log "Issued and deployed TLS certificate for domains: $DNS_NAMES"
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
