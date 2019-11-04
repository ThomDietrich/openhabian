#!/usr/bin/env bash

# Find the absolute script location dir (e.g. BASEDIR=/opt/openhabian)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  BASEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$BASEDIR/$SOURCE"
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SCRIPTNAME="$(basename "$SOURCE")"

CONFIGFILE="/etc/openhabian.conf"
REPOSITORYURL=$(grep -i '^repositoryurl' ${CONFIGFILE} | cut -d '=' -f2)
CLONEBRANCH=$(grep -i '^clonebranch' ${CONFIGFILE} | cut -d '=' -f2)

export SOURCE BASEDIR SCRIPTNAME REPOSITORYURL CLONEBRANCH CONFIGFILE
