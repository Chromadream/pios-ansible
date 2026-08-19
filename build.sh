#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_DIR="${REPO_ROOT}/stage-custom"
PI_GEN_DIR="${REPO_ROOT}/pi-gen"

git submodule update --init

touch "${PI_GEN_DIR}/stage2/SKIP_IMAGES"

PIGEN_OPTS="-v ${STAGE_DIR}:/stage-custom"

cd "${PI_GEN_DIR}"
PIGEN_DOCKER_OPTS="${PIGEN_DOCKER_OPTS:-} ${PIGEN_OPTS}" ./build-docker.sh -c "${REPO_ROOT}/config"
