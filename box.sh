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
  satisfy-$TYPE "$@"
}

function check () {
  local TYPE=$1
  shift
  check-$TYPE "$@"

  if [ $BOX_STATUS = $BOX_STATUS_LATEST ]; then
    return 0
  fi
  return 1
}

function must-install () {
  local TYPE=$1
  shift
  check-$TYPE "$@"

  if [ $BOX_STATUS = $BOX_STATUS_MISSING ]; then
    return 0
  fi
  return 1
}

function must-upgrade () {
  local TYPE=$1
  shift
  check-$TYPE "$@"

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
  $PREFIX-$IDENTIFIER
  cd $OLDPWD
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

  print-box-status "$PACKAGE"

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

function check-deb () {
  local PACKAGE=$1
  local URL=$2

  if [ ! -s $INSTALL_CACHE ]; then
    dpkg --get-selections > $INSTALL_CACHE
  fi

  if [ ! -s $UPGRADE_CACHE ]; then
    sudo apt-get -s upgrade > $UPGRADE_CACHE
  fi

  if ! cat $INSTALL_CACHE | grep -E "^$PACKAGE\\s+install$" > /dev/null; then
    BOX_STATUS=$BOX_STATUS_MISSING
  else
    BOX_STATUS=$BOX_STATUS_LATEST
  fi
}

function satisfy-deb () {
  local PACKAGE=$1
  local URL=$2

  check-deb "$PACKAGE" "$URL"

  print-box-status "$PACKAGE"

  if [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
    BOX_ACTION=$BOX_ACTION_NONE
  else
    local TEMP_DIR=`mktemp --directory`
    cd $TEMP_DIR
    wget -O package.deb "$URL"
    sudo dpkg -i package.deb
    cd $OLDPWD
    BOX_ACTION=$BOX_ACTION_INSTALL
  fi
}

function check-apt-ppa () {
  local PPA=$1
  local SEARCH=$(echo "$PPA" | sed 's/^ppa://')

  if apt-cache policy | grep "$SEARCH" > /dev/null; then
    BOX_STATUS=$BOX_STATUS_LATEST
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-apt-ppa () {
  local PPA=$1

  check-apt-ppa "$PPA"

  print-box-status "$PPA"

  if [ $BOX_STATUS = $BOX_STATUS_LATEST ]; then
    BOX_ACTION=$BOX_ACTION_NONE
  else
    sudo add-apt-repository -y "$PPA"
    sudo apt -y update
    BOX_ACTION=$BOX_ACTION_INSTALL
  fi
}

function check-file-line () {
  local FILE_PATH=$1
  local COMMENT=$2
  local LINE=$3
  local FULL_LINE="$LINE # $COMMENT"

  if [[ -f "$FILE_PATH" ]]; then
    if grep "$FULL_LINE" "$FILE_PATH" > /dev/null; then
      BOX_STATUS=$BOX_STATUS_LATEST
    else
      BOX_STATUS=$BOX_STATUS_MISSING
    fi
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-file-line () {
  local FILE_PATH=$1
  local COMMENT=$2
  local LINE=$3
  local FULL_LINE="$LINE # $COMMENT"

  check-file-line "$FILE_PATH" "$COMMENT" "$LINE"

  print-box-status "$FILE_PATH $COMMENT"

  if [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
    BOX_ACTION=$BOX_ACTION_NONE
  else
    echo "$FULL_LINE" >> "$FILE_PATH"
    BOX_ACTION=$BOX_ACTION_INSTALL
  fi
}

function check-symlink () {
  local TARGET=$1
  local NAME=$2

  if [[ -L $NAME ]]; then
    local EXISTING_TARGET=$(readlink -f "$NAME")

    if [[ "$EXISTING_TARGET" = "$TARGET" ]]; then
      BOX_STATUS=$BOX_STATUS_LATEST
    else
      BOX_STATUS=$BOX_STATUS_MISMATCH
    fi
  elif [[ -e $NAME ]]; then
    BOX_STATUS=$BOX_STATUS_MISMATCH
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-symlink () {
  local TARGET=$1
  local NAME=$2

  check-symlink "$TARGET" "$NAME"

  print-box-status "$NAME"

  if [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
    BOX_ACTION=$BOX_ACTION_NONE
  elif [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    ln -s "$TARGET" "$NAME"
    BOX_ACTION=$BOX_ACTION_INSTALL
  elif [[ $BOX_STATUS = $BOX_STATUS_MISMATCH ]]; then
    echo "Couldn't create symlink $NAME, because it already exists"
    echo "and is either a file, or a symlink pointing somewhere else."
    exit 1
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

  print-box-status "golang $VERSION"

  if [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
    BOX_ACTION=$BOX_ACTION_NONE
  elif [[ $BOX_STATUS = $BOX_STATUS_MISMATCH ]]; then
    exit 1
  else
    local TEMP_DIR=`mktemp --directory`
    cd $TEMP_DIR
    wget "https://storage.googleapis.com/golang/$VERSION.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "$VERSION.linux-amd64.tar.gz"
    cd $OLDPWD
    BOX_ACTION=$BOX_ACTION_INSTALL
  fi
}

function satisfy-executable () {
  local EXECUTABLE=$1
  check-executable "$EXECUTABLE"

  print-box-status "$EXECUTABLE"

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

  print-box-status "$NAME"

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

  print-box-status "$PACKAGE"

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

    cd $OLDPWD
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-github () {
  local REPOSITORY=$1
  local DESTINATION=$2

  check-github "$REPOSITORY" "$DESTINATION"

  print-box-status "$REPOSITORY"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    git clone "$REPOSITORY" "$DESTINATION"
    BOX_ACTION=$BOX_ACTION_INSTALL
  elif [[ $BOX_STATUS = $BOX_STATUS_OUTDATED ]]; then
    cd "$DESTINATION"
    git pull
    cd $OLDPWD
    BOX_ACTION=$BOX_ACTION_UPGRADE
  else
    BOX_ACTION=$BOX_ACTION_NONE
  fi
}

function check-dconf () {
  local DCONF_PATH=$1
  local DCONF_VALUE=$2

  local CURRENT_VALUE=$(dconf read "$DCONF_PATH" | sed "s/^'//" | sed "s/'$//")

  if [[ $CURRENT_VALUE = $DCONF_VALUE ]]; then
    BOX_STATUS=$BOX_STATUS_LATEST
  else
    BOX_STATUS=$BOX_STATUS_MISSING
  fi
}

function satisfy-dconf () {
  local DCONF_PATH=$1
  local DCONF_VALUE=$2

  check-dconf "$DCONF_PATH" "$DCONF_VALUE"

  print-box-status "$DCONF_PATH"

  if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
    BOX_ACTION=$BOX_ACTION_INSTALL
    dconf write "$DCONF_PATH" \"$DCONF_VALUE\"
  else
    BOX_ACTION=$BOX_ACTION_NONE
  fi
}

function print-box-status () {
  local NAME=$1

  if [[ -t 1 ]]; then
    local COLOUR_END='\033[0m'
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'

    if [[ $BOX_STATUS = $BOX_STATUS_MISSING ]]; then
      local COLOUR=$RED
    elif [[ $BOX_STATUS = $BOX_STATUS_OUTDATED ]]; then
      local COLOUR=$YELLOW
    elif [[ $BOX_STATUS = $BOX_STATUS_LATEST ]]; then
      local COLOUR=$GREEN
    elif [[ $BOX_STATUS = $BOX_STATUS_MISMATCH ]]; then
      local COLOUR=$RED
    fi

    printf "$NAME -> $COLOUR$BOX_STATUS$COLOUR_END\n"
  else
    echo "$NAME -> $BOX_STATUS"
  fi

}
