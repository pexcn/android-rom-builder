#!/bin/bash
# shellcheck disable=SC1091

PROG_NAME="${0##*/}"

_print_usage() {
  cat <<EOF
android rom build script.

USAGE:
    $PROG_NAME [OPTIONS]

OPTIONS:
    -d, --device <CODE_NAME>           Device code name.
    -v, --variant <BUILD_VARIANT>      Build variant.
    -m, --manifest [GIT_URL:BRANCH]    Local manifests git url and branch.
    -p, --patchset [GIT_URL:BRANCH]    Patchset git url and branch.
    -r, --reset                        Whether to reset the sources before starting build.
    -h, --help                         Show this help message then exit.
EOF
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
        MANIFEST="$2"
        shift 2
        ;;
      -p | --patchset)
        PATCHSET="$2"
        shift 2
        ;;
      -r | --reset)
        RESET=1
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

  # parameters checking
  if [ -z "$DEVICE" ]; then
    echo "\`-d | --device\` parameter must be specified."
    exit 1
  fi
  if [ -z "$VARIANT" ]; then
    echo "\`-v | --variant\` parameter must be specified."
    exit 1
  fi
  if [ "$(awk -F: '{print NF-1}' <<<"$MANIFEST")" -lt 2 ]; then
    echo "\`-m | --manifest\` parameter is invalid."
    exit 1
  fi
  if [ "$(awk -F: '{print NF-1}' <<<"$PATCHSET")" -lt 2 ]; then
    echo "\`-p | --patchset\` parameter is invalid."
    exit 1
  fi
}

build_rom() {
  # reset changes
  if [ "$RESET" = 1 ]; then
    repo forall -c git reset --hard HEAD >/dev/null
    repo forall -c git clean -fdx >/dev/null
  fi

  # clone local_manifests
  if [ -n "$MANIFEST" ]; then
    rm -rf .repo/local_manifests
    local manifest_url="${MANIFEST%:*}"
    local manifest_branch="${MANIFEST##*:}"
    git clone "$manifest_url" -b "$manifest_branch" .repo/local_manifests || exit 1
  fi

  # repo sync
  if [ "$DCDEVSPACE" = 1 ]; then
    /opt/crave/resync.sh
  else
    repo sync --current-branch --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j"$(nproc --all)"
  fi

  # apply patchset
  if [ -n "$PATCHSET" ]; then
    rm -rf .patchset
    local patchset_url="${PATCHSET%:*}"
    local patchset_branch="${PATCHSET##*:}"
    git clone "$patchset_url" -b "$patchset_branch" .patchset || exit 1
    ./.patchset/patch.sh .
  fi

  if [ "$DCDEVSPACE" = 1 ]; then
    export TZ=${TZ:-Asia/Taipei}
    export BUILD_USERNAME=${BUILD_USERNAME:-pexcn}
    export BUILD_HOSTNAME=${BUILD_HOSTNAME:-crave}
  fi

  # start build
  . build/envsetup.sh
  breakfast "$DEVICE" "$VARIANT"
  mka bacon
}

parse_args "$@"
build_rom
