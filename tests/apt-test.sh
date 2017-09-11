#!/bin/bash

source box.sh
source tests/helpers.sh

result=$(satisfy apt "git" 2> /dev/null)
expect-result-to-include "apt git -> missing"

result=$(satisfy apt "git")
expect-result-to-include "apt git -> latest"

result=$(dpkg --get-selections)
expect-result-to-include "git						install"
