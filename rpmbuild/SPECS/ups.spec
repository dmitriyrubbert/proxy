Name: proxy
Version:1.000
Release: 1
Summary: Example proxy Server
Group: Applications/Productivity
BuildArch: x86_64
License: free
Requires: nmap

BuildRoot: %{_tmppath}/proxy
AutoReq: no

%description
Example proxy Server

%files
/opt/proxy
/etc/systemd/system/proxy.service

%pre

%install
mkdir -p $RPM_BUILD_ROOT/opt/proxy
mkdir -p $RPM_BUILD_ROOT/etc/systemd/system/
cp ~/rpmbuild/SOURCES/etc/systemd/system/proxy.service $RPM_BUILD_ROOT/etc/systemd/system/
cp -R ~/rpmbuild/SOURCES/opt/proxy/* $RPM_BUILD_ROOT/opt/proxy/

%post
cd /opt/proxy/
if [ -f "proxy.tar" ]; then
	tar -xf proxy.tar
	rm -f proxy.tar &> /dev/null
fi

firewall-cmd --permanent --add-port=6182/tcp
firewall-cmd --reload
systemctl daemon-reload
systemctl enable proxy
/opt/proxy/autodiscovery

%preun
ps -ax | grep "nginx" | grep -v grep | awk '{print $1}'| xargs kill -9 &> /dev/null
while [ `ps -ax | grep "nginx" | grep -v grep -c` -ne 0 ]; do sleep 0.1; done

umount /opt/proxy/nginx/var/log/nginx &> /dev/null

%postun
rm -rf /opt/proxy/
