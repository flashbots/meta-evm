#!/bin/sh
# TODO: backend healchecks
LOG_DIR=/var/log
HAPROXY_ENV_FILE=/etc/haproxy/haproxy.env
ACME_HOME=/persistent/acme.sh
PRIV_KEY="${ACME_HOME}/key.pem"
CERT_FILE="${ACME_HOME}/cert.pem"

source /etc/acme.sh/acme-le.env

mkdir -p $ACME_HOME /var/run/haproxy
acme.sh --home $ACME_HOME \
  --register-account \
  -m webmaster@buildernet.org \
  --server letsencrypt \
  --log $LOG_DIR/acme.sh.log --log-level 1
grep -m 1 -o -E "ACCOUNT_THUMBPRINT='[^']*'" $LOG_DIR/acme.sh.log > $HAPROXY_ENV_FILE
chmod 644 $HAPROXY_ENV_FILE

if [ ! -f "$PRIV_KEY" ]; then
  openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
    -noenc -sha256 -out $CERT_FILE -keyout $PRIV_KEY -subj "/O=BuilderNet/CN=${DNS_NAME}"

  acme.sh --home $ACME_HOME --sign-csr --csr $CERT_FILE --stateless --server letsencrypt \
    --log $LOG_DIR/acme.sh.log --log-level 1

  DEPLOY_HAPROXY_HOT_UPDATE=yes \
  DEPLOY_HAPROXY_STATS_SOCKET=/var/run/haproxy/admin.sock \
  DEPLOY_HAPROXY_PEM_PATH=/etc/haproxy/certs \
    acme.sh --home $ACME_HOME --deploy -d $DNS_NAME --deploy-hook haproxy \
      --log $LOG_DIR/acme.sh.log --log-level 1
fi
