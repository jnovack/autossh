include variables.mk

.PHONY: build all
.DEFAULT_GOAL := all

all: build

test:
	echo $(PACKAGE)
