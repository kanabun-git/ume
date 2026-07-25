#!/usr/bin/env bash
# Runs once when the Codespace is created. Installs Ruby (via rbenv, matching
# .ruby-version), PostgreSQL, project gems, sets up the DB, and starts the
# Rails server in the background so it's already running by the time the
# Codespace finishes booting.
set -euxo pipefail

# Prevent apt / needrestart from opening interactive prompts, which would
# otherwise hang this script forever waiting for keyboard input that never
# comes (a very common devcontainer gotcha on Debian-based images).
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# --- Everything that needs sudo happens here, up front -----------------
# Ruby compiles from source further down and can take several minutes —
# long enough for sudo's cached credential to expire, after which a later
# `sudo` call blocks forever on a password prompt nobody can answer.
# Finishing all root-requiring steps now, before anything slow, sidesteps
# that entirely: nothing below this block ever calls sudo again.
sudo -E apt-get update < /dev/null
sudo -E apt-get install -y --no-install-recommends \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  git build-essential libssl-dev libreadline-dev zlib1g-dev \
  libyaml-dev libffi-dev libgdbm-dev postgresql postgresql-contrib libpq-dev < /dev/null

sudo service postgresql start

# `sudo -u postgres ...` (switching to a *different* target user) prompts
# for a password on this image even though plain `sudo <cmd>` (root, the
# default target) does not — this sudoers setup only grants NOPASSWD for
# root. Route through a root shell instead: `sudo bash -c '...'` hits the
# passwordless root rule, and `su postgres` inside it needs no further
# sudo authorization because we're already root at that point.
CURRENT_USER="$(whoami)"
cat > /tmp/init_pg_role.sql <<SQL
DO
\$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${CURRENT_USER}') THEN
    CREATE ROLE "${CURRENT_USER}" SUPERUSER LOGIN;
  ELSE
    ALTER ROLE "${CURRENT_USER}" SUPERUSER LOGIN;
  END IF;
END
\$\$;
SQL
chmod 644 /tmp/init_pg_role.sql
sudo bash -c 'su postgres -c "psql -v ON_ERROR_STOP=1 -f /tmp/init_pg_role.sql"'
# -------------------------------------------------------------------------

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

bundle install

bin/rails db:create db:migrate db:seed

nohup bin/rails server -p 3000 -b 0.0.0.0 > /tmp/rails-server.log 2>&1 &

echo "Setup complete. Rails server starting on port 3000."
