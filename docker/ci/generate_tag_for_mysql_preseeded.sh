#!/usr/bin/env bash
# generate_tag_for_mysql_preseeded.sh
#
# Computes a content-addressed tag for the pre-seeded MySQL image based on:
#   - db/schema.rb (the schema definition)
#   - docker/ci/Dockerfile.mysql-preseeded
#   - MySQL version pinned in docker-compose-test-and-ci.yml
#
# This ensures the image is rebuilt only when the schema or Dockerfile changes.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SHA=$(cat \
  db/schema.rb \
  docker/ci/Dockerfile.mysql-preseeded \
  | shasum -a 256 | cut -c1-12)

echo "mysql-preseeded-${SHA}"
