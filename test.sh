#!/usr/bin/env bash

set -euo pipefail

plugins_dir="./.testcache/site/pack/vendor/start"

if ! [ -e "${plugins_dir}/plenary.nvim" ]; then
  mkdir -p .testcache/site
  git clone --depth=1 https://github.com/nvim-lua/plenary.nvim "${plugins_dir}/plenary.nvim"
fi

nvim --headless --noplugin -u tests/init.lua -c "lua require('plenary.test_harness').test_directory('tests/format-on-save/', {minimal_init='tests/init.lua',sequential=true})"
