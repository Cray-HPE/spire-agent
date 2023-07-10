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

ifeq ($(ARCH),)
export ARCH ?= x86_64
endif

ifeq ($(NAME),)
export NAME := $(shell basename $(shell pwd))
endif

ifeq ($(SPIRE_VERSION),)
export SPIRE_VERSION := $(shell git vendor list spire | grep ref | awk '{print $$NF}')
endif

ifeq ($(BUILD),)
export BUILD := $(shell git describe --tags | tr -s '-' '~' | sed 's/^v//')
endif

# By default, if these are not set then set them to match the host.
ifeq ($(GOOS),)
OS := $(shell uname)
export GOOS := $(call lc,$(OS))
endif
ifeq ($(GOARCH),)
	ifeq "$(ARCH)" "aarch64"
		export GOARCH=arm64
	else ifeq "$(ARCH)" "x86_64"
		export GOARCH=amd64
	endif
endif

SPEC_FILE ?= ${NAME}.spec
SOURCE_NAME ?= ${NAME}
BUILD_DIR ?= $(PWD)/dist/rpmbuild
SOURCE_PATH := ${BUILD_DIR}/SOURCES/${SOURCE_NAME}-$(shell echo $(SPIRE_VERSION) | sed 's/^v//').tar.bz2

.PHONY: rpm
rpm: print rpm_package_source rpm_build_source rpm_build

.PHONY: print
print:
	@printf "%-20s: %s\n" Name $(NAME)
	@printf "%-20s: %s\n" 'SPIRE Version' $(SPIRE_VERSION)
	@printf "%-20s: %s\n" 'ARCH' $(ARCH)
	@printf "%-20s: %s\n" Build $(BUILD)

.PHONY: prepare
prepare:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/SPECS $(BUILD_DIR)/SOURCES
	cp $(SPEC_FILE) $(BUILD_DIR)/SPECS/

.PHONY: rpm_package_source
rpm_package_source:
	tar --transform 'flags=r;s,^,/${NAME}-$(shell echo $(SPIRE_VERSION) | sed 's/^v//')/,' --exclude .git --exclude dist -cvjf $(SOURCE_PATH) .

.PHONY: rpm_build_source
rpm_build_source:
	rpmbuild --nodeps --target ${ARCH} -ts $(SOURCE_PATH) --define "_topdir $(BUILD_DIR)"

.PHONY: rpm_build
rpm_build:
	rpmbuild --nodeps --target ${ARCH} -ba $(SPEC_FILE) --define "_topdir $(BUILD_DIR)"
