SUMMARY = "Cloud Init Custom Data JSON Parser for Environment Variables"
DESCRIPTION = "A bash script that parses a JSON file and exports key-value pairs as environment variables"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/:"
SRC_URI = "file://config_parser.sh \
           file://setup_env.sh \
           file://fetch-config.sh"

S = "${WORKDIR}"

# Default value for the config URL
CLOUD_INIT_CONFIG_URL ?= "http://10.0.2.2:8000/config.json"

do_install() {
    # Create necessary directories
    install -d ${D}${bindir}
    install -d ${D}${sysconfdir}
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}${sysconfdir}/profile.d

    # Install scripts
    install -m 0755 ${S}/config_parser.sh ${D}${bindir}
    install -m 0755 ${S}/setup_env.sh ${D}${bindir}
    install -m 0755 ${S}/fetch-config.sh ${D}${sysconfdir}/init.d/fetch-config

    # Create configuration file with the URL
    echo "CONFIG_URL=${CLOUD_INIT_CONFIG_URL}" > ${D}${sysconfdir}/cloud-init-config.conf

    # Set up profile.d script to source setup_env.sh
    echo "source /usr/bin/setup_env.sh" > ${D}${sysconfdir}/profile.d/json_env_vars.sh
}

RDEPENDS:${PN} += "jq curl"

inherit update-rc.d

INITSCRIPT_NAME = "fetch-config"
INITSCRIPT_PARAMS = "defaults 90"
