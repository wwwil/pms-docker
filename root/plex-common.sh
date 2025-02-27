#!/bin/bash

CONT_CONF_FILE="/version.txt"

function addVarToConf {
  local variable="$1"
  local value="$2"
  if [ ! -z "${variable}" ]; then
    echo ${variable}=${value} >> ${CONT_CONF_FILE}
  fi
}

function readVarFromConf {
  local variable="$1"
  declare -n value=$2
  if [ ! -z "${variable}" ]; then
    value="$(grep -w ${variable} ${CONT_CONF_FILE} | cut -d'=' -f2 | tail -n 1)"
  else
    value=NULL
  fi
}

function getVersionInfo {
  local version="$1"
  local token="$2"
  declare -n remoteVersion=$3
  declare -n remoteFile=$4
  
  local channel
  local tokenNeeded=1
  if [ ! -z "${PLEX_UPDATE_CHANNEL}" ] && [ "${PLEX_UPDATE_CHANNEL}" > 0 ]; then
    channel="${PLEX_UPDATE_CHANNEL}"
  elif [ "${version,,}" = "beta" ]; then
    channel=8
  elif [ "${version,,}" = "public" ]; then
    channel=16
    tokenNeeded=0
  else
    channel=8
  fi
  
  # Read container architecture info from file created when building Docker image
  readVarFromConf "plex_build" plexBuild
  readVarFromConf "plex_distro" plexDistro

  local url="https://plex.tv/downloads/details/5?build=${plexBuild}&channel=${channel}&distro=${plexDistro}"
  if [ ${tokenNeeded} -gt 0 ]; then
    url="${url}&X-Plex-Token=${token}"
  fi
  
  local versionInfo="$(curl -s "${url}")"
  
  # Get update info from the XML.  Note: This could countain multiple updates when user specifies an exact version with the lowest first, so we'll use first always.
  remoteVersion=$(echo "${versionInfo}" | sed -n 's/.*Release.*version="\([^"]*\)".*/\1/p')
  remoteFile=$(echo "${versionInfo}" | sed -n 's/.*file="\([^"]*\)".*/\1/p')
}


function installFromUrl {
  installFromRawUrl "https://plex.tv/${1}"
}

function installFromRawUrl {
  local remoteFile="$1"
  local last=0
  if [[ ! -e /tmp/plexmediaserver.deb ]]; then
    curl -k -J -L -o /tmp/plexmediaserver.deb "${remoteFile}"
    local last=$?
  fi

  # test if deb file size is ok, or if download failed
  if [[ "$last" -gt "0" ]] || [[ $(stat -c %s /tmp/plexmediaserver.deb) -lt 10000 ]]; then
    echo "Failed to fetch update"
    exit 1
  fi

  dpkg -i --force-confold --force-architecture  /tmp/plexmediaserver.deb
  rm -f /tmp/plexmediaserver.deb
}
