#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
Name: %(echo $NAME)
License: GPLv2
Summary: iPXE for booting bare metal in HPCaaS environments
BuildArch: $(echo $ARCH)
Version: %(echo $VERSION)
Release: 1
Source: %{name}-%{version}.tar.bz2
Group: Applications/System
Vendor: Hewlett Packard Enterprise Company
%systemd_requires
Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%define vendor vendor/github.com/Cray-HPE/spire/

%define spire_agent_dir /var/lib/spire
%define spire_bin_dir /opt/cray/cray-spire

%description
SPIFFE SPIRE Agent binary distribution.

%prep
%setup -q

%build
cd %{vendor}
make build

%install

%clean

%files
%defattr(-,root,root)
%license LICENSE
%doc README.adoc
%config(noreplace) %{wwwbootdir}%{bootscript}
%attr(-,dnsmasq,tftp) %{wwwbootdir}%(basename %{binx86_64})

%changelog
