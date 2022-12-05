#!/usr/bin/env bash

REVIEWDOG_GIT_TOKEN=$1
REVIEWDOG_DIR=$2
REVIEWDOG_LVL=$3
REVIEWDOG_REPORTER=$4

# Print commands for debugging
if [[ "$RUNNER_DEBUG" = "1" ]]; then
  set -x
fi

# Fail fast on errors, unset variables, and failures in piped commands
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE}/${REVIEWDOG_DIR}" || { echo "TIZONA - Tfsec review: Terraform directory not found, skipping." ; exit 1;}

echo "TIZONA - Tfsec review: Print tfsec details ..."
tfsec_v=`tfsec --version`
echo "TIZONA - Tfsec review: Tfsec version: ${tfsec_v}"

echo 'TIZONA - Tfsec review: Running tfsec with reviewdog ...'
export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

# Allow failures now, as reviewdog handles them
set +Eeuo pipefail

# shellcheck disable=SC2086

if [ "pull_request" = "$GITHUB_EVENT_NAME" ]; then
  TFSEC_DIRS=$(git diff origin/${GITHUB_BASE_REF} origin/${GITHUB_HEAD_REF} --dirstat | awk -F '% ' '{print $2}')
else
  TFSEC_DIRS="."
fi

for dir in $TFSEC_DIRS
do 
  tfsec --format=json --force-all-dirs $dir | jq -r -f "/app/to-rdjson.jq" | reviewdog -f=rdjson -name="tfsec" -reporter="${REVIEWDOG_REPORTER}" -level="${REVIEWDOG_LVL}" -fail-on-error=true 

  tfsec_return="${PIPESTATUS[0]}" reviewdog_return="${PIPESTATUS[2]}" exit_code=$?

  echo "TIZONA - Tfsec review of $dir: tfsec-return-code: ${tfsec_return}"
  echo "TIZONA - Tfsec review of $dir: reviewdog-return-code: ${reviewdog_return}"

  echo "TIZONA - Tfsec review of $dir: Tfsec exit ${exit_code}"

  if [[ ${exit_code} != *"0"* ]]; then
    echo "TIZONA - Tfsec review of $dir: exit code is not 0"
    break
  fi

done

exit ${exit_code}
