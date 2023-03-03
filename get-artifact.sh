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
exec > "$(basename "$0" .sh).output" 2>&1

set -xeo pipefail
trap 'rm -rf ${TEMP_DIR}' EXIT ERR

if [ -z "${ARCH}" ] || [ -z "${NAME}" ] || [ -z "${SPIRE_URL}" ] || [ -z "${SPIRE_VERSION}" ]; then
    echo >&2 'Please run this script by running "make download"'
    exit 1
fi

if [ -z "${GITHUB_TOKEN}" ]; then
    echo >&2 'GITHUB_TOKEN must be defined'
    exit 1
fi

if ! command -v jq >/dev/null ; then
    echo >&2 'Needs jq'
    exit 1
fi

GITHUB_API_VERSION='2022-11-28'
# ALWAYS RUN THIS SCRIPT BY RUNNING `make download`
TEMP_DIR=$(mktemp -d)

RELEASE_JSON=$(curl -f -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: $GITHUB_API_VERSION" \
    "${SPIRE_URL}/releases" | jq '.[] | select(.tag_name=="'"${SPIRE_VERSION}"'")')
RELEASE_ID="$(echo "${RELEASE_JSON}" | jq .id)"

ASSET_JSON=$(curl -f -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: $GITHUB_API_VERSION" \
    "${SPIRE_URL}/releases/${RELEASE_ID}/assets" | jq '.[] | select(.name | endswith(".tgz"))')
ASSET_ID="$(echo "${ASSET_JSON}" | jq .id)"
ASSET_NAME="$(echo "${ASSET_JSON}" | jq -r .name)"

curl -f -L \
   -H "Accept: application/octet-stream" \
   -H "Authorization: Bearer $GITHUB_TOKEN" \
   -H "X-GitHub-Api-Version: $GITHUB_API_VERSION" \
   "${SPIRE_URL}/releases/assets/${ASSET_ID}" \
   -o "${TEMP_DIR}/${ASSET_NAME}"
tar -xvzf "${TEMP_DIR}/${ASSET_NAME}" -C "${TEMP_DIR}"

mkdir -p bin
cp "${TEMP_DIR}/${NAME}-${ARCH}" "bin/${NAME}"