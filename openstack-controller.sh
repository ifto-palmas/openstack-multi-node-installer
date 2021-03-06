#!/bin/bash

function net_interface()
{
 ifconfig | head -n 1 | cut -d' ' -f1 | cut -d':' -f1 
}

# $1 - network interface name
function ip_addr()
{
  ip -4 addr show $1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
}

#Setup SSH
mkdir -p ~/.ssh; chmod 700 ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyYjfgyPazTvGpd8OaAvtU2utL8W6gWC4JdRS1J95GhNNfQd657yO6s1AH5KYQWktcE6FO/xNUC2reEXSGC7ezy+sGO1kj9Limv5vrvNHvF1+wts0Cmyx61D2nQw35/Qz8BvpdJANL7VwP/cFI/p3yhvx2lsnjFE3hN8xRB2LtLUopUSVdBwACOVUmH2G+2BWMJDjVINd2DPqRIA4Zhy09KJ3O1Joabr0XpQL0yt/I9x8BVHdAx6l9U0tMg9dj5+tAjZvMAFfye3PJcYwwsfJoFxC8w/SLtqlFX7Ehw++8RtvomvuipLdmWCy+T9hIkl+gHYE4cS3OIqXH7f49jdJf jesse@spacey.local" > ~/.ssh/authorized_keys

./download.sh
cd devstack

echo "Starting controller installation"
FLAT_INTERFACE=$(net_interface)
HOST_IP=$(ip_addr $FLAT_INTERFACE)
USER="stack"
PASSWD=$USER

echo "[[local|localrc]]
HOST_IP=$HOST_IP
FLAT_INTERFACE=$FLAT_INTERFACE
#Private Network Addressing
FIXED_RANGE=192.168.0.0/24
FIXED_NETWORK_SIZE=256
FLOATING_RANGE=10.105.0.128/25
MULTI_HOST=1
LOGFILE=/opt/stack/logs/stack.sh.log
ADMIN_PASSWORD=$PASSWD
DATABASE_PASSWORD=$PASSWD
RABBIT_PASSWORD=$PASSWD
SERVICE_PASSWORD=$PASSWD
VERBOSE=true" > local.conf  

#In the multi-node configuration the first 10 or so IPs in the private subnet are usually reserved. 
#Add this to local.sh to have it run after every stack.sh run:
echo "for i in `seq 2 10`; do /opt/$USER/nova/bin/nova-manage fixed reserve 10.4.128.$$i; done" > local.sh

./stack.sh

echo ""
cat ~/.profile | grep "devstack/openrc admin" > /dev/null || echo "source /opt/$USER/devstack/openrc admin" >> ~/.profile
source /opt/$USER/devstack/openrc admin
echo "INSTALLATION COMPLETE"
echo "OpenStack services are installed in subdirectories at /opt/$USER and it's services configuration files are located at /etc"