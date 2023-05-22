#!/usr/bin/env bash

set -e

echo "lint"

set +e

hadolint -t error ./Dockerfile

exit_code=$?

echo "TIZONA - Docker lint: Hadolint exit code: ${exit_code}"
exit ${exit_code}
