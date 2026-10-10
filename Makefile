ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ZIPS_DIR ?= $(abspath $(ROOT)../zips)

.PHONY: index check

index:
	python3 -I $(ROOT)scripts/index.py $(ZIPS_DIR)

check:
	ZIPS_DIR=$(ZIPS_DIR) $(ROOT)scripts/check.sh
