#!/bin/bash

echo "Install dependencies ..."
yum install shc rpm-build -y

dir="rpmbuild/SOURCES/opt/proxy"
rpmDir="products"

version=`cat .version`
new=$(echo "$version+0.001" | bc -l)
sed -i "s/Version:.*/Version:$new/" rpmbuild/SPECS/proxy.spec

rm -fR $dir/*
mkdir -p $dir $rpmDir

tar -cvf  $dir/proxy.tar nginx/

shc -r -f stop.sh -o $dir/stop
shc -r -f start.sh -o $dir/start
shc -r -f autodiscovery.sh -o $dir/autodiscovery
rm -f *.sh.x.c

cp params.conf $dir/

rm -f ~/rpmbuild
ln -s `pwd`/rpmbuild ~/rpmbuild

cd rpmbuild/SPECS
rpmbuild -bb proxy.spec

cd -
rm -f $rpmDir/proxy*.rpm
mv ~/rpmbuild/RPMS/x86_64/* $rpmDir/
rm -fR $dir/*
rm -fR ~/rpmbuild
