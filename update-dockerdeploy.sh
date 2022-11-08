#!/usr/bin/env bash
# Update script for DockerDeploy in PrivateRouter OpenWRT routers
# Version 1.0
# Contact: ops@torguard.net

HASH_STORE="/etc/config/.dockerdeploy"
GIT_URL="https://github.com/PrivateRouter-LLC/dockerdeploy.git"
TMP_DIR="/tmp/dockerdeploy"
DOCKERDEPLOY_LOCATION="/usr/bin/dockerdeploy"
UPDATE_NEEDED="0"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/dockerdeploy/commits/main |
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

    [ -f "${DOCKERDEPLOY_LOCATION}" ] && { echo "Removing old ${DOCKERDEPLOY_LOCATION}"; rm "${DOCKERDEPLOY_LOCATION}"; }
    [ -f "${TMP_DIR}/dockerdeploy.sh" ] && {
        echo "Moving ${TMP_DIR}/dockerdeploy.sh to ${DOCKERDEPLOY_LOCATION}"
        mv "${TMP_DIR}/dockerdeploy.sh" "${DOCKERDEPLOY_LOCATION}"   
        chmod +x "${DOCKERDEPLOY_LOCATION}"
    }

    echo "Removing ${TMP_DIR} as cleanup"
    rm -rf "${TMP_DIR}"
else
    echo "No update needed for ${DOCKERDEPLOY_LOCATION}"
fi