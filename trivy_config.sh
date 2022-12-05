#!/usr/bin/env bash

TRIVY_SEVERITY=$1
TRIVY_TIMEOUT=$2
REVIEWDOG_GIT_TOKEN=$3
TRIVY_OUTPUT='trivy-results-config.sarif'
ARGS=""
TIMEOUT=""

set -e

export REVIEWDOG_GITHUB_API_TOKEN="${REVIEWDOG_GIT_TOKEN}"

if [ $TRIVY_SEVERITY ];then
  ARGS="$ARGS --severity $TRIVY_SEVERITY"
fi

if [ $TRIVY_TIMEOUT ];then
  TIMEOUT="$TIMEOUT --timeout $TRIVY_TIMEOUT"
fi

echo ${GITHUB_BASE_REF}
echo ${GITHUB_HEAD_REF} 
TRIVY_DIRS=$(git diff origin/${GITHUB_BASE_REF} origin/${GITHUB_HEAD_REF} --dirstat | awk -F '% ' '{print $2}')

for dir in $TRIVY_DIRS
do 
  echo "TIZONA - Trivy configuration analysis of $dir: Building SARIF config report"
  trivy --quiet ${TIMEOUT} config --format sarif --output ${TRIVY_OUTPUT} ${ARGS} $dir

  echo "TIZONA - Trivy configuration analysis of $dir: Upload trivy config scan result to Github"
  set +Eeuo pipefail

  jq '.runs[0].results[] | "\(.level):\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.endLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"' < ${TRIVY_OUTPUT} | sed 's/"//g' |  reviewdog -efm="%t%.%+:%f:%l:%c: %m" -reporter=github-pr-check -fail-on-error=true

  reviewdog_return="${PIPESTATUS[2]}" exit_code=$?
  echo "TIZONA - Trivy configuration analysis of $dir: reviewdog-return-code: ${reviewdog_return}"
  echo "TIZONA - Trivy configuration analysis of $dir: Trivy config exit ${exit_code}"

  if [[ ${exit_code} != *"0"* ]]; then
    echo "TIZONA - Trivy configuration analysis of $dir: exit code is not 0"
    break
  fi

done

exit ${exit_code}