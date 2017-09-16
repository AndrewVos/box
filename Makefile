TESTS=$(wildcard tests/*-test.sh)

.PHONY: test clean $(TESTS)

test: $(TESTS)

INITIAL_BOX_NAME = box-test-initial
BOX_NAME = $$(basename --suffix .sh $@)

$(TESTS): image
	@lxc delete --force $(BOX_NAME) 2> /dev/null || :
	@lxc copy local:$(INITIAL_BOX_NAME)/snapshot $(BOX_NAME)
	@lxc file push tests/helpers.sh $(BOX_NAME)/helpers.sh
	@lxc file push $@ $(BOX_NAME)/test.sh
	@lxc start $(BOX_NAME)
	@sleep 10
	@lxc exec $(BOX_NAME) -- sh -c "chmod +x /test.sh && /test.sh"
	@lxc delete --force $(BOX_NAME)

image: box.sh
	@lxc delete --force $(INITIAL_BOX_NAME) || :
	@lxc launch ubuntu:17.04 $(INITIAL_BOX_NAME)
	@sleep 5
	@lxc exec $(INITIAL_BOX_NAME) -- apt-key update
	@lxc exec $(INITIAL_BOX_NAME) -- apt-get -y update
	@lxc exec $(INITIAL_BOX_NAME) -- apt-get -y --force-yes upgrade
	@lxc stop $(INITIAL_BOX_NAME)
	@lxc file push box.sh $(INITIAL_BOX_NAME)/box.sh
	@lxc snapshot $(INITIAL_BOX_NAME) snapshot
	@touch image

clean:
	@rm image || :
