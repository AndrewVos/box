
#!/bin/bash

source box.sh
source tests/helpers.sh

result=$(satisfy apt-ppa "ppa:peek-developers/stable" 2> /dev/null)
expect-result-to-include "apt-ppa ppa:peek-developers/stable -> missing"

result=$(apt-cache policy)
expect-result-to-include "500 http://ppa.launchpad.net/peek-developers/stable/ubuntu xenial/main amd64 Packages"

result=$(satisfy apt-ppa "ppa:peek-developers/stable")
expect-result-to-include "apt-ppa ppa:peek-developers/stable -> latest"
