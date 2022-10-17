# Container image that runs your code
FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

##################################################################
# Dependency track requirementes
##################################################################

# using --no-install-recommends to reduce image size
RUN apt-get update \
    && apt-get install --no-install-recommends -y git npm golang lsb-release default-jdk=2:1.11-72 \
    curl jq build-essential apt-transport-https unzip wget nodejs gnupg snapd \
    libc6 libgcc1 libgssapi-krb5-2 libicu66 libssl1.1 libstdc++6 zlib1g 

RUN go get github.com/ozonru/cyclonedx-go/cmd/cyclonedx-go && cp /root/go/bin/cyclonedx-go /usr/bin/

RUN curl -sS https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.24.1/cyclonedx-linux-x64 -o /usr/bin/cyclonedx-cli && \
    chmod +x /usr/bin/cyclonedx-cli


##################################################################
# Secrets leaks requirements
##################################################################

# Reviewdog
# https://github.com/reviewdog/reviewdog
# Install the latest version. (Install it into ./bin/ by default).

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s

# Gitleaks
RUN curl -L https://github.com/zricethezav/gitleaks/releases/download/v8.12.0/gitleaks_8.12.0_linux_x64.tar.gz -L -O \
    && tar -zxvf gitleaks_8.12.0_linux_x64.tar.gz && \
    rm gitleaks_8.12.0_linux_x64.tar.gz


##################################################################
# Sonarqube requirements
##################################################################

RUN mkdir /downloads/sonarqube -p && \
    cd /downloads/sonarqube && \
    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.7.0.2747-linux.zip && \
    unzip sonar-scanner-cli-4.7.0.2747-linux.zip && \
    mv sonar-scanner-4.7.0.2747-linux /var/opt && \
    rm sonar-scanner-cli-4.7.0.2747-linux.zip


ENV PATH $PATH:/var/opt/sonar-scanner-4.7.0.2747-linux/bin/

##################################################################
# Configuration checker requirements
##################################################################

# Tfsec
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install trivy -y
    
    


##################################################################
# Dependency check requirementes
##################################################################

RUN wget https://github.com/jeremylong/DependencyCheck/releases/download/v7.2.1/dependency-check-7.2.1-release.zip  && \
    unzip dependency-check-7.2.1-release.zip && \
    mv dependency-check /var/opt && \
    rm dependency-check-7.2.1-release.zip 

ENV PATH $PATH:/var/opt/dependency-check/bin/
ENV JAVA_HOME="/lib/jvm/java-11-openjdk-amd64"

RUN /var/opt/dependency-check/bin/dependency-check.sh --updateonly

# Copies your code file from your action repository to the filesystem path `/` of the container

COPY entrypoint.sh /entrypoint.sh
COPY dependency_track.sh /dependency_track.sh
COPY secrets_leaks.sh /secrets_leaks.sh
COPY code.sh /code.sh
COPY config.sh /config.sh
COPY tfsec_check.sh /tfsec_check.sh
COPY trivy_config.sh /trivy_config.sh
COPY trivy_repo.sh /trivy_repo.sh
COPY to-rdjson.jq /to-rdjson.jq

RUN chmod +x /*.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]