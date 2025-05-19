#!/bin/bash

# Delete temp files to prevent build system from complaining
rm -r include/config &>/dev/null
# Wrap to ckbuild.sh
export WP=${WP:-$(realpath $PWD/../)}

if [[ -z "$1" ]]; then
    echo -e "\nERROR: Please specify device to build!\n"
    echo "Usage: $0 <device> [build options]"
    exit 1
fi

bash ckbuild.sh "$@"
