#!/bin/bash

haPassword='passsword'
nodes=(192.168.1.2:srv-02 192.168.1.3:srv-03)
node_names='srv-02 srv-03'
sharedIP='192.168.1.3'
cidr='24'
service_name='example'

for item in ${nodes[*]}; do
  addr=$(printf $item|cut -d':' -f1)
    host=$(printf $item|cut -d':' -f2)
    address+="$addr "; hosts+="$host "
    if [ `cat /etc/hosts | grep "$host" -c` -eq 0 ]; then
    echo "$addr $host" >> /etc/hosts
    fi
done

echo 0 > /sys/fs/selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

yum update -y
yum install pacemaker corosync pcs resource-agents fence-agents -y

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=high-availability
firewall-cmd --reload

systemctl enable pcsd
service pcsd start
pcs cluster destroy
echo hacluster:$haPassword | chpasswd

if [ $(echo "$address" | awk '{ print $NF }') == $(hostname -I | awk '{print $1}')  ]; then
  echo "lastnode"
  pcs cluster auth $hosts -u hacluster -p $haPassword
  pcs cluster setup --force --enable --transport udpu --name proxy $hosts
  pcs cluster start --all
  pcs cluster enable --all
  pcs property set stonith-enabled=false
  pcs property set no-quorum-policy=ignore
  pcs resource create ip-alias IPaddr2 ip="$sharedIP" cidr_netmask="$cidr"
  pcs resource create $service_name service:$service_name op monitor interval=2
  pcs resource group add hagroup ip-alias $service_name
  pcs constraint order start ip-alias then start $service_name
  pcs resource update $service_name op start timeout=15s
  sleep 10
  pcs status
fi

systemctl disable $service_name
systemctl restart $service_name
