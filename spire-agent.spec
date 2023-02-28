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
Version: %(echo $VERSION)
Release: 1
Source: %{name}-%{version}.tar.bz2
Group: Applications/System
Vendor: Hewlett Packard Enterprise Company
%systemd_requires
Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel

%define arch %{arch}
%define spire_binary bin/spire-agent

%define spire_agent_dir /var/lib/spire
%define spire_bin_dir /usr/bin/

%description
SPIFFE SPIRE Agent binary distribution.

%prep
%setup -q

%build

%install
install -D -m 0755 bin/spire-agent %{buildroot}%{_bindir}/spire-agent
install -D -m 0755 conf/configure-spire.sh %{buildroot}%{_bindir}/configure-spire.sh
install -D -m 0644 conf/spire-agent.service %{buildroot}%{_unitdir}/spire-agent.service

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc README.adoc
%{spire_bin_dir}/spire-agent
%{spire_bin_dir}/configure-spire.sh
%{_unitdir}/spire-agent.service

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
