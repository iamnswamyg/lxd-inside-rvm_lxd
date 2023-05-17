FROM ubuntu:14.04

RUN    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt update \
    && apt install -y apt-transport-https bash curl gnupg2 python3 unzip vim zip \
    && curl -fsSL https://archive.repo.saltproject.io/apt/ubuntu/14.04/amd64/2019.2/SALTSTACK-GPG-KEY.pub | apt-key add - && \
    echo "deb https://archive.repo.saltproject.io/apt/ubuntu/14.04/amd64/2019.2 trusty main" >/etc/apt/sources.list.d/saltstack.list

RUN    apt update \
    && apt install -y salt-minion
    && apt install -y rsyslog