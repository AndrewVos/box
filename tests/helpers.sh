#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

function expect-result-to-include () {
  local expected=$1
  if echo "$result" | grep "$expected" > /dev/null; then
    printf "."
  else
    echo "Fail:"
    echo "Expected:"
    echo $expected
    echo "Result:"
    echo "$result"
  fi
}


function expect-file-to-equal () {
  local file=$1
  local expected=$2

  if [[ "$expected" = $(cat $file) ]]; then
    printf "."
  else
    echo "Fail:"
    echo "Expected:"
    echo "$expected"
    echo "Result:"
    cat "$file"
  fi
}
