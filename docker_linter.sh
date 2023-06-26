#!/usr/bin/env bash

set +e

DOCKERFILE_PATH=$1
DOCKERLINT_LVL=$2

echo "TIZONA - Docker linter: Running hadolint -t $DOCKERLINT_LVL $DOCKERFILE_PATH"

hadolint -t $DOCKERLINT_LVL $DOCKERFILE_PATH

exit_code=$?
echo "TIZONA - Docker linter: Hadolint exit code: ${exit_code}"
exit ${exit_code}