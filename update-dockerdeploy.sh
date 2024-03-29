#!/usr/bin/env bash
# Update script for DockerDeploy in PrivateRouter OpenWRT routers
# Version 1.2
# Contact: jason@torguard.net

# We do not run on mini routers so if we find /etc/pr-mini, we exit!
[ -f /etc/pr-mini ] && exit 0

# Source our base OpenWRT functions
. /lib/functions.sh

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
    echo "${SCRIPT_NAME}: ${1}" >> "/tmp/${SCRIPT_NAME}.log"
}

# Command to wait for Internet connection
wait_for_internet() {
    while ! ping -q -c3 1.1.1.1 >/dev/null 2>&1; do
        log_say "Waiting for Internet connection..."
        sleep 1
    done
    log_say "Internet connection established"
}

wait_for_internet

# Force source our REPO variable from /root/.profile
# This way it proliferates into all other scripts this one sources
. /root/.profile

log_say "***[ REPO is set to: ${REPO} ]***"

HASH_STORE="/etc/config/.dockerdeploy"
GIT_URL="https://github.com/PrivateRouter-LLC/dockerdeploy.git"
TMP_DIR="/tmp/dockerdeploy"
DOCKERDEPLOY_LOCATION="/usr/bin/dockerdeploy"
UPDATE_NEEDED="0"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/dockerdeploy/commits/main | \
        jq --raw-output '.sha'
)

log_say "Got current hash ${CURRENT_HASH}"

if [ -f "${HASH_STORE}" ]; then
    log_say "Found ${HASH_STORE}"
    CHECK_HASH=$(cat ${HASH_STORE})
    log_say "Check Hash ${CHECK_HASH}"
    [[ "${CHECK_HASH}" != "${CURRENT_HASH}" ]] && {
        log_say "${CHECK_HASH} != ${CURRENT_HASH}"
        UPDATE_NEEDED="1"
        echo "${CURRENT_HASH}" > "${HASH_STORE}"
        log_say "Wrote ${CURRENT_HASH} > ${HASH_STORE}"
    }
else
    log_say "${HASH_STORE} did not exist"
    touch "${HASH_STORE}"
    echo "${CURRENT_HASH}" > "${HASH_STORE}"
    log_say "Wrote ${CURRENT_HASH} > ${HASH_STORE}"
    UPDATE_NEEDED="1"
fi

if [[ "${UPDATE_NEEDED}" == "1" ]]; then
    log_say "Update needed: ${UPDATE_NEEDED}"

    [ -d "${TMP_DIR}" ] && {
        log_say "Cleaning temporary output ${TMP_DIR}"
        rm -rf "${TMP_DIR}"
    }

    log_say "Cloning ${GIT_URL} into ${TMP_DIR}"
    git clone --depth=1 "${GIT_URL}" "${TMP_DIR}"

    [ -f "${DOCKERDEPLOY_LOCATION}" ] && { log_say "Removing old ${DOCKERDEPLOY_LOCATION}"; rm "${DOCKERDEPLOY_LOCATION}"; }
    [ -f "${TMP_DIR}/dockerdeploy.sh" ] && {
        log_say "Moving ${TMP_DIR}/dockerdeploy.sh to ${DOCKERDEPLOY_LOCATION}"
        mv "${TMP_DIR}/dockerdeploy.sh" "${DOCKERDEPLOY_LOCATION}"   
        chmod +x "${DOCKERDEPLOY_LOCATION}"
    }

    log_say "Removing ${TMP_DIR} as cleanup"
    rm -rf "${TMP_DIR}"
else
    log_say "No update needed for ${DOCKERDEPLOY_LOCATION}"
fi