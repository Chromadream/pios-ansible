#!/usr/bin/env bash
set -euo pipefail

QEMU_STATIC=/usr/bin/qemu-aarch64-static
BINFMT_DIR=/proc/sys/fs/binfmt_misc
BINFMT_ENTRY="${BINFMT_DIR}/qemu-aarch64"
REGISTER=':qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'"${QEMU_STATIC}"':F'

if [ ! -d "${BINFMT_DIR}" ]; then
    echo "This script is for Linux hosts only. It is not required on this system."
    exit 0
fi

if [ ! -f "${QEMU_STATIC}" ]; then
    echo "ERROR: ${QEMU_STATIC} not found. Install qemu-user-static first." 1>&2
    exit 1
fi

if [ -e "${BINFMT_ENTRY}" ]; then
    if grep -q "^interpreter ${QEMU_STATIC}$" "${BINFMT_ENTRY}"; then
        echo "${QEMU_STATIC} is already registered for arm64 emulation."
        exit 0
    fi
    echo -1 > "${BINFMT_ENTRY}"
fi

echo "${REGISTER}" > "${BINFMT_DIR}/register"

echo "Registered ${QEMU_STATIC} for arm64 emulation."
echo "This registration is not persistent. Run this script again after a reboot."
