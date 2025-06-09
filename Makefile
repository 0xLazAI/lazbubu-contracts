.PHONY: build
build:
	forge build --sizes

.PHONY: fmt
fmt:
	forge fmt

.PHONY: test
test:
	forge test -vvv
