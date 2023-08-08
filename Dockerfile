FROM ghcr.io/empathyco/tizona-action:main

WORKDIR /app

COPY entrypoint.sh entrypoint.sh
COPY secrets_leaks.sh secrets_leaks.sh
COPY code.sh code.sh
COPY config.sh config.sh
COPY trivy_config.sh trivy_config.sh
COPY trivy_repo.sh trivy_repo.sh
COPY to-rdjson.jq to-rdjson.jq
COPY docker_linter.sh docker_linter.sh

RUN chmod +x /app/*.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)

ENTRYPOINT ["/app/entrypoint.sh"]