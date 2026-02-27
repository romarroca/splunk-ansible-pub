FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    python3 \
    openssh-client \
    sshpass \
    git \
    ca-certificates \
    curl \
    vim \
    iputils-ping \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /splunk-ansible

RUN ansible-galaxy collection install community.general

CMD ["bash"]
