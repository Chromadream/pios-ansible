#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_DIR="${REPO_ROOT}/stage-ansible"
PI_GEN_DIR="${REPO_ROOT}/pi-gen"

git submodule update --init

touch "${PI_GEN_DIR}/stage2/SKIP_IMAGES"

PIGEN_OPTS="-v ${STAGE_DIR}:/stage-ansible"
QEMU_SRC=/usr/bin/qemu-aarch64-static
QEMU_DIR="${REPO_ROOT}/.qemu"
if [ "$(uname -s)" = "Darwin" ]; then
    :
elif [ -f "${QEMU_SRC}" ]; then
    mkdir -p "${QEMU_DIR}"
    cp -p "${QEMU_SRC}" "${QEMU_DIR}/qemu-aarch64-static"
    PIGEN_OPTS="${PIGEN_OPTS} -v ${QEMU_DIR}/qemu-aarch64-static:/usr/bin/qemu-aarch64:ro"
else
    echo "WARNING: ${QEMU_SRC} not found. Install qemu-user-static." 1>&2
fi

cd "${PI_GEN_DIR}"
PIGEN_DOCKER_OPTS="${PIGEN_DOCKER_OPTS:-} ${PIGEN_OPTS}" ./build-docker.sh -c "${REPO_ROOT}/config"
