#!/usr/bin/env bash
set -euo pipefail

# Bump the global RTYLR_VERSION (pins all images) and roll the stack.
# Usage:
#   ./scripts/update.sh             # pull + restart at the current pinned version
#   ./scripts/update.sh 3.300.14    # set RTYLR_VERSION=3.300.14, then pull + restart

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f .env ]; then
  echo ".env missing; run ./scripts/setup.sh first."
  exit 1
fi

set_version() {
  file="$1"
  version="$2"
  tmp="$(mktemp)"
  awk -v value="$version" '
    BEGIN { found = 0 }
    /^RTYLR_VERSION=/ { print "RTYLR_VERSION=" value; found = 1; next }
    { print }
    END { if (!found) print "RTYLR_VERSION=" value }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

if [ "$#" -ge 1 ]; then
  new_version="$1"
  echo "Pinning RTYLR_VERSION=${new_version}"
  set_version versions.env "$new_version"
  set_version .env "$new_version"
fi

# Detect whether the bundled local-infra is in use (db service present in .env).
profile_args=()
if grep -Eq '^DB_HOST=db$' .env; then
  profile_args=(--profile local-infra)
fi

docker compose "${profile_args[@]}" --env-file .env pull
docker compose "${profile_args[@]}" --env-file .env up -d

current_version="$(grep -E '^RTYLR_VERSION=' .env | head -n1 | cut -d= -f2-)"
echo "Updated rtylr self-host stack to RTYLR_VERSION=${current_version}."
