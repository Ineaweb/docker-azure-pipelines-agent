#!/bin/bash
set -e

cd "$(dirname "$0")"

ubuntu() {
  cd ubuntu

  dirs() {
    BASE_DIR=$1
    echo "$BASE_DIR"
    while read -r DOTNET_LINE_VERSION; do
      DOTNET_VERSION=$(echo $DOTNET_LINE_VERSION | cut -d' ' -f1)
      echo "$BASE_DIR/dotnet/core/$DOTNET_VERSION"
    done < <(< derived/dotnet/core/versions sed '/^\s*#/d')
  }

  while read -r UBUNTU_VERSION; do
    echo "ubuntu/$UBUNTU_VERSION"
    while read -r AZDO_AGENT_RELEASE; do
      dirs "ubuntu/$UBUNTU_VERSION/${AZDO_AGENT_RELEASE/-/\/}"
    done < <(< versioned/releases sed '/^\s*#/d')
  done < <(< versions sed '/^\s*#/d')

  cd ..
}

ubuntu
