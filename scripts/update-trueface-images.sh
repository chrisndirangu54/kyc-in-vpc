#!/bin/bash

set -euo pipefail

"$(dirname $0)/build_and_upload.sh" trueface-spoof docker/trueface-spoof &
"$(dirname $0)/build_and_upload.sh" trueface-dash docker/trueface-dash &

wait
