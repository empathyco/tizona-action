#!/usr/bin/env bash

set -e

REVIEWDOG_GIT_TOKEN=${1}
REVIEWDOG_DIR=${2}
REVIEWDOG_LVL=${3}
REVIEWDOG_REPORTER=${4}

TRIVY_CONFIG_SCANREF=${5}
TRIVY_REPO_SCANREF=${6}
TRIVY_REPO_IGNORE=${7}
TRIVY_REPO_VULN=${8}
TRIVY_SEVERITY=${9}
TRIVY_TIMEOUT=${10}

echo "TIZONA - Configuration analysis: Run Tfsec"
/bin/bash /app/tfsec_check.sh ${REVIEWDOG_GIT_TOKEN} ${REVIEWDOG_DIR} ${REVIEWDOG_LVL} ${REVIEWDOG_REPORTER}

echo "TIZONA - Configuration analysis: Run Trivy for config"
/bin/bash /app/trivy_config.sh ${TRIVY_CONFIG_SCANREF} ${TRIVY_SEVERITY} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}

echo "TIZONA - Configuration analysis: Run Trivy for repository"
/bin/bash /app/trivy_repo.sh  ${TRIVY_REPO_SCANREF} ${TRIVY_REPO_IGNORE} ${TRIVY_SEVERITY} ${TRIVY_REPO_VULN} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}