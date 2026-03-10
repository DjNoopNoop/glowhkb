#!/usr/bin/env bash
set -euo pipefail

# Recreate and reseed production database for glowhkb
# Usage: sudo ./scripts/recreate_and_seed_prod.sh

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (or via sudo) to write backups to /root/backups"
  exit 1
fi

POSTGRES_CONTAINER=${POSTGRES_CONTAINER:-$(docker ps --filter "ancestor=postgres:16" --format '{{.Names}}' | head -n1)}
WEB_CONTAINER=${WEB_CONTAINER:-$(docker ps --format '{{.Names}} {{.Image}}' | grep -i glowhkb | grep -v postgres | awk '{print $1}' | head -n1)}

if [ -z "$POSTGRES_CONTAINER" ]; then
  echo "Postgres container not found. Set POSTGRES_CONTAINER env or ensure a postgres:16 container is running."
  exit 1
fi

if [ -z "$WEB_CONTAINER" ]; then
  echo "Web container not found. Set WEB_CONTAINER env or ensure the app container is running (image contains 'glowhkb')."
  exit 1
fi

echo "Using POSTGRES_CONTAINER=$POSTGRES_CONTAINER"
echo "Using WEB_CONTAINER=$WEB_CONTAINER"

BACKUP_DIR=/root/backups
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/pg_dump_glowhkb_production_$(date +%F_%H%M).sql.gz"

echo "Backing up existing production DB (if present) to $BACKUP_FILE"
# pg_dump will fail if DB missing; allow script to continue
docker exec "$POSTGRES_CONTAINER" bash -lc "pg_dump -U postgres glowhkb_production" | gzip -c > "$BACKUP_FILE" || true
echo "Backup finished (if DB existed): $BACKUP_FILE"

echo "Terminating connections to glowhkb_production (if any) and recreating DB"
docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='glowhkb_production';" || true
docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -c "DROP DATABASE IF EXISTS glowhkb_production;"
docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -c "CREATE DATABASE glowhkb_production OWNER postgres;"

echo "Running Rails migrations in $WEB_CONTAINER"
docker exec -it "$WEB_CONTAINER" bash -lc "RAILS_ENV=production bin/rails db:migrate"

echo "Creating admin users (idempotent) via rails runner"
docker exec -i "$WEB_CONTAINER" bash -lc 'RAILS_ENV=production bin/rails runner <<"RUBY"
users = [
  {username: "haseenaR", email: "haseena.rajeevan@gmail.com", password: "abc123!@#", role: User::ADMINISTRATOR, status: User::ACTIVE},
  {username: "dj.noopnoop", email: "rajevan.anoop@gmail.com", password: "epii22@Rajee", role: User::ADMINISTRATOR, status: User::ACTIVE}
]

users.each do |attrs|
  u = User.find_by(email: attrs[:email]) || User.find_by(username: attrs[:username])
  if u
    u.update!(username: attrs[:username], email: attrs[:email], role: attrs[:role], status: attrs[:status], password: attrs[:password])
    puts "Updated user #{attrs[:email]}"
  else
    User.create!(attrs)
    puts "Created user #{attrs[:email]}"
  end
end
RUBY'

echo "Running import:all rake task"
docker exec -it "$WEB_CONTAINER" bash -lc "RAILS_ENV=production bin/rails import:all"

echo "Completed. Backup: $BACKUP_FILE"

exit 0
