FROM mcr.microsoft.com/devcontainers/base:debian-12

ARG TARGETARCH

COPY .terraform-version .opentofu-version .task-version /tmp/versions/

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl git gnupg perl unzip; \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}" in \
      amd64) architecture="amd64" ;; \
      arm64) architecture="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    terraform_version="$(tr -d '[:space:]' < /tmp/versions/.terraform-version)"; \
    tofu_version="$(tr -d '[:space:]' < /tmp/versions/.opentofu-version)"; \
    task_version="$(tr -d '[:space:]' < /tmp/versions/.task-version)"; \
    curl --fail --location --silent --show-error --output "/tmp/terraform_${terraform_version}_linux_${architecture}.zip" "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_${architecture}.zip"; \
    curl --fail --location --silent --show-error --output /tmp/terraform_SHA256SUMS "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_SHA256SUMS"; \
    (cd /tmp && grep "terraform_${terraform_version}_linux_${architecture}.zip" terraform_SHA256SUMS | sha256sum --check --status); \
    unzip -q "/tmp/terraform_${terraform_version}_linux_${architecture}.zip" -d /usr/local/bin; \
    curl --fail --location --silent --show-error --output "/tmp/tofu_${tofu_version}_linux_${architecture}.zip" "https://github.com/opentofu/opentofu/releases/download/v${tofu_version}/tofu_${tofu_version}_linux_${architecture}.zip"; \
    curl --fail --location --silent --show-error --output /tmp/tofu_SHA256SUMS "https://github.com/opentofu/opentofu/releases/download/v${tofu_version}/tofu_${tofu_version}_SHA256SUMS"; \
    (cd /tmp && grep "tofu_${tofu_version}_linux_${architecture}.zip" tofu_SHA256SUMS | sha256sum --check --status); \
    unzip -q "/tmp/tofu_${tofu_version}_linux_${architecture}.zip" tofu -d /usr/local/bin; \
    curl --fail --location --silent --show-error --output "/tmp/task_linux_${architecture}.tar.gz" "https://github.com/go-task/task/releases/download/v${task_version}/task_linux_${architecture}.tar.gz"; \
    curl --fail --location --silent --show-error --output /tmp/task_checksums.txt "https://github.com/go-task/task/releases/download/v${task_version}/task_checksums.txt"; \
    (cd /tmp && grep "task_linux_${architecture}.tar.gz" task_checksums.txt | sha256sum --check --status); \
    tar -xzf "/tmp/task_linux_${architecture}.tar.gz" -C /usr/local/bin task; \
    terraform version; \
    tofu version; \
    task --version; \
    rm -rf /tmp/terraform_* /tmp/tofu_* /tmp/task_* /tmp/versions; \
    mkdir -p /home/vscode/.cache/terraform/providers; \
    chown -R vscode:vscode /home/vscode/.cache

ENV TF_PLUGIN_CACHE_DIR=/home/vscode/.cache/terraform/providers
