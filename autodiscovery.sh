#!/bin/bash

servece_port=1234

cd /opt/proxy
echo "=== Run autodiscovery ==="
addr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
for sub in $addr; do
    echo "=== Search services on $sub ==="
    hosts=$(nmap -Pn -v -p $servece_port $sub 2>/dev/null| grep 'open port')
    servers=$(printf "$hosts" | grep '$servece_port/tcp' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')
done
if [ ! -z "$hosts" ]; then
    sm=$(printf "%s" "$servers" | jq -Rrsc 'split("\n")')

    sed -i "s/\"servers\": .*/\"servers\": $sm,/g;" params.conf
    systemctl restart proxy
else
    printf "=== Services not found! ===\nPlease install it, and run /opt/proxy/autodiscovery again.\n"
fi
