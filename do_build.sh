#!/bin/bash
set -e

# Configuration
all_devs=("ginkgo" "laurel_sprout") # Define devices for "all" target
ck_script="ckbuild.sh"              # Name of main script

rm -r include/config &>/dev/null || true
export WP=${WP:-$(realpath "${PWD}/../")}

if [[ -z "$1" ]]; then
    echo "ERROR: Please specify device or 'all' to build!"
    exit 1
fi

arg_target="$1"
shift
arg_opts="$*" # Original options

# --- Parse options ---
f_param=false
build_opts="$arg_opts"
if [[ "$arg_opts" == *f* ]]; then
    f_param=true
    build_opts="${arg_opts//f/}"
fi

# Check for clean param
c_param=false
if [[ "$arg_opts" == *c* ]]; then
    c_param=true
fi

# Check for KSU param
k_param=false
if [[ "$build_opts" == *k* ]]; then
    k_param=true
fi

first_build_done=false

run_build() {
    local dev="$1"
    local current_opts="$2"
    local effective_opts="$current_opts"

    # Apply 'c' only if globally requested AND this is the very first build of the entire batch
    if $c_param && ! $first_build_done; then
        if [[ "$effective_opts" != *c* ]]; then
            effective_opts="${effective_opts}c"
        fi
    else
        # If not the first build, or 'c' was not globally requested, remove 'c'
        effective_opts="${effective_opts//c/}"
    fi

    # Ensure 'f' is never passed down to ck_script
    effective_opts="${effective_opts//f/}"

    echo -e "==> Building target: \"$dev\" with options: \"$effective_opts\"\n"
    bash "$ck_script" "$dev" "$effective_opts"
    
    first_build_done=true # Mark that at least one build has started/completed
}

# Determine the list of devices to process
devices_to_process=()
if [[ "$arg_target" == "all" ]]; then
    echo -e "\n==> Selecting all valid targets: \"${all_devs[*]}\""
    devices_to_process=("${all_devs[@]}")
else
    devices_to_process=("$arg_target")
fi

# Phase 1: KernelSU Builds
if $k_param; then
    for device_name in "${devices_to_process[@]}"; do
        run_build "$device_name" "$build_opts"
    done
fi

# Phase 2: Vanilla Builds
if ! $k_param || ($f_param && $k_param); then
    vanilla_opts="${build_opts//k/}"
    for device_name in "${devices_to_process[@]}"; do
        run_build "$device_name" "$vanilla_opts"
    done
fi

echo "All targets built."