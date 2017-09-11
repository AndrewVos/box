.PHONY: test image

TESTS=$(wildcard tests/*-test.sh)
TEST_OUTPUTS=$(patsubst %.sh,%.out,$(TESTS))

%.out: %.sh image
	@sudo docker run -t box-test /bin/bash "-c" "./$^"

test: $(TEST_OUTPUTS)
	@echo

image:
	@sudo docker build -q -t box-test .

