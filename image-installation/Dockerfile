FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

##################################################################
# Dependency track requirementes
##################################################################

# using --no-install-recommends to reduce image size
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y git npm golang lsb-release \
    curl jq procps file build-essential apt-transport-https unzip wget nodejs gnupg snapd \
    libc6 libgcc1 libgssapi-krb5-2 libicu66 libssl1.1 libstdc++6 zlib1g 


ENV JAVA_HOME_8=/opt/java/java8
COPY --from=eclipse-temurin:8 /opt/java/openjdk $JAVA_HOME_8
ENV JAVA_HOME=/opt/java/java17
COPY --from=eclipse-temurin:17 /opt/java/openjdk $JAVA_HOME
ENV PATH "${JAVA_HOME}/bin:${PATH}"


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


ENV PATH=$PATH:/var/opt/sonar-scanner-4.7.0.2747-linux/bin/

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

ENV PATH=$PATH:/var/opt/dependency-check/bin/
