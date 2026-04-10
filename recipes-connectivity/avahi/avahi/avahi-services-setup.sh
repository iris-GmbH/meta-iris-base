#!/bin/sh

set -eu

target_dir="/mnt/iris/avahi/services"
seed_file="/usr/share/avahi/irma-provider.service"
target_file="${target_dir}/irma-provider.service"

mkdir -p "${target_dir}"

if [ ! -e "${target_file}" ]; then
    cp "${seed_file}" "${target_file}"
    chmod 0644 "${target_file}"
fi
