#!/bin/bash

servece_port=1234

cd /opt/proxy

# get params
port=$(cat params.conf | jq  -r '.port' | echo ${1:-8080})
servers=$(cat params.conf | jq  -r '.servers[]')

fail_timeout=$(cat params.conf | jq -r .fail_timeout | echo ${1:-1s})
max_fails=$(cat params.conf | jq -r .max_fails | echo ${1:-1})
proxy_connect_timeout=$(cat params.conf | jq -r .proxy_connect_timeout | echo ${1:-1s})
proxy_send_timeout=$(cat params.conf | jq -r .proxy_send_timeout | echo ${1:-10s})
proxy_read_timeout=$(cat params.conf | jq -r .proxy_read_timeout | echo ${1:-10s})

# make templates from params
proxytreamtpl="max_fails=$max_fails fail_timeout=$fail_timeout;\n"
locationtpl="\n\tproxy_connect_timeout $proxy_connect_timeout;\n\tproxy_send_timeout $proxy_send_timeout;\n\tproxy_read_timeout $proxy_read_timeout;\n"

# make servers list
for host in $servers; do
    srv+="  server $host:$servece_port $proxytreamtpl"
done

# make upstream list
if [ ! -z "$srv" ]; then
  smctpl="upstream proxy  {\n$srv}\n"
  location_tpl="location \/proxy\/ {\n\tproxy_pass  http:\/\/proxy; $locationtpl}"
fi

# write config
cat nginx/etc/nginx/conf.d/default.conf.example | \
sed "s/__port__/$port/g; \
s/__upstream__/$tpl/g; \
s/__location__/$location_tpl/g"  > nginx/etc/nginx/conf.d/default.conf

# run service
mkdir -p /var/log/proxy /opt/proxy/nginx/var/log/nginx
umount /opt/proxy/nginx/var/log/nginx &> /dev/null
mount --bind /var/log/proxy /opt/proxy/nginx/var/log/nginx
chroot /opt/proxy/nginx /bin/bash -c '/etc/init.d/nginx start'
