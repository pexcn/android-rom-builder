#!/bin/bash
# shellcheck disable=SC2155,SC2164,SC2086,SC2103

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
AOSP_DIR=$(readlink -f "$1")

check_param() {
  if [ -z "$AOSP_DIR" ]; then
    echo "Usage: $0 <aosp-source-path>"
    exit 1
  fi

  if [ ! -d "$AOSP_DIR" ]; then
    echo "$AOSP_DIR is not a directory."
    exit 1
  fi
}

apply_patches() {
  local patch_dir="$SCRIPT_DIR/patches"

  cd "$patch_dir" || exit 1
  find . -name "*.patch" | sort | while read -r patch_path; do
    local repo_path=$(dirname "$patch_path")
    local target_dir=$(readlink -f "$AOSP_DIR/$repo_path")
    local patch_file=$(readlink -f "$patch_dir/$patch_path")

    echo "Applying $patch_file to $target_dir"
    cd "$target_dir"
    patch --no-backup-if-mismatch --batch -p1 < "$patch_file" || {
      echo "Failed to apply $patch_file"
      exit 1
    }
    cd - >/dev/null
  done
  cd $SCRIPT_DIR
}

check_param
apply_patches
