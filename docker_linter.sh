#!/usr/bin/env bash

set +e

DOCKERLINT_FILES=$(git diff --name-only origin/${GITHUB_BASE_REF} origin/${GITHUB_HEAD_REF})
DOCKERLINT_LVL=$1

for file in $DOCKERLINT_FILES
do
    if [[ $file == *"Dockerfile"* ]]; then
        if [ -e $file ]; then
            echo "TIZONA - Docker linter: Running hadolint -t $DOCKERLINT_LVL $file"
            hadolint -t $DOCKERLINT_LVL $DOCKERFILE_PATH
            exit_code=$?
            echo "TIZONA - Docker linter: Hadolint exit code: ${exit_code}"
            exit ${exit_code}
        else
            echo "TIZONA - Dockerfile not found"
        fi
    else
        echo "TIZONA - The Dockerfile is not among the changed files: $file"
    fi
done
