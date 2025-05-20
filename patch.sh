#!/bin/sh

patch_all() {
  patch -p1 --no-backup-if-mismatch < xxxx.patch
}

patch_all
