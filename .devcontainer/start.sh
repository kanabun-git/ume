#!/usr/bin/env bash
# Runs every time the Codespace (re)starts, including after it was stopped
# and resumed later. postCreateCommand (setup.sh) only runs once on first
# creation, so PostgreSQL and the Rails server need to be (re)started here.
set -uxo pipefail

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)" 2>/dev/null || true

sudo service postgresql start

if ! curl -sf http://localhost:3000 >/dev/null 2>&1; then
  nohup bin/rails server -p 3000 -b 0.0.0.0 > /tmp/rails-server.log 2>&1 &
fi
