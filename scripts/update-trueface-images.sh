#!/bin/bash

set -euo pipefail

"$(dirname $0)/build-and-upload.sh" trueface-spoof docker/trueface-spoof &
"$(dirname $0)/build-and-upload.sh" trueface-dash docker/trueface-dash &

wait
