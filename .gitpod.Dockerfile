FROM gitpod/workspace-full:latest

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    tar \
    ca-certificates \
    && apt-get clean

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

# Install fixed version of kubectl (v1.29.2)
RUN curl -LO "https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Install eksctl (latest)
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
    | tar xz -C /tmp \
    && mv /tmp/eksctl /usr/local/bin/eksctl

USER gitpod
