#!/bin/sh

repo forall -c git reset --hard HEAD
repo forall -c git clean -fdx

. build/envsetup.sh
#lunch aosp_munch-bp1a-user
breakfast munch user
mka bacon
