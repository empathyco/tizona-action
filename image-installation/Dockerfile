# Container image that runs your code
FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

##################################################################
# Dependency track requirementes
##################################################################

# using --no-install-recommends to reduce image size
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y git lsb-release unzip \
    curl jq procps file build-essential apt-transport-https wget gnupg snapd \
    python-is-python3


##################################################################
# JAVA v17 installation
##################################################################

COPY --from=eclipse-temurin:17 /opt/java/openjdk /opt/java/java17


##################################################################
# Secrets leaks requirements
##################################################################

# Reviewdog
# https://github.com/reviewdog/reviewdog
# Install the latest version. (Install it into ./bin/ by default).
RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s

# Gitleaks
COPY --from=zricethezav/gitleaks /usr/bin/gitleaks /usr/bin/gitleaks

##################################################################
# Sonarqube requirements
##################################################################

COPY --from=sonarsource/sonar-scanner-cli /opt/sonar-scanner/ /opt/sonar-scanner/
ENV PATH=$PATH:/opt/sonar-scanner/bin/

##################################################################
# Configuration checker requirements
##################################################################

# Tfsec
COPY --from=aquasec/tfsec /usr/bin/tfsec /usr/bin/tfsec

# Trivy
COPY --from=aquasec/trivy /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=aquasec/trivy contrib/ contrib/

##################################################################
# Dependency Check
##################################################################

RUN wget https://github.com/jeremylong/DependencyCheck/releases/download/v7.2.1/dependency-check-7.2.1-release.zip  && \
    unzip dependency-check-7.2.1-release.zip && \
    mv dependency-check /var/opt && \
    rm dependency-check-7.2.1-release.zip 

ENV PATH=$PATH:/var/opt/dependency-check/bin/
ENV JAVA_HOME="/opt/java/java17"

RUN /var/opt/dependency-check/bin/dependency-check.sh --updateonly

##################################################################
# Docker hadolint requirements
##################################################################

COPY --chmod=777 --from=hadolint/hadolint /bin/hadolint /bin/hadolint

##################################################################
# remove unnecessary packages
##################################################################

RUN apt remove -y python2 && apt autoremove --purge -y
