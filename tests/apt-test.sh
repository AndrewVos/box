#!/bin/bash

source /box.sh
source /helpers.sh

result=$(satisfy apt "multitail" 2> /dev/null)
expect-result-to-include "apt multitail -> missing"

result=$(dpkg --get-selections)
expect-result-to-include "multitail					install"

result=$(satisfy apt "multitail")
expect-result-to-include "apt multitail -> latest"

result=$(dpkg --get-selections)
expect-result-to-include "multitail					install"
