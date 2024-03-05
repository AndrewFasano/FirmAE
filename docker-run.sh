#!/bin/bash

set -eu

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path to firmware file or dir>"
  exit 1
fi

IN_PATH=$(readlink -f "$1")
# Define the file where results will be stored
RESULTS_FILE="docker_results.txt"

# Function to process a single file and append the result to the results file
process_file() {
    local file_path="$1"
    local in_dir=$(dirname "$file_path")
    local in_file=$(basename "$file_path")
    local result_file="${in_dir}/${in_file}_result.txt"


    docker run --rm \
        --privileged \
        -v "${in_dir}:/work/firmwares" \
        fcore \
            bash -c "\
                cd /work/FirmAE && \
                ./run.sh -c brand \"/work/firmwares/${in_file}\"; \
                " #| tee $result_file
    #grep 'RESULT: ' $result_file | cut -d' ' -f1 >> $RESULTS_FILE # This could get clobbered with races
}

export -f process_file
export RESULTS_FILE


if [ -d "${IN_PATH}" ]; then
  # Find all files in the directory and pass them to xargs for parallel processing
  find "${IN_PATH}" -type f -print0 | xargs -0 -I {} -P $(nproc) bash -c 'process_file "$@"' _ {}
else
  # Process a single file
  process_file "${IN_PATH}"
fi

