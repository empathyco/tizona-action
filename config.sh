#!/usr/bin/env bash

ACTION_MODE=${1}

if [[ ${ACTION_MODE} == *"false"* ]]; then
  set -e
fi

REVIEWDOG_GIT_TOKEN=${2}
TRIVY_REPO_IGNORE=${3}
TRIVY_REPO_VULN=${4}
TRIVY_SEVERITY=${5}
TRIVY_TIMEOUT=${6}

if [ "pull_request" = "$GITHUB_EVENT_NAME" ]; then
  echo "TTIZONA - Configuration analysis: Trivy configuration enabled for Pull Requests"

  echo "TIZONA - Configuration analysis: Run Trivy for config"
  /bin/bash /app/trivy_config.sh ${TRIVY_SEVERITY} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}

  echo "TIZONA - Configuration analysis: Run Trivy for repository"
  /bin/bash /app/trivy_repo.sh ${TRIVY_REPO_IGNORE} ${TRIVY_SEVERITY} ${TRIVY_REPO_VULN} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}
else
  echo "TTIZONA - Configuration analysis: Trivy configuration only available for Pull Requests. Skipping"
fi
