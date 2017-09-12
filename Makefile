.PHONY: test image

TESTS=$(wildcard tests/*-test.sh)

test: $(TESTS)

$(TESTS): image
	@sudo docker run -t box-test /bin/bash "-c" "./$@"

image:
	@sudo docker build -q -t box-test .

