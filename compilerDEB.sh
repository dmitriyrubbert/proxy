#!/bin/bash

dir="build/opt/proxy"
debDir="products"


version=`cat .version`
new=$(echo "$version+0.001" | bc -l)
echo "$new" > .version
sed -i "s/Version:.*/Version:$new/" build/DEBIAN/control

rm -fR $dir/*
mkdir -p $dir $debDir

tar -cvf  $dir/proxy.tar nginx/

shc -r -f ./stop.sh -o $dir/stop
shc -r -f ./start.sh -o $dir/start
shc -r -f ./autodiscovery.sh -o $dir/autodiscovery

rm -f ./stop.sh.x.c ./start.sh.x.c ./autodiscovery.sh.x.c

cp params.conf $dir/

dpkg-deb --build --root-owner-group build

OS=`lsb_release -a | grep Distributor | cut -d':' -f2 | xargs`

rm -f $debDir/proxy*.deb

cp build.deb $debDir/proxy-$new-Debian.deb
mv build.deb $debDir/proxy-$new-$OS.deb

rm -fR $dir/*
