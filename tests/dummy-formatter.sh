#!/usr/bin/env bash

set -euo pipefail

mode="$1"
shift
case "$mode" in
  replace-name)
    sed "s/{name}/joe/"
    ;;
  replace-filename)
    sed "s/{filename}/$1/"
    ;;
  format-tempfile)
    mv -f "$1" "$1.tmp"
    sed "s#{tempfile}#$1#" "$1.tmp" > "$1"
    rm -f "$1.tmp"
    ;;
esac
