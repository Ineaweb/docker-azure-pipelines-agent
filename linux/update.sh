#!/bin/bash
set -e

registry=pmorisseau
name=azdo-agent

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -r|--registry)
            if [ "$2" ]; then
                registry=$2
                echo "Registry: '$registry'"
                shift
            else
                die 'ERROR: "--registry" requires a non-empty option argument.'
            fi
            ;;
        -n|--name)
            if [ "$2" ]; then
                name=$2
                echo "Name: '$name'"
                shift
            else
                die 'ERROR: "--name" requires a non-empty option argument.'
            fi
            ;;
        --)                     # End of all options.
            shift
            break
            ;;
        *)                      # unknown option
            POSITIONAL+=("$1")  # save it in an array for later
            shift               # past argument
            ;;
    esac

    shift
done
set -- "${POSITIONAL[@]}"       # restore positional parameters


cd "$(dirname "$0")"

BASE_PATH=../output/ubuntu/

ubuntu() {
  cd ubuntu

  update() {
    UBUNTU_VERSION=$1
    AZDO_AGENT_VERSION=$2
    AZDO_AGENT_ON_ACI=$3

    echo "    running update for: $UBUNTU_VERSION $AZDO_AGENT_VERSION"

    TEMPLATE_DIR=.
    TARGET_DIR=$BASE_PATH$UBUNTU_VERSION
    AZDO_AGENT_TAG=ubuntu-$UBUNTU_VERSION
    if [ -n "$AZDO_AGENT_VERSION" ]; then
      if [ "$AZDO_AGENT_ON_ACI" == "0" ]; then
        TEMPLATE_DIR=versioned
        TARGET_DIR=$TARGET_DIR/azdo
        AZDO_AGENT_TAG=$AZDO_AGENT_TAG-azdo
      fi
      if [ "$AZDO_AGENT_ON_ACI" == "1" ]; then
        TEMPLATE_DIR=versioned_for_aci
        TARGET_DIR=$TARGET_DIR/aci-azdo
        AZDO_AGENT_TAG=$AZDO_AGENT_TAG-aci-azdo
      fi
    fi   

    echo "        Target: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    
    sed \
      -e s/'$\[DOCKER_REGISTRY\]'/"$registry"/g \
      -e s/'$\[DOCKER_NAME\]'/"$name"/g \
      -e s/'$\[UBUNTU_VERSION\]'/"$UBUNTU_VERSION"/g \
      -e s/'$\[AZDO_AGENT_VERSION\]'/"$AZDO_AGENT_VERSION"/g \
      "$TEMPLATE_DIR/dockerfile.template" > "$TARGET_DIR/dockerfile"

    if ls -d $TEMPLATE_DIR/*.sh > /dev/null 2>&1; then
      cp $TEMPLATE_DIR/*.sh "$TARGET_DIR"
    fi

    if [ -n "$AZDO_AGENT_VERSION" ]; then
      while read -r DOTNET_LINE_VERSION; do
        DOTNET_VERSION=$(echo $DOTNET_LINE_VERSION | cut -d' ' -f1)
        DOTNET_SDK_VERSION=$(echo $DOTNET_LINE_VERSION | cut -d' ' -f2)
        DOTNET_CORE_DIR=$TARGET_DIR/dotnet/$DOTNET_VERSION
        mkdir -p "$DOTNET_CORE_DIR"
        
        sed \
          -e s/'$\[DOCKER_REGISTRY\]'/"$registry"/g \
          -e s/'$\[DOCKER_NAME\]'/"$name"/g \
          -e s/'$\[AZDO_AGENT_TAG\]'/"$AZDO_AGENT_TAG"/g \
          -e s/'$\[DOTNET_VERSION\]'/"$DOTNET_VERSION"/g \
          -e s/'$\[DOTNET_SDK_VERSION\]'/"$DOTNET_SDK_VERSION"/g \
          derived/dotnet/dockerfile.template > "$DOTNET_CORE_DIR/dockerfile"
      done < <(< derived/dotnet/versions sed '/^\s*#/d')
    fi
    echo "        done."
  }

  echo "starting update..."
  while read -r UBUNTU_VERSION; do
    rm -rf "$BASE_PATH$UBUNTU_VERSION"
    update "$UBUNTU_VERSION"
    while read -r AZDO_AGENT_VERSION; do
      update "$UBUNTU_VERSION" "$AZDO_AGENT_VERSION" "0"
    done < <(< versioned/releases sed '/^\s*#/d')
    while read -r AZDO_AGENT_VERSION; do
      update "$UBUNTU_VERSION" "$AZDO_AGENT_VERSION" "1"
    done < <(< versioned_for_aci/releases sed '/^\s*#/d')
  done < <(< versions sed '/^\s*#/d')

  cd ..
  echo "    done."
}

ubuntu
