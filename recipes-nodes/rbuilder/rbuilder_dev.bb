SUMMARY = "Rust Builder"
HOMEPAGE = "https://github.com/flashbots/rbuilder-private"
LICENSE = "CLOSED"

inherit cargo_bin

python () {
    import os
    origenv = d.getVar("BB_ORIGENV", False)
    git_token = origenv.getVar('GIT_TOKEN') or os.getenv('GIT_TOKEN')
    if not git_token:
        bb.fatal("GIT_TOKEN environment variable not set or is empty")
    else:
        bb.note("GIT_TOKEN is set")
    
    # Set the SRC_URI with the token included
    d.setVar('SRC_URI', f"git://{git_token}@github.com/flashbots/rbuilder-private.git;protocol=https;branch=main")
}

SRCREV = "49eee1f3af9dd7bbeecd331f371c288047d4481c"
PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

# Enable network access for cargo to fetch dependencies
do_compile[network] = "1"

# Avoid caching sensitive information
BB_BASEHASH_IGNORE_VARS:append = " GIT_TOKEN"
BB_DONT_CACHE = "1"

# Exclude GIT_TOKEN from being logged
GIT_TOKEN[vardepsexclude] = "GIT_TOKEN"