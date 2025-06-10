FROM gitpod/workspace-full:latest

USER root

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    tar \
    ca-certificates \
    && apt-get clean

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

# kubectl (fixed with bash)
RUN bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"' \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# eksctl
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
    | tar xz -C /tmp \
    && mv /tmp/eksctl /usr/local/bin
