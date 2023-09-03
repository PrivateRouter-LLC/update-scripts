#!/usr/bin/env bash
# Update script to update the scripts in /pr-scripts in PrivateRouter OpenWRT routers
# Version 1.0
# Contact: jason@torguard.net

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

HASH_STORE="/etc/config/.pr-scripts"
GIT_URL="https://github.com/PrivateRouter-LLC/pr-scripts.git"
TMP_DIR="/tmp/pr-scripts"
REPO_LOCATION="/pr-scripts"
UPDATE_NEEDED="0"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/pr-scripts/commits/main | \
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
    # If this completed successfully, we can remove the old directory
    if [ $? -eq 0 ]; then
        [ -d "${REPO_LOCATION}" ] && { log_say "Removing old ${REPO_LOCATION}"; rm -rf "${REPO_LOCATION}"; }

        log_say "Moving ${TMP_DIR} to ${REPO_LOCATION}"
        mv "${TMP_DIR}" "${REPO_LOCATION}"   

        log_say "Removing ${TMP_DIR} as cleanup"
        rm -rf "${TMP_DIR}"
    fi
else
    log_say "No update needed for ${REPO_LOCATION}"
fi
