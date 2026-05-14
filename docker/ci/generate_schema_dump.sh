#!/usr/bin/env bash
# generate_schema_dump.sh
#
# Generates a SQL dump from db/schema.rb by:
#   1. Starting a temporary MySQL container
#   2. Running db:schema:load via the Rails app (in the test Docker image)
#   3. Dumping the resulting schema as SQL
#   4. Outputting schema_dump.sql for the pre-seeded image build
#
# Usage: docker/ci/generate_schema_dump.sh <test_image_tag>
#
# Requires: docker, the test image already built

set -euo pipefail

TEST_IMAGE="${1:?Usage: $0 <test_image_tag>}"
NETWORK="schema-dump-$$"
MYSQL_CONTAINER="schema-dump-mysql-$$"
DUMP_FILE="docker/ci/schema_dump.sql"

cleanup() {
  docker rm -f "$MYSQL_CONTAINER" 2>/dev/null || true
  docker network rm "$NETWORK" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Creating network..."
docker network create "$NETWORK"

echo "==> Starting temporary MySQL..."
docker run -d --name "$MYSQL_CONTAINER" --network "$NETWORK" \
  --tmpfs /var/lib/mysql:size=512M \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=gumroad_test \
  mysql:8.0.32 \
  mysqld \
    --default-authentication-plugin=mysql_native_password \
    --collation-server=utf8mb4_unicode_ci \
    --character-set-server=utf8mb4 \
    --innodb-flush-log-at-trx-commit=0 \
    --innodb-doublewrite=0 \
    --sync-binlog=0 \
    --innodb-flush-method=nosync \
    --skip-log-bin

echo "==> Waiting for MySQL..."
until docker exec "$MYSQL_CONTAINER" mysqladmin ping -h localhost -uroot -ppassword --silent 2>/dev/null; do
  sleep 1
done
echo "MySQL ready."

echo "==> Running db:schema:load..."
docker run --rm --entrypoint="" --network "$NETWORK" \
  -e RAILS_ENV=test \
  -e DATABASE_HOST="$MYSQL_CONTAINER" \
  -e DATABASE_NAME=gumroad_test \
  -e DATABASE_PORT=3306 \
  -e DATABASE_USERNAME=root \
  -e DATABASE_PASSWORD=password \
  "$TEST_IMAGE" \
  bundle exec rake db:schema:load

echo "==> Dumping schema..."
docker exec "$MYSQL_CONTAINER" \
  mysqldump -uroot -ppassword \
    --no-data \
    --routines \
    --triggers \
    --skip-comments \
    --skip-lock-tables \
    gumroad_test > "$DUMP_FILE"

echo "==> Schema dump written to $DUMP_FILE ($(wc -l < "$DUMP_FILE") lines)"
