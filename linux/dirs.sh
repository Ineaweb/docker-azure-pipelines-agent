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
      # fix unable install core-3.1 on ubuntu 22.04
      if [[ "$BASE_DIR" != "ubuntu/22.04/azdo" || "$DOTNET_VERSION" != "core-3.1" ]]; then
        echo "$BASE_DIR/dotnet/$DOTNET_VERSION"
      fi
    done < <(< derived/dotnet/versions sed '/^\s*#/d')
  }

  while read -r UBUNTU_VERSION; do
    echo "ubuntu/$UBUNTU_VERSION"
    while read -r AZDO_AGENT_RELEASE; do
      dirs "ubuntu/$UBUNTU_VERSION/azdo"
    done < <(< versioned/releases sed '/^\s*#/d')
    # while read -r AZDO_AGENT_RELEASE; do
    #   dirs "ubuntu/$UBUNTU_VERSION/aci-azdo"
    # done < <(< versioned_for_aci/releases sed '/^\s*#/d')
  done < <(< versions sed '/^\s*#/d')

  cd ..
}

ubuntu
