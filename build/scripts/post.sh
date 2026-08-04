#!/usr/bin/env bash
#
# Post-build verification + flashable zip packaging for ckbuild.
# Sourced by build/ckbuild.sh.

post_build() {
    ## Check if the kernel binaries were built.
    if [[ "$CODENAME" == "unified" ]]; then
        if [[ -f "$OUT_IMAGE" ]] && [[ -f "$DTBO_TMP/dtbo-ginkgo.img" ]] && [[ -f "$DTBO_TMP/dtbo-laurel_sprout.img" ]] && [[ -f "$OUT_DTB_GINKGO" ]] && [[ -f "$OUT_DTB_LAUREL" ]]; then
            echo -e "\n$(log_info "Kernel compiled succesfully! Zipping up...")"
        else
            echo -e "\n$(log_err "Kernel files not found! Compilation failed?")"
            echo -e "\n$(log_info "Uploading log to 0x0.st")\n"
            curl -F'file=@log.txt' http://0x0.st || log_warn "Failed to upload log to 0x0.st (ignored)"
            exit 1
        fi
    elif [[ -f "$OUT_IMAGE" ]] && [[ -f "$OUT_DTBO" ]] && [[ -f "$OUT_DTB" ]]; then
        echo -e "\n$(log_info "Kernel compiled succesfully! Zipping up...")"
    else
        echo -e "\n$(log_err "Kernel files not found! Compilation failed?")"
        echo -e "\n$(log_info "Uploading log to 0x0.st")\n"
        curl -F'file=@log.txt' http://0x0.st || log_warn "Failed to upload log to 0x0.st (ignored)"
        exit 1
    fi

    # If local AK3 copy exists, assume testing.
    if [[ -d "$AK3_DIR" ]]; then
        AK3_TEST=1
        echo -e "\n$(log_info "AK3_TEST flag set because local AnyKernel3 dir was found")"
    else
        if ! git clone -q --depth=1 -b "$AK3_BRANCH" "$AK3_URL" "$AK3_DIR"; then
            echo -e "\n$(log_err "Failed to clone AnyKernel3!")"
            exit 1
        fi
    fi

    ## Copy the built binaries
    cp "$OUT_IMAGE" "$AK3_DIR"
    if [[ "$CODENAME" == "mitrinket" ]]; then
        # Device-named DTBOs (required in mitrinket unified builds)
        cp "$OUT_DTBO" "$AK3_DIR/dtbo-ginkgo.img"
        cp "$DTBO_TMP/dtbo-laurel_sprout.img" "$AK3_DIR/dtbo-laurel_sprout.img"
        cp "$OUT_DTB_GINKGO" "$AK3_DIR/dtb-ginkgo"
        cp "$OUT_DTB_LAUREL" "$AK3_DIR/dtb-laurel_sprout"
    else
        cp "$OUT_DTBO" "$AK3_DIR"
        cp "$OUT_DTB" "$AK3_DIR/dtb"
    fi
    rm -f *zip

    ## Prepare kernel flashable zip
    cd "$AK3_DIR"
    git checkout "$AK3_BRANCH" &> /dev/null
    zip -r9 "$ZIP_PATH" * -x '*.git*' README.md *placeholder
    cd ..
    rm -rf "$AK3_DIR"
    echo -e "\n$(log_info "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !")"
    echo "Zip: $ZIP_PATH"
    echo " "
    if [[ "$AK3_TEST" == "1" ]]; then
        echo -e "\n$(log_info "Skipping deletion of AnyKernel3 dir because test flag is set")"
    else
        rm -rf "$AK3_DIR"
    fi
    cd "$KDIR"
}

clean_tmp() {
    echo -e "$(log_info "Cleaning after build...")"
    rm -f "$OUT_IMAGE"
    rm -f "$OUT_DTBO"
    rm -rf "$DTBO_TMP"
}