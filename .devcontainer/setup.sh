#!/usr/bin/env bash
# Runs once when the Codespace is created. Installs Ruby (via rbenv, matching
# .ruby-version), PostgreSQL, project gems, sets up the DB, and starts the
# Rails server in the background so it's already running by the time the
# Codespace finishes booting.
set -euxo pipefail

# Keep sudo's cached credentials alive for the whole script. Ruby compiles
# from source below and can take several minutes — long enough for sudo's
# default timestamp to expire, after which a later `sudo` call blocks
# forever on a password prompt nobody can answer. Grab the credential now
# (while still within the fresh post-boot window) and refresh it every 60s
# in the background until this script exits.
sudo -v
( while true; do sleep 60; sudo -n true 2>/dev/null || exit; kill -0 "$$" 2>/dev/null || exit; done & )

# Prevent apt / needrestart from opening interactive prompts, which would
# otherwise hang this script forever waiting for keyboard input that never
# comes (a very common devcontainer gotcha on Debian-based images).
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

sudo -E apt-get update < /dev/null
sudo -E apt-get install -y --no-install-recommends \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  git build-essential libssl-dev libreadline-dev zlib1g-dev \
  libyaml-dev libffi-dev libgdbm-dev postgresql postgresql-contrib libpq-dev < /dev/null

if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
fi

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"

RUBY_VERSION="$(cat .ruby-version | sed 's/ruby-//')"
rbenv install -s "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"

gem install bundler --no-document

sudo service postgresql start
sudo -u postgres psql -c "ALTER ROLE \"$(whoami)\" SUPERUSER LOGIN;" || true

bundle install

bin/rails db:create db:migrate db:seed

nohup bin/rails server -p 3000 -b 0.0.0.0 > /tmp/rails-server.log 2>&1 &

echo "Setup complete. Rails server starting on port 3000."
