#!/bin/bash

pidGrep="nginx"
ps -ax | grep "$pidGrep" | grep -v grep | awk '{print $1}'| xargs kill -9 &> /dev/null
while [ `ps -ax | grep "$pidGrep" | grep -v grep -c` -ne 0 ]; do sleep 0.1; done

umount /opt/proxy/nginx/var/log/nginx &> /dev/null
