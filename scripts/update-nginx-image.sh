#!/bin/bash

set -euo pipefail

"$(dirname "$0")/build_and_upload.sh" tradle-kyc-nginx-proxy "$(dirname "$0")/../docker/nginx"
