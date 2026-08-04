#!/usr/bin/env bash
#
# Upload logic for ckbuild.
# Sourced by build/ckbuild.sh.

## Telegram info variables

CAPTION_BUILD="Build info:
*Device*: \`${DEVICE} [${CODENAME}]\`
*Kernel Version*: \`${LINUX_VER}\`
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Build host*: \`${BUILD_HOST}\`
*Commit / Branch*: [($(git rev-parse HEAD | cut -c -7))]($(echo $KERNEL_URL)/commit/$(git rev-parse HEAD)) / \`$(git rev-parse --abbrev-ref HEAD)\`
*Build variant*: \`${CK_TYPE}\` / \`${BUILD_TYPE}$( [ "$DO_CLEAN" -eq 1 ] && echo " (clean)" || echo " (dirty)")\`
*Timestamp*: \`${DATE}\`
"

# Functions to send file(s) via Telegram's BOT api.
tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TELEGRAM_BOT_TOKEN}"/sendDocument \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "parse_mode=Markdown" \
        -F "disable_web_page_preview=true" \
        -F "caption=${CAPTION_BUILD}*MD5*: \`$MD5\`" &>/dev/null
}

upload() {
    if [[ "$DO_ZXZ" == "1" ]]; then
    echo -e "\n$(log_info "Uploading to 0x0.st...")\n"
    curl -F'file=@'"$ZIP_PATH" http://0x0.st || log_warn "Failed to upload build to 0x0.st (ignored)"
    fi

    if [[ "$DO_TG" == "1" ]]; then
            log_info "Uploading build to Telegram"
            tgs "$ZIP_PATH"
            log_info "Done!"
    fi
    if [[ "$LOG_UPLOAD" == "1" ]]; then
        echo -e "\n$(log_info "Uploading log to 0x0.st")\n"
        curl -F'file=@log.txt' http://0x0.st || log_warn "Failed to upload log to 0x0.st (ignored)"
    fi
    # Delete any leftover zip files
    # rm -f "$WP/FloppyKernel*zip"
}