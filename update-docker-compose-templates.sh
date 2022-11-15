#!/usr/bin/env bash
# Update script for docker-compose-templates in PrivateRouter OpenWRT routers
# Version 1.0
# Contact: ops@torguard.net

# If we are not connected to the internet, exit this updater
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

[ is_connected ] || exit 0

HASH_STORE="/etc/config/.docker-compose-templates"
GIT_URL="https://github.com/PrivateRouter-LLC/docker-compose-templates"
TMP_DIR="/tmp/docker-compose-templates"
TEMPLATE_LOCATION="/root/docker-compose"
UPDATE_NEEDED="0"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/docker-compose-templates/commits/main |
        jq --raw-output '.sha'
)

echo "Got current hash ${CURRENT_HASH}"

if [ -f "${HASH_STORE}" ]; then
    echo "Found ${HASH_STORE}"
    CHECK_HASH=$(cat ${HASH_STORE})
    echo "Check Hash ${CHECK_HASH}"
    [[ "${CHECK_HASH}" != "${CURRENT_HASH}" ]] && {
        echo "${CHECK_HASH} != ${CURRENT_HASH}"
        UPDATE_NEEDED="1"
        echo "${CURRENT_HASH}" > "${HASH_STORE}"
        echo "Wrote ${CURRENT_HASH} > ${HASH_STORE}"
    }
else
    echo "${HASH_STORE} did not exist"
    touch "${HASH_STORE}"
    echo "${CURRENT_HASH}" > "${HASH_STORE}"
    echo "Wrote ${CURRENT_HASH} > ${HASH_STORE}"
    UPDATE_NEEDED="1"
fi

if [[ "${UPDATE_NEEDED}" == "1" ]]; then
    echo "Update needed: ${UPDATE_NEEDED}"

    [ -d "${TMP_DIR}" ] && {
        echo "Cleaning temporary output ${TMP_DIR}"
        rm -rf "${TMP_DIR}"
    }

    echo "Cloning ${GIT_URL} into ${TMP_DIR}"
    git clone --depth=1 "${GIT_URL}" "${TMP_DIR}"

    [ -d "${TEMPLATE_LOCATION}" ] && { echo "Removing old ${TEMPLATE_LOCATION}"; rm -rf "${TEMPLATE_LOCATION}"; }
    [ -d "${TMP_DIR}/docker-compose" ] && {
        echo "Moving ${TMP_DIR}/docker-compose to ${TEMPLATE_LOCATION}"
        mv "${TMP_DIR}/docker-compose" "${TEMPLATE_LOCATION}"   
    }

    echo "Removing ${TMP_DIR} as cleanup"
    rm -rf "${TMP_DIR}"
else
    echo "No update needed for ${TEMPLATE_LOCATION}"
fi