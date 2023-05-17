FROM ubuntu:22.04

RUN    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt update \
    && apt install -y apt-transport-https bash curl gnupg2 python3 unzip vim zip ca-certificates curl software-properties-common \
    && curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring.gpg https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/3005/salt-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/3005 jammy main" > /etc/apt/sources.list.d/salt.list
    

RUN    apt update \
    && apt install -y salt-minion