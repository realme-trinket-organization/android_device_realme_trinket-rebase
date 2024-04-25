#!/bin/bash
#
# Copyright (C) 2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=realme_trinket
VENDOR=realme

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..
DEVICE_BLOB_ROOT="$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
            CLEAN_VENDOR=false
            ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

function blob_fixup() {
    case "${1}" in

    # Remove vtcamera for ginkgo
    vendor/etc/camera/camera_config.xml)
        gawk -i inplace '{ p = 1 } /<CameraModuleConfig>/{ t = $0; while (getline > 0) { t = t ORS $0; if (/ginkgo_vtcamera/) p = 0; if (/<\/CameraModuleConfig>/) break } $0 = t } p' "${2}"
        ;;

    vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml)
        sed -i "s/ginkgo_s5kgm1_sunny_i/ginkgo_s5kgm1_ofilm_ii/g" "${2}"
        ;;
    
    vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml)
        sed -i "s/ginkgo_s5kgm1_ofilm_ii_common/ginkgo_s5kgm1_sunny_i_common/g" "${2}"
        ;;

    vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml)
        sed -i "s/ginkgo_s5kgm1_ofilm_ii_postproc/ginkgo_s5kgm1_sunny_i_postproc/g" "${2}"
        ;;

    vendor/bin/mlipayd@1.1)
        patchelf --remove-needed vendor.xiaomi.hardware.mtdservice@1.0.so "${2}"
        ;;

    vendor/lib64/libmlipay.so | vendor/lib64/libmlipay@1.1.so)
        patchelf --remove-needed vendor.xiaomi.hardware.mtdservice@1.0.so "${2}"
        sed -i "s|/system/etc/firmware|/vendor/firmware\x0\x0\x0\x0|g" "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false $CLEAN_VENDOR

extract "$MY_DIR"/proprietary-files.txt "$SRC" "${KANG}" --section "${SECTION}"

"$MY_DIR"/setup-makefiles.sh
