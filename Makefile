ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ZIPS_DIR ?= $(abspath $(ROOT)../zips)

.PHONY: index

index:
	python3 -I $(ROOT)scripts/index.py $(ZIPS_DIR)
