#!/bin/bash

set -euo pipefail

./scripts/build_and_upload.sh trueface-spoof docker/trueface-spoof &
./scripts/build_and_upload.sh trueface-dash docker/trueface-dash &

wait
