#!/bin/bash

set -e

while getopts "a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:" o; do
   case "${o}" in
       a)
         export DTRACK_ENABLE=${OPTARG}
       ;;
       b)
         export DTRACK_URL=${OPTARG}
       ;;
       c)
         export DTRACK_KEY=${OPTARG}
       ;;
       d)
         export DTRACK_LANGUAGE=${OPTARG}
       ;;
       e)
         export DTRACK_DIR=${OPTARG}
       ;;
       f)
         export CODE_ENABLE=${OPTARG}
       ;;
       g)
         export SONAR_SOURCES=${OPTARG}
       ;;
       h)
         export SONAR_HOST=${OPTARG}
       ;;
       i)
         export SONAR_LOGIN=${OPTARG}
       ;;
       j)
         export CONFIG_ENABLE=${OPTARG}
       ;;
       k)
         export SECRETS_ENABLE=${OPTARG}
       ;;
       l)
         export REVIEWDOG_GIT_TOKEN=${OPTARG}
       ;;
       m)
         export REVIEWDOG_DIR=${OPTARG}
       ;;
       n)
         export REVIEWDOG_LVL=${OPTARG}
       ;;
       o)
         export REVIEWDOG_REPORTER=${OPTARG}
       ;;
       p)
         export REVIEWDOG_FAIL=${OPTARG}
       ;;
       q)
         export DEPCHECK_PROJECT=${OPTARG}
       ;;
       r)
         export DEPCHECK_PATH=${OPTARG}
       ;;
       s)
         export DEPCHECK_FORMAT=${OPTARG}
       ;;
       t)
         export TRIVY_CONFIG_SCANREF=${OPTARG}
       ;;
       u)
         export TRIVY_CONFIG_SEVERITY=${OPTARG}
       ;;
       v)
         export TRIVY_REPO_SCANREF=${OPTARG}
       ;;
       w)
         export TRIVY_REPO_IGNORE=${OPTARG}
       ;;
       x)
         export TRIVY_REPO_SEVERITY=${OPTARG}
       ;;
       y)
         export TRIVY_REPO_VULN=${OPTARG}
       ;;
       z)
         export TRIVY_TIMEOUT=${OPTARG}
       ;;
  esac
done

echo "Starting security checks"

if [[ ${DTRACK_ENABLE} == *"true"* ]]; then
    
    DTRACK_ARGS=""

    if [ $DTRACK_URL ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_URL"
    else
      echo "Dependency Track requires URL of OWASP Dependency Track REST API. Exit"
      exit 1
    fi

    if [ $DTRACK_KEY ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_KEY"
    else
      echo "Dependency Track requires key to access OWASP Dependency Track REST API. Exit"
      exit 1
    fi

    if [ $DTRACK_LANGUAGE ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_LANGUAGE"
    else
      echo "Dependency Track requires programming language to review. Exit"
      exit 1
    fi

    if [ $DTRACK_DIR ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_DIR"
    else
      echo "Dependency Track specific directory. Exit"
      exit 1
    fi

    echo "Run Dependency Track action"
    /bin/bash /app/dependency_track.sh $DTRACK_ARGS

else
    echo "Skip Dependency Track action"
fi

if [[ ${CODE_ENABLE} == *"true"* ]]; then

    CODE_ARGS=""

    if [ $DEPCHECK_PROJECT ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_PROJECT"
    else
      echo "Dependency Check requires project review. Exit"
      exit 1
    fi

    if [ $DEPCHECK_PATH ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_PATH"
    else
      echo "Dependency Check requires path review. Exit"
      exit 1
    fi

    if [ $DEPCHECK_FORMAT ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_FORMAT"
    else
      echo "Dependency Check requires output format. Exit"
      exit 1
    fi

    if [ $SONAR_SOURCES ];then
      CODE_ARGS="$CODE_ARGS $SONAR_SOURCES"
    fi

    if [ $SONAR_HOST ];then
      CODE_ARGS="$CODE_ARGS $SONAR_HOST"
    fi

    if [ $SONAR_LOGIN ];then
      CODE_ARGS="$CODE_ARGS $SONAR_LOGIN"
    fi

    echo "Run code check action"
    /bin/bash /app/code.sh $CODE_ARGS

else
    echo "Skip code check action"
fi

if [[ ${CONFIG_ENABLE} == *"true"* ]]; then
    echo "Run configuration check action"

    REVIEWDOG_ARGS=""

    if [ $REVIEWDOG_GIT_TOKEN ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_GIT_TOKEN"
    else
      echo "ReviewDog requires GitHub token. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_DIR ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_DIR"
    else
      echo "ReviewDog requires path to review. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_LVL ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_LVL"
    else
      echo "ReviewDog requires level. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_REPORTER ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_REPORTER"
    else
      echo "ReviewDog requires reporter of reviewdog command [github-pr-check,github-pr-review]. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_FAIL ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_FAIL"
    else
      echo "ReviewDog requires exit code for reviewdog when errors are found [true,false]. Exit"
      exit 1
    fi


    TRIVY_CONFIG_ARGS=""

    if [ $TRIVY_CONFIG_SCANREF ];then
      TRIVY_CONFIG_ARGS="$TRIVY_CONFIG_ARGS $TRIVY_CONFIG_SCANREF"
    else
      echo "Trivy requires path to scan configuration. Exit"
      exit 1
    fi

    if [ $TRIVY_CONFIG_SEVERITY ];then
      TRIVY_CONFIG_ARGS="$TRIVY_CONFIG_ARGS $TRIVY_CONFIG_SEVERITY"
    else
      echo "Trivy requires severity for configuration scan. Exit"
      exit 1
    fi

    TRIVY_REPO_ARGS=""

    if [ $TRIVY_REPO_SCANREF ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_SCANREF"
    else
      echo "Trivy requires path to scan repository. Exit"
      exit 1
    fi

    if [ $TRIVY_REPO_IGNORE ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_IGNORE"
    else
      echo "Trivy requires set ignore unfixed vulnerabilities [true/false]. Exit"
      exit 1
    fi

    if [ $TRIVY_REPO_SEVERITY ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_SEVERITY"
    else
      echo "Trivy requires severity for repository scan. Exit"
      exit 1
    fi

    if [ $TRIVY_REPO_VULN ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_VULN"
    else
      echo "Trivy requires comma-separated list of vulnerability types (os,library). Exit"
      exit 1
    fi

    TRIVY_COMMON_ARGS=""

    if [ $TRIVY_TIMEOUT ]; then
      TRIVY_COMMON_ARGS="$TRIVY_COMMON_ARGS $TRIVY_TIMEOUT"
    else
      echo "Trivy requires timeout (default 5m0s). Exit"
      exit 1
    fi

    /bin/bash /app/config.sh $REVIEWDOG_ARGS $TRIVY_CONFIG_ARGS $TRIVY_REPO_ARGS $TRIVY_COMMON_ARGS

else
    echo "Skip configuration check action"
fi

if [[ ${SECRETS_ENABLE} == *"true"* ]]; then

    SECRETS_ARGS=""

    if [ $REVIEWDOG_GIT_TOKEN ];then
      SECRETS_ARGS="$SECRETS_ARGS $REVIEWDOG_GIT_TOKEN"
    else
      echo "ReviewDog requires GitHub token. Exit"
      exit 1
    fi

    echo "Run secrets leaks action"
    /bin/bash /app/secrets_leaks.sh $SECRETS_ARGS
else
    echo "Skip secrets leaks action"
fi

echo "Security checks finished"
