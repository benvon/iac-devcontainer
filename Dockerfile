FROM --platform=x86_64 docker.io/library/debian:bullseye-slim as base

# Set the SHELL to bash with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

ARG CPUARCH
ENV CPUARCH amd64 
ARG CPUARCH_EXT 
ENV CPUARCH_EXT x86_64

ARG OS 
ENV OS linux
ARG OS_EXT 
ENV OS_EXT Linux

RUN apt-get update \
        -o Acquire::Check-Valid-Until=false \
        -o Acquire::Check-Date=false && \
    apt-get upgrade -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        --no-install-recommends && \
    apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        --no-install-recommends \
            build-essential \
            coreutils \
            util-linux \
            bsdutils \
            file \
            openssl \
            locales \
            ca-certificates \
            wget \
            patch \
            curl \
            git \
            jq \
            xz-utils \
            unzip \
            zip \
            bzip2 \
            gnupg \
            apt-transport-https \
            openssh-client \
            python3 \
            python3-pip \
            python-is-python3 \
            python3-venv \
            zlib1g \
            && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Go stuff
ARG GO_VERSION 
ENV GO_VERSION=${GO_VERSION:-1.20.3}
RUN set -ex; \  
    curl -fsSLko go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${CPUARCH}.tar.gz" && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go.tar.gz 
ENV PATH=${PATH}:/usr/local/go/bin

# conftest: https://www.conftest.dev/install/
ARG CONFTEST_VERSION
ENV CONFTEST_VERSION=${CONFTEST_VERSION:-0.41.0}
RUN set -ex; \
    curl -fsSLko conftest.tar.gz "https://github.com/open-policy-agent/conftest/releases/download/v$CONFTEST_VERSION/conftest_${CONFTEST_VERSION}_${OS_EXT}_${CPUARCH_EXT}.tar.gz"; \
    tar -xf conftest.tar.gz; \
    mv conftest /usr/local/bin; \
    rm conftest.tar.gz; 

# opa: https://www.openpolicyagent.org/docs/latest/#1-download-opa
ARG OPA_VERSION
ENV OPA_VERSION=${OPA_VERSION:-0.51.0}
RUN set -ex; \
    curl -fsSLko opa "https://openpolicyagent.org/downloads/v$OPA_VERSION/opa_${OS}_${CPUARCH}_static"; \
    chmod +x opa; \
    mv opa /usr/local/bin

# repo: https://gerrit.googlesource.com/git-repo/#install
RUN set -ex; \
    curl -fsSLko repo https://storage.googleapis.com/git-repo-downloads/repo; \
    chmod a+rx repo; \
    mv repo /usr/local/bin

# terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli
ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION:-1.4.6}
RUN set -ex; \
    curl -fsSLko terraform.zip "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_${OS}_${CPUARCH}.zip"; \
    unzip terraform.zip; \
    mv terraform /usr/local/bin; \
    rm terraform.zip

# terragrunt: https://github.com/gruntwork-io/terragrunt/releases/download/v0.38.12/terragrunt_linux_amd64
ARG TERRAGRUNT_VERSION
ENV TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-v0.45.4}
RUN set -ex; \
    curl -fsSLko terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_${OS}_${CPUARCH}"; \
    chmod 755 terragrunt; \
    mv terragrunt /usr/local/bin

# tflint: https://github.com/terraform-linters/tflint#installation
ARG TFLINT_VERSION
ENV TFLINT_VERSION=${TFLINT_VERSION:-0.46.1}
RUN set -ex; \
    curl -fsSLko tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v$TFLINT_VERSION/tflint_${OS}_${CPUARCH}.zip"; \
    unzip tflint.zip; \
    mv tflint /usr/local/bin; \
    rm -rf tflint.zip

# golangci-lint
ARG GOLANGCI_LINT_VERSION
ENV GOLANGCI_LINT_VERSION=${GOLANGCI_LINT_VERSION:-1.52.2}
RUN set -ex; \
    curl -fsSLko golangci-lint.tar.gz "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-${OS}-${CPUARCH}.tar.gz"; \
    tar -xzf golangci-lint.tar.gz; \
    mv golangci-lint-*/golangci-lint /usr/local/bin; \
    rm -rf golangci-lint*; 

ARG PRECOMMIT_VERSION
ENV PRECOMMIT_VERSION=${PRECOMMIT_VERSION_VERSION:-3.2.2}
RUN set -ex; \
    pip3 install --no-cache-dir --no-deps \
      identify \
      filelock \
      cfgv \
      virtualenv \
      platformdirs \
      pre-commit==${PRECOMMIT_VERSION}; 

ARG SBOT_VERSION
ENV SBOT_VERSION=${SBOT_VERSION:-1.1.0}
RUN set -ex && \
    curl -fsSLko semverbot.tar.gz "https://github.com/restechnica/semverbot/archive/refs/tags/v${SBOT_VERSION}.tar.gz" && \
    tar -xzf semverbot.tar.gz && \
    cd semverbot-${SBOT_VERSION} && \
    GOOS=${OS} GOARCH=${CPUARCH} go build -o /usr/local/bin/sbot && \
    chmod +x /usr/local/bin/sbot && \
    cd && \
    rm -rf  semverbot.tar.gz semverbot-${SBOT_VERSION}

# Azure CLI
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir azure-cli

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-${OS}-${CPUARCH_EXT}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    aws --version

RUN mkdir /workspace
WORKDIR /workspace