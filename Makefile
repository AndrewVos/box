.PHONY: test image

TESTS=$(wildcard tests/*-test.sh)

test: $(TESTS)

$(TESTS): shellcheck image
	@sudo docker run -t box-test /bin/bash "-c" "./$@"
	@echo

shellcheck: box.sh
	shellcheck box.sh

image:
	@sudo docker build -q -t box-test .

