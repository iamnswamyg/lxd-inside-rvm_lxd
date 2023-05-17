#!/bin/bash

SCRIPT_PREFIX="lxdc"
OS=${SCRIPT_PREFIX}
STORAGE_PATH="/data/lxd/"${SCRIPT_PREFIX}
IP="10.120.11"
IFACE="eth0"
IP_SUBNET=${IP}".1/24"
POOL=${SCRIPT_PREFIX}"-pool"
SCRIPT_PROFILE_NAME=${SCRIPT_PREFIX}"-profile"
SCRIPT_BRIDGE_NAME=${SCRIPT_PREFIX}"-br"
NAME=${SCRIPT_PREFIX}"-test"
IMAGE="rvm"

UID= echo uid=$(id -u) | awk -F= '{print $2}'

if ! [[ $(cat /etc/subuid /etc/subgid | grep -o -i root | wc -l) -eq 2 ]]; then
    echo "root:${UID}:1" | sudo tee -a /etc/subuid /etc/subgid
else
  if ! [[ $(cat /etc/subuid | grep -o -i root | wc -l) -eq 1 ]]; then
    echo "root:${UID}:1" | sudo tee -a /etc/subuid
  fi
  if ! [[ $(cat /etc/subgid | grep -o -i root | wc -l) -eq 1 ]]; then
    echo "root:${UID}:1" | sudo tee -a /etc/subgid
  fi
fi

# check if jq exists
if ! snap list | grep jq >>/dev/null 2>&1; then
  sudo snap install jq 
fi
# check if lxd exists
if ! snap list | grep lxd >>/dev/null 2>&1; then
  sudo snap install lxd 
fi


if ! [ -d ${STORAGE_PATH} ]; then
    sudo mkdir -p ${STORAGE_PATH}
fi

# creating the pool
lxc storage create ${POOL} dir source=${STORAGE_PATH}

#create network bridge
lxc network create ${SCRIPT_BRIDGE_NAME} ipv6.address=none ipv4.address=${IP_SUBNET} ipv4.nat=true

# creating needed profile
lxc profile create ${SCRIPT_PROFILE_NAME}

# editing needed profile
echo "config:
devices:
  ${IFACE}:
    name: ${IFACE}
    network: ${SCRIPT_BRIDGE_NAME}
    type: nic
  root:
    path: /
    pool: ${POOL}
    type: disk
name: ${SCRIPT_PROFILE_NAME}" | lxc profile edit ${SCRIPT_PROFILE_NAME} 


#create master container
lxc init ${IMAGE} ${NAME} --profile ${SCRIPT_PROFILE_NAME}
lxc network attach ${SCRIPT_BRIDGE_NAME} ${NAME} ${IFACE}
lxc config device set ${NAME} ${IFACE} ipv4.address ${IP}.2
lxc config set ${NAME} raw.idmap "both ${UID} ${UID}"
lxc config device add ${NAME} homedir disk source=/home/${USER} path=/home/ubuntu
lxc start ${NAME} 
sudo lxc config device add ${NAME} ${NAME}-script-share disk source=${PWD}/scripts path=/lxd
sudo lxc exec ${NAME} -- /bin/bash /lxd/${NAME}.sh
#save container as image
lxc stop ${NAME}
lxc publish ${NAME} --alias ${NAME} 
lxc start ${NAME}












