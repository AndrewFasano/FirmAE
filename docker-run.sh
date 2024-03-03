#!/bin/bash

set -eu


if [ $# -lt 1 ]; then
  echo "Usage: $0 <path to firmware file or dir>"
  exit 1
fi

IN_PATH=$(readlink -f "$1")
IN_DIR=$(dirname "$IN_PATH")
IN_FILE=$(basename "$IN_PATH")

if [ -d "${IN_PATH}" ]; then
    # Process the whole dir
    IN_DIR="${IN_PATH}"
    IN_FILE=""
fi



docker run --rm -it -v /dev:/dev \
    -v ${IN_DIR}:/work/firmwares \
    --privileged \
    fcore \
        bash -c "\
            cd /work/FirmAE && \
            sudo service postgresql start && \
            ./run.sh -c brand \"/work/firmwares/${IN_FILE}\"; \
            echo -n "RESULT:"; \
            cat ./scratch/1/result \
            "