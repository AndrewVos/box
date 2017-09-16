#!/bin/bash

source /box.sh
source /helpers.sh

result=$(satisfy file-line "Some file thing" "$HOME/some-file.txt" "echo 1")
expect-result-to-include "file-line Some file thing -> missing"
expect-file-to-equal $HOME/some-file.txt "echo 1 # Some file thing"

result=$(satisfy file-line "Some file thing" "$HOME/some-file.txt" "echo 1")
expect-result-to-include "file-line Some file thing -> latest"
expect-file-to-equal $HOME/some-file.txt "echo 1 # Some file thing"
