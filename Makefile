# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /usr/bin/env bash

install-kind:
	@./hack/install-kind.sh


