#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

MODULES=()
source modules.sh

function apt-package-installed () {
  PACKAGE=$1
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PACKAGE|grep "install ok installed")
  if [ "" == "$PKG_OK" ]; then
    return 1
  fi
  return 0
}

function install_module () {
  module=$1
  if eval "gab__check-$module"; then
    echo "$module already installed"
  else
    echo "Installing $module"
    eval "gab__install-$module"
  fi
}

for module in ${MODULES[@]};
do
  install_module $module
done
