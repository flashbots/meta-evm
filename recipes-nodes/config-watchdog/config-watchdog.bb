SUMMARY = "Config watchdog"
DESCRIPTION = "Pulls the config from BuilderHub and reloads repsective services"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "file://config-watchdog.sh \
           file://config-watchdog.cron"

S = "${WORKDIR}"

do_install() {
  # Create necessary directories
  install -d ${D}${sysconfdir}/init.d
  install -d ${D}${sysconfdir}/cron.d

  # Install scripts
  install -m 0755 ${S}/config-watchdog.sh ${D}${sysconfdir}/init.d/config-watchdog

  # Install a cron job
  install -m 0640 ${WORKDIR}/config-watchdog.cron ${D}${sysconfdir}/cron.d/config-watchdog
}

RDEPENDS:${PN} += "jq curl coreutils rbuilder"

inherit update-rc.d

INITSCRIPT_NAME = "config-watchdog"
INITSCRIPT_PARAMS = "defaults 89"
