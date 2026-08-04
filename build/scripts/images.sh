#!/usr/bin/env bash
#
# DTBO image build for ckbuild.
# Sourced by build/ckbuild.sh.

dtbo_build() {
    echo -e "\n$(log_info "Building DTBO image...")"
    mkdir -p "$DTBO_TMP"
    local IN_DTBO=""
    case "$CODENAME" in
        ginkgo)
            IN_DTBO="$IN_DTBO_GINKGO"
            python3 "$KDIR/scripts/dtc/libfdt/mkdtboimg.py" create "$OUT_DTBO" --custom0=0x00000000 --custom1=0x00000000 --page_size=4096 "$IN_DTBO"
            ;;
        laurel_sprout)
            IN_DTBO="$IN_DTBO_LAUREL"
            python3 "$KDIR/scripts/dtc/libfdt/mkdtboimg.py" create "$OUT_DTBO" --custom0=0x00000000 --custom1=0x00000000 --page_size=4096 "$IN_DTBO"
            ;;
        mitrinket)
            python3 "$KDIR/scripts/dtc/libfdt/mkdtboimg.py" create "$DTBO_TMP/dtbo-ginkgo.img" --custom0=0x00000000 --custom1=0x00000000 --page_size=4096 "$IN_DTBO_GINKGO"
            python3 "$KDIR/scripts/dtc/libfdt/mkdtboimg.py" create "$DTBO_TMP/dtbo-laurel_sprout.img" --custom0=0x00000000 --custom1=0x00000000 --page_size=4096 "$IN_DTBO_LAUREL"
            OUT_DTBO="$DTBO_TMP/dtbo-ginkgo.img"
            ;;
        *)
            log_err "Unknown device for DTBO build!"
            exit 1
            ;;
    esac
}