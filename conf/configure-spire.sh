#!/bin/bash
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

#Set spire home
spire_rootdir="/var/lib/spire"

# Get boot parameters
BOOT_PARAMS=$(</proc/cmdline)

if [[ -f "${spire_rootdir}/conf/join_token" ]] && [[ -f "${spire_rootdir}/conf/spire-agent.conf" ]]; then
    echo "Not recreating spire-agent.conf."
    exit 0
fi

# set mdserver_endpoint and fetch join_token
for word in ${BOOT_PARAMS}; do
    IFS='=' read -r parent_key parent_val <<< "${word}"

    if [[ ${parent_key} == 'ds' ]]; then
        mdserver_endpoint=$(sed -E 's#.*s=(.*)/#\1#' <<< "${parent_val}")
        if [[ -z ${mdserver_endpoint} ]]; then
            echo >&2 "mdserver_endpoint is not set. Unable to generate SPIRE Agent config file."
            exit 1
        fi
    fi

    if [[ ${parent_key} == 'spire_join_token' ]]; then
        join_token="${parent_val}"

        if [[ -z ${join_token} ]]; then
            echo >&2 "join_token is not set. Refusing to start spire-agent"
            exit 1
        else
            printf "join_token=%s" "${join_token}" > "${spire_rootdir}/conf/join_token"
            chmod 600 "${spire_rootdir}/conf/join_token"
        fi
    fi
done

# NOTE: An empty spire-agent.conf gets installed by spire-agent rpm.
if ! [[ -f ${spire_rootdir}/conf/spire-agent.conf ]]
then
    [[ -f /root/spire/conf/spire-agent.conf ]] && spire_rootdir="/root/spire"
fi

# prevent recreating config file if the agent is already running
if [[ -S ${spire_rootdir}/agent.sock ]]; then
    echo "Spire agent is already running. Will not recreate spire-agent.conf file"
    exit 0
fi

ret=$(curl -s -k -o /tmp/spire_bundle -w '%{http_code}' "${mdserver_endpoint}/spire-bundle/")

if [[ "$ret" == "200" ]]; then
    spire_domain=$(jq -Mcr '.Domain' /tmp/spire_bundle)
    spire_server=$(jq -Mcr '.Server' /tmp/spire_bundle)
    # Insert root certificate into bundle.crt
    jq -Mcr '.CertBundle' /tmp/spire_bundle > ${spire_rootdir}/bundle/bundle.crt
else
    ret=$(curl -s -k -o /tmp/spire_bundle -w '%{http_code}' "${mdserver_endpoint}/meta-data")
    if [[ "$ret" == "200" ]]; then
        spire_domain=$(jq -Mcr '.Global.spire.trustdomain' /tmp/spire_bundle)
        spire_server=$(jq -Mcr '.Global.spire.fqdn' /tmp/spire_bundle)
        # Insert root certificate into bundle.crt
        jq -Mcr '.Global."ca-certs".trusted[0]' /tmp/spire_bundle > ${spire_rootdir}/bundle/bundle.crt
    else
        echo >&2 "Unable to retrieve metadata from server"
        exit 1
    fi
fi

rm -f /tmp/spire_bundle

# Populate the spire configuration file
cat << EOF > "${spire_rootdir}/conf/spire-agent.conf"
agent {
  data_dir = "${spire_rootdir}"
  log_level = "WARN"
  server_address = "${spire_server}"
  server_port = "8081"
  socket_path = "${spire_rootdir}/agent.sock"
  trust_bundle_path = "${spire_rootdir}/bundle/bundle.crt"
  trust_domain = "${spire_domain}"
  join_token = "\$join_token"
}

plugins {
  NodeAttestor "join_token" {
    plugin_data {}
  }

  KeyManager "disk" {
    plugin_data {
        directory = "${spire_rootdir}/data"
    }
  }

  WorkloadAttestor "unix" {
    plugin_data {
        discover_workload_path = true
    }
  }
}
EOF
