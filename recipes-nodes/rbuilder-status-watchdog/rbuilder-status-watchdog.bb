SUMMARY = "rbuilder status watchdog"
DESCRIPTION = "Checks the status of rbuilder in BuilderHub and toggles the service"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "file://rbuilder-status-watchdog.sh \
           file://rbuilder-status-watchdog.cron"

S = "${WORKDIR}"

do_install() {
  # Create necessary directories
  install -d ${D}${sysconfdir}/init.d
  install -d ${D}${sysconfdir}/cron.d

  # Install scripts
  install -m 0755 ${S}/rbuilder-status-watchdog.sh ${D}${sysconfdir}/init.d/rbuilder-status-watchdog

  # Install a cron job
  install -m 0755 ${WORKDIR}/rbuilder-status-watchdog.cron ${D}${sysconfdir}/cron.d/rbuilder-status-watchdog
}

RDEPENDS:${PN} += "jq curl coreutils rbuilder"

inherit update-rc.d

INITSCRIPT_NAME = "rbuilder-status-watchdog"
INITSCRIPT_PARAMS = "defaults 89"
