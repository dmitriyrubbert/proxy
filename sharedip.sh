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

sudo service apparmor stop
sudo update-rc.d -f apparmor remove
sudo apt -y purge apparmor

sudo apt update

sudo apt purge pcs corosync pacemaker python3-tornado -y
sudo pip3 uninstall tornado -y
sudo apt autoremove -y

sudo apt install pacemaker corosync pcs -y

sudo systemctl enable pcsd
sudo service pcsd start
sudo pcs cluster destroy
echo hacluster:$haPassword | sudo chpasswd

if [ $(echo "$address" | awk '{ print $NF }') == $(hostname -I | awk '{print $1}')  ]; then
  echo "lastnode"
  sudo pcs host auth $hosts -u hacluster -p $haPassword
  sudo pcs cluster setup proxy $hosts --start --enable
  sudo pcs property set stonith-enabled=false
  sudo pcs property set no-quorum-policy=ignore
  sudo pcs resource create ip-alias IPaddr2 ip="$sharedIP" cidr_netmask="$cidr"
  sudo pcs resource create $service_name service:$service_name op monitor interval=2
  sudo pcs resource group add hagroup ip-alias $service_name
  sudo pcs constraint order start ip-alias then start $service_name
  sudo pcs resource update $service_name op start timeout=15s
  sleep 10
  sudo pcs status
fi

systemctl disable $service_name
systemctl restart $service_name
