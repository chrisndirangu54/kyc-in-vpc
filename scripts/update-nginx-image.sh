#!/bin/bash

set -euo pipefail

"$(dirname "$0")/build-and-upload.sh" tradle-kyc-nginx-proxy "$(dirname "$0")/../docker/nginx"
