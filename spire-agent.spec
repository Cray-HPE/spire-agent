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
Summary: spire-agent binary
Version: %(echo $SPIRE_VERSION | sed 's/^v//')
Release: %(echo $BUILD)
Source: %{name}-%{version}.tar.bz2
Group: Applications/System
Vendor: Hewlett Packard Enterprise Company
%systemd_requires
Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%ifarch %ix86
    %global GOARCH 386
%endif
%ifarch aarch64
    %global GOARCH arm64
%endif
%ifarch x86_64
    %global GOARCH amd64
%endif

%define vendor_dir vendor/github.com/spiffe/spire

%define arch %{arch}
%define spire_binary bin/spire-agent

%define spire_agent_dir /var/lib/spire
%define spire_bin_dir /opt/cray/cray-spire

%description
SPIFFE SPIRE Agent binary distribution.

%prep
%setup -q

%build
cd %{vendor_dir}
make build

%install
mkdir -p %{buildroot}%{spire_agent_dir}/{data,conf,bundle}
install -D -m 0700 %{vendor_dir}/bin/spire-agent %{buildroot}%{spire_bin_dir}/spire-agent
install -D -m 0700 conf/configure-spire.sh %{buildroot}%{spire_bin_dir}/configure-spire.sh
install -D -m 0644 conf/spire-agent.service %{buildroot}%{_unitdir}/spire-agent.service

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc README.adoc
%attr(700,root,root) %{spire_bin_dir}/spire-agent
%attr(700,root,root) %{spire_bin_dir}/configure-spire.sh
%attr(644,root,root) %{_unitdir}/spire-agent.service
%attr(700,spire,spire) %dir %{spire_agent_dir}/data
%attr(700,spire,spire) %dir %{spire_agent_dir}/conf
%attr(700,spire,spire) %dir %{spire_agent_dir}/bundle

%pre
%if 0%{?suse_version}
%service_add_pre spire-agent.service
%endif
getent group spire >/dev/null || groupadd -r spire
getent passwd spire >/dev/null || \
    useradd -r -g spire -d /var/lib/spire -s /sbin/nologin \
    -c "spire-agent service account" spire

%post
%if 0%{?suse_version}
%service_add_post spire-agent.service
%else
%systemd_post spire-agent.service
%endif

%preun
%if 0%{?suse_version}
%service_del_preun spire-agent.service
%else
%systemd_preun spire-agent.service
%endif

%postun
%if 0%{?suse_version}
%service_del_postun spire-agent.service
%else
%systemd_postun_with_restart spire-agent.service
%endif

%changelog
