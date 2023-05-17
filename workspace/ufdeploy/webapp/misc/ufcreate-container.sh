LCX_INSTANCE_NAME=$(hostname)-$1
LXC_START_DELAY=$2
FILE=/var/lib/lxc/$LCX_INSTANCE_NAME/rootfs/root/setup.sh

lxc-create -n $LCX_INSTANCE_NAME -t ubuntu -- --user ufadm

echo "echo Setup starting" > $FILE
echo "echo Running: apt-get -y update" >> $FILE
echo "apt-get -y update" >> $FILE
echo "echo Running: apt-get -y install wget" >> $FILE
echo "apt-get -y install wget" >> $FILE
echo "echo Running: apt-get -y update" >> $FILE
echo "apt-get -y update" >> $FILE
echo "echo Running: apt-get -y upgrade" >> $FILE
echo "apt-get -y upgrade" >> $FILE
echo "echo Running: apt-get -y install nano salt-minion" >> $FILE
echo "apt-get -y install nano salt-minion" >> $FILE
echo "echo Updating minion_id " >> $FILE
echo "echo $LCX_INSTANCE_NAME > /etc/salt/minion_id" >> $FILE
echo "echo Adding salt to /etc/hosts " >> $FILE
echo "echo \"10.10.0.101 salt\" >> /etc/hosts" >> $FILE
echo "echo Running: service salt-minion restart" >> $FILE
echo "service salt-minion restart" >> $FILE
echo "echo Setup done" >> $FILE

chmod u+x /var/lib/lxc/$LCX_INSTANCE_NAME/rootfs/root/setup.sh
#lxc-execure -n $LCX_INSTANCE_NAME /root/setup.sh
lxc-start -d -n $LCX_INSTANCE_NAME
sleep 5
lxc-attach -n $LCX_INSTANCE_NAME -- /root/setup.sh
rm /var/lib/lxc/$LCX_INSTANCE_NAME/rootfs/root/setup.sh

echo "lxc.network.veth.pair = veth-$1" >> /var/lib/lxc/$LCX_INSTANCE_NAME/config
echo "lxc.start.auto = 1" >> /var/lib/lxc/$LCX_INSTANCE_NAME/config
echo "lxc.start.delay = $LXC_START_DELAY" >> /var/lib/lxc/$LCX_INSTANCE_NAME/config
