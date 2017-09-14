.PHONY: test image

TESTS=$(wildcard tests/*-test.sh)

test: $(TESTS)

$(TESTS): image
	@sudo docker run -t box-test /bin/bash "-c" "./$@"
	@echo

image:
	@sudo docker build -q -t box-test .

