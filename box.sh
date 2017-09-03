#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

BOX_ACTION_NONE="none"
BOX_ACTION_INSTALL="install"
BOX_ACTION_UPGRADE="upgrade"

BOX_STATUS_MISSING="missing"
BOX_STATUS_OUTDATED="outdated"
BOX_STATUS_LATEST="latest"
BOX_STATUS_MISMATCH="mismatch"

INSTALL_CACHE=$(mktemp)
UPGRADE_CACHE=$(mktemp)

function satisfy () {
  local TYPE=$1
  shift
  eval satisfy-$TYPE "$@"
}

function check () {
  local TYPE=$1
  shift
  eval check-$TYPE "$@"

  if [ $BOX_STATUS = $BOX_STATUS_LATEST ]; then
    return 0
  fi
  return 1
}

function must-install () {
  local TYPE=$1
  shift
  eval check-$TYPE "$@"

  if [ $BOX_STATUS = $BOX_STATUS_MISSING ]; then
    return 0
  fi
  return 1
}

function must-upgrade () {
  local TYPE=$1
  shift
  eval check-$TYPE "$@"

  if [ $BOX_STATUS = $BOX_STATUS_OUTDATED ]; then
    return 0
  fi
  return 1
}

function did-install () {
  if [ $BOX_ACTION = $BOX_ACTION_INSTALL ]; then
    return 0
  else
    return 1
  fi
}

function did-upgrade () {
  if [ $BOX_ACTION = $BOX_ACTION_UPGRADE ]; then
    return 0
  else
    return 1
  fi
}

function execute-function () {
  local PREFIX=$1
  local IDENTIFIER=$2

  local IDENTIFIER=$(echo "$IDENTIFIER" | sed 's/^[^A-Za-z0-9]//')
  local IDENTIFIER=$(echo "$IDENTIFIER" | sed 's/[^A-Za-z0-9]/-/g')

  local TEMP_DIR=`mktemp --directory`
  cd "$TEMP_DIR"

  eval "$PREFIX-$IDENTIFIER"
}

function check-apt () {
  local PACKAGE=$1

  if [ ! -s $INSTALL_CACHE ]; then
    dpkg --get-selections > $INSTALL_CACHE
  fi

  if [ ! -s $UPGRADE_CACHE ]; then
    sudo apt-get -s upgrade > $UPGRADE_CACHE
  fi

  if ! cat $INSTALL_CACHE | grep -E "^$PACKAGE\\s+install$" > /dev/null; then
    BOX_STATUS=$BOX_STATUS_MISSING
  elif cat $UPGRADE_CACHE | grep -E '^Inst ' | cut -d ' ' -f 2 | grep -E "^$PACKAGE"; then
    BOX_STATUS=$BOX_STATUS_OUTDATED
  else
    BOX_STATUS=$BOX_STATUS_LATEST
  fi
}

function satisfy-apt () {
  local PACKAGE=$1

  check-apt "$PACKAGE"

  echo "$PACKAGE -> $BOX_STATUS"

  if [ $BOX_STATUS = $BOX_STATUS_LATEST ]; then
    BOX_ACTION=$BOX_ACTION_NONE
  else
    sudo apt-get install "$PACKAGE"

    if [ $BOX_STATUS = $BOX_STATUS_OUTDATED ]; then
      BOX_ACTION=$BOX_ACTION_UPGRADE
    elif [ $BOX_STATUS = $BOX_STATUS_MISSING ]; then
      BOX_ACTION=$BOX_ACTION_INSTALL
    fi
  fi
}

function check-golang () {
  local VERSION=$1

  if [ -f "/usr/local/go/bin/go" ]; then
    local CURRENT_VERSION=$(go version | cut -d ' ' -f 3)

    if [[ $CURRENT_VERSION = $VERSION ]]; then
      BOX_STATUS=$BOX_STATUS_LATEST
    else
      BOX_STATUS=$BOX_STATUS_MISMATCH
    fi
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-golang () {
  local VERSION=$1

  check-golang "$VERSION"

  echo "golang $VERSION -> $BOX_STATUS"

  if [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
    BOX_ACTION=$BOX_ACTION_NONE
  elif [[ $BOX_STATUS = $BOX_STATUS_MISMATCH ]]; then
    exit 1
  else
    local temp_dir=`mktemp --directory`
    cd $temp_dir
    wget "https://storage.googleapis.com/golang/$VERSION.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "$VERSION.linux-amd64.tar.gz"
    BOX_ACTION=$BOX_ACTION_INSTALL
  fi
}

function satisfy-executable () {
  local EXECUTABLE=$1
  check-executable "$EXECUTABLE"

  echo "$EXECUTABLE -> $BOX_STATUS"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    execute-function "install" "$EXECUTABLE"
  fi
}

function check-executable () {
  local EXECUTABLE=$1

  if hash $EXECUTABLE 2>/dev/null; then
    BOX_STATUS=$BOX_STATUS_LATEST
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-file () {
  local NAME=$1
  local FILE=$2

  check-file "$NAME" "$FILE"

  echo "$NAME -> $BOX_STATUS"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    execute-function "install" "$NAME"
  fi
}

function check-file () {
  local NAME=$1
  local FILE=$2

  if [[ -f $FILE ]]; then
    BOX_STATUS=$BOX_STATUS_LATEST
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function check-go-package () {
  local PACKAGE=$1

  if go list "$PACKAGE" > /dev/null; then
    BOX_STATUS=$BOX_STATUS_LATEST
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-go-package () {
  local PACKAGE=$1

  check-go-package "$PACKAGE"

  echo "$PACKAGE -> $BOX_STATUS"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    go get "$PACKAGE"
    BOX_ACTION=$BOX_ACTION_INSTALL
  else
    BOX_ACTION=$BOX_ACTION_NONE
  fi
}

function check-github () {
  local REPOSITORY=$1
  local DESTINATION=$2

  if [ -d "$DESTINATION" ]; then
    cd "$DESTINATION"
    git fetch --quiet > /dev/null

    if [ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]; then
      BOX_STATUS=$BOX_STATUS_LATEST
    else
      BOX_STATUS=$BOX_STATUS_OUTDATED
    fi
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-github () {
  local REPOSITORY=$1
  local DESTINATION=$2

  check-github "$REPOSITORY" "$DESTINATION"

  echo "$REPOSITORY -> $BOX_STATUS"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    git clone "$REPOSITORY" "$DESTINATION"
    BOX_ACTION=$BOX_ACTION_INSTALL
  elif [[ $BOX_STATUS = $BOX_STATUS_OUTDATED ]]; then
    cd "$DESTINATION"
    git pull
    BOX_ACTION=$BOX_ACTION_UPGRADE
  else
    BOX_ACTION=$BOX_ACTION_NONE
  fi
}