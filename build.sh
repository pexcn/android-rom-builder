#!/bin/bash
# shellcheck disable=SC1091

PROG_NAME="${0##*/}"

_print_usage() {
  cat <<EOF
android rom build script.

USAGE:
    $PROG_NAME [OPTIONS]

OPTIONS:
    -d, --device [CODE_NAME]         Device code name.
    -v, --variant [BUILD_VARIANT]    Build variant.
    -c, --crave                      Whether to Build on foss.crave.io.
    -h, --help                       Show this help message then exit.
EOF
}

_repo_sync() {
  if [ "$CRAVE" = 1 ]; then
    /opt/crave/resync.sh
  else
    repo sync --current-branch --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j"$(nproc --all)"
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d | --device)
        DEVICE="$2"
        shift 2
        ;;
      -v | --variant)
        VARIANT="$2"
        shift 2
        ;;
      -m | --manifest)
        MANIFEST_URL="${2%:*}"
        MANIFEST_BRANCH="${2##*:}"
        shift 2
        ;;
      -c | --crave)
        CRAVE=1
        shift 1
        ;;
      -h | --help)
        _print_usage
        exit 0
        ;;
      *)
        echo "unknown option: $1"
        exit 1
        ;;
    esac
  done
}

build_rom() {
  # reset changes
  repo forall -c git reset --hard HEAD >/dev/null
  repo forall -c git clean -fdx >/dev/null

  # clone local_manifests
  rm -rf .repo/local_manifests
  git clone "$MANIFEST_URL" -b "$MANIFEST_BRANCH" .repo/local_manifests
  _repo_sync

  # # apply patch
  # git clone https://github.com/pexcn/android-rom-builder.git -b pixelos-15
  # cd android-rom-builder
  # ./patch.sh ..
  # cd -

  if [ "$CRAVE" = 1 ]; then
    export TZ=${TZ:-Asia/Taipei}
    export BUILD_USERNAME=${BUILD_USERNAME:-pexcn}
    export BUILD_HOSTNAME=${BUILD_HOSTNAME:-crave}
  fi

  . build/envsetup.sh
  #lunch aosp_munch-bp1a-userdebug
  breakfast "$DEVICE" "$VARIANT"
  mka bacon
}

parse_args "$@"
build_rom
