#!/usr/bin/env bash
#
# Kernel build logic for ckbuild.
# Sourced by build/ckbuild.sh.

build() {
    mkdir -p out
    if [[ "$DO_REGEN" = "1" ]]; then
        if [[ "$DO_KSU" = "1" ]] || [[ "$DO_SUKI" = "1" ]] || [[ "$DO_XXKSU" == "1" ]]; then
             echo "ERROR: Can't regenerate with KSU argument"
             exit 1
        fi
        # Clean any existing .config to avoid picking up settings from previous builds
        rm -f out/.config
        make O=out ARCH=arm64 "$DEFCONFIG" 2>&1 | tee log.txt
    else
        FRAGMENTS="$BASE_FRAGMENT $FRAGMENT"
        [[ "$DO_KSU" == "1" ]] && FRAGMENTS="$FRAGMENTS ksu.config"
        [[ "$DO_SUKI" == "1" ]] && FRAGMENTS="$FRAGMENTS sukisu.config"
        [[ "$DO_XXKSU" == "1" ]] && FRAGMENTS="$FRAGMENTS xxksu.config"
        [ "$DROIDSPACES" = "1" ] && [ "$DO_REGEN" != "1" ] && FRAGMENTS="$FRAGMENTS droidspaces.config"
        if [[ "$CKB_CRASHKEY" == "1" ]]; then
            FRAGMENTS="$FRAGMENTS crash_key.config"
            # Append CrashKey to the ZIP name so these builds are identifiable
            ZIP_PATH="${ZIP_PATH%.zip}-CrashKey.zip"
        fi

        make O=out ARCH=arm64 "$DEFCONFIG" $FRAGMENTS 2>&1 | tee log.txt
    fi

    # Delete leftovers
    rm -f out/arch/arm64/boot/Image*
    rm -f out/arch/arm64/boot/dtbo*
    rm -f log.txt

    export LLVM=1 LLVM_IAS=1
    export ARCH=arm64

    if [[ "$DO_MENUCONFIG" == "1" ]]; then
        make O=out menuconfig
    fi

    if [[ "$DO_REGEN" = "1" ]]; then
        cp -f out/.config "arch/arm64/configs/$DEFCONFIG"
        echo "INFO: Configuration regenerated. Check the changes!"
        exit 0
    fi

    # Disallow Release builds when CrashKey testing is enabled
    if [[ "$CKB_CRASHKEY" == "1" && "$IS_RELEASE" == "1" ]]; then
        echo "ERROR: CrashKey builds cannot be Release builds"
        exit 1
    fi

    if [[ "$IS_RELEASE" == "1" ]]; then
        VERSION_STR="\"-Floppy-$FK_VER-$CK_TYPE_SHORT-release\""
        VERSION_NOAUTO=1
    else
        VERSION_STR="\"-Floppy-$FK_VER-$CK_TYPE_SHORT\""
    fi

    if [[ "$CKB_CRASHKEY" == "1" ]]; then
        # Append CrashKey to the LOCALVERSION string
        VERSION_STR="${VERSION_STR%\"}-CrashKey\""
    fi

    scripts/config --file "$KDIR/out/.config" --set-val LOCALVERSION "$VERSION_STR"

    if [[ "$VERSION_NOAUTO" == "1" ]]; then
        scripts/config --file "$KDIR/out/.config" --disable LOCALVERSION_AUTO
    fi

    if [[ "$DO_FLTO" == "1" ]]; then
        scripts/config --file "$KDIR/out/.config" --enable CONFIG_LTO_CLANG
        scripts/config --file "$KDIR/out/.config" --disable CONFIG_THINLTO
    fi

    ## Start the build
    echo -e "\nINFO: Starting compilation...\n"

    if [[ "$USE_CCACHE" == "1" ]]; then
        make -j$(nproc --all) O=out \
        CC="ccache clang" \
        CROSS_COMPILE="$CCARM64_PREFIX" \
        CROSS_COMPILE_ARM32="$CCARM_PREFIX" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        READELF="llvm-readelf" \
        OBJSIZE="llvm-size" \
        OBJDUMP="llvm-objdump" \
        OBJCOPY="llvm-objcopy" \
        STRIP="llvm-strip" \
        NM="llvm-nm" \
        AR="llvm-ar" \
        HOSTAR="llvm-ar" \
        HOSTAS="llvm-as" \
        HOSTNM="llvm-nm" \
        LD="ld.lld" 2>&1 | tee log.txt
    else
        make -j$(nproc --all) O=out \
        CC="clang" \
        CROSS_COMPILE="$CCARM64_PREFIX" \
        CROSS_COMPILE_ARM32="$CCARM_PREFIX" \
        CLANG_TRIPLE="aarch64-linux-gnu-" \
        READELF="llvm-readelf" \
        OBJSIZE="llvm-size" \
        OBJDUMP="llvm-objdump" \
        OBJCOPY="llvm-objcopy" \
        STRIP="llvm-strip" \
        NM="llvm-nm" \
        AR="llvm-ar" \
        HOSTAR="llvm-ar" \
        HOSTAS="llvm-as" \
        HOSTNM="llvm-nm" \
        LD="ld.lld" 2>&1 | tee log.txt
    fi
}