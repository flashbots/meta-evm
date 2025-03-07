SUMMARY = "rbuilder status watchdog"
DESCRIPTION = "Checks the status of rbuilder in BuilderHub and toggles the service"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "file://rbuilder-toggle.sh \
           file://rbuilder-toggle.cron"

S = "${WORKDIR}"

do_install() {
  # Create necessary directories
  install -d ${D}${bindir}
  install -d ${D}${sysconfdir}
  install -d ${D}${sysconfdir}/init.d
  install -d ${D}${sysconfdir}/cron.d

  # Install scripts
  install -m 0755 ${S}/rbuilder-toggle.sh ${D}${sysconfdir}/init.d/rbuilder-toggle

  # Install a cron job
  install -m 0755 ${WORKDIR}/rbuilder-toggle.cron ${D}${sysconfdir}/cron.d/rbuilder-toggle
}

RDEPENDS:${PN} += "jq curl coreutils rbuilder"

inherit update-rc.d

INITSCRIPT_NAME = "rbuilder-toggle"
INITSCRIPT_PARAMS = "defaults 89"
