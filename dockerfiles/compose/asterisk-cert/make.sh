#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-roman220/asterisk-certified:18.9-cert8-rc1}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

cd "${SCRIPT_DIR}"
docker build -t "${IMAGE_NAME}" .
docker push "${IMAGE_NAME}"
