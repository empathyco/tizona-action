# Container image that runs your code
FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

##################################################################
# Dependency track requirementes
##################################################################

# using --no-install-recommends to reduce image size
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y git npm lsb-release \
    curl jq procps file build-essential apt-transport-https wget nodejs gnupg snapd \
    libc6 libgcc1 libgssapi-krb5-2 libicu66 libssl1.1 libstdc++6 zlib1g python-is-python3


##################################################################
# JAVA 8 & 17 installation
##################################################################

COPY --from=eclipse-temurin:8 /opt/java/openjdk /opt/java/java8
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
COPY --from=tfsec/tfsec /usr/bin/tfsec /usr/bin/tfsec

# Trivy
COPY --from=aquasec/trivy /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=aquasec/trivy contrib/ contrib/


##################################################################
# remove unnecessary packages
##################################################################

RUN apt remove -y python2 && apt autoremove --purge -y