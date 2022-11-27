#!/usr/bin/env bash
# Update script for PrivateRouter Repo in PrivateRouter OpenWRT routers
# Version 1.0
# Contact: ops@torguard.net

# If we are not connected to the internet, exit this updater
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

[ is_connected ] || exit 0

HASH_STORE="/etc/config/.pr-repo"
GIT_URL="https://github.com/PrivateRouter-LLC/pr-repo.git"
TMP_DIR="/tmp/pr-repo"
REPO_LOCATION="/root/pr-repo"
UPDATE_NEEDED="0"

CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/pr-repo/commits/main |
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

    [ -d "${REPO_LOCATION}" ] && { echo "Removing old ${REPO_LOCATION}"; rm -rf "${REPO_LOCATION}"; }

    echo "Moving ${TMP_DIR} to ${REPO_LOCATION}"
    mv "${TMP_DIR}" "${REPO_LOCATION}"   

    echo "Removing ${TMP_DIR} as cleanup"
    rm -rf "${TMP_DIR}"

    # Check if our crontab is in the crontab file
    CRONTAB_CONTENT=$(cat "/etc/crontabs/root")
    [[ "${CRONTAB_CONTENT}" =~ "update-repo-packages.sh" ]] && {
        echo "Update Script found update-repo-packages.sh, removing entry in crontab"
        sed -i '/update-repo-packages.sh/d' /etc/crontabs/root
    }

    [ -f "${REPO_LOCATION}/crontabs" ] && {
        echo "Update Script Inserting crontabs for repo tasks"
        cat "${REPO_LOCATION}/crontabs" >> /etc/crontabs/root
        /etc/init.d/cron restart
    }
else
    echo "No update needed for ${REPO_LOCATION}"
fi

# Always install our repo's public key to the router
wget -qO /tmp/public.key https://repo.privaterouter.com/public.key
opkg-key add /tmp/public.key
rm /tmp/public.key 

# Always update the repo
sed -i '/privaterouter_repo/d' /etc/opkg/customfeeds.conf 
echo "src/gz privaterouter_repo https://repo.privaterouter.com" >> /etc/opkg/customfeeds.conf

# Execute Script to install our packages we want installed
[ -f "${REPO_LOCATION}/update-repo-packages.sh" ] && {
    echo "Executing ${REPO_LOCATION}/update-repo-packages.sh"
    bash "${REPO_LOCATION}/update-repo-packages.sh"
}


