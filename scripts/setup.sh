#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required before setup can continue."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required before setup can continue."
  exit 1
fi

if [ -f .env ]; then
  echo ".env already exists. Leaving it untouched."
  exit 0
fi

cp .env.example .env

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi

  LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 64
}

set_env() {
  key="$1"
  value="$2"
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { FS = OFS = "=" }
    $1 == key { print key "=" value; found = 1; next }
    { print }
    END { if (!found) print key "=" value }
  ' .env > "$tmp"
  mv "$tmp" .env
}

mysql_password="$(random_hex)"
mysql_root_password="$(random_hex)"

set_env "JWT_SECRET" "$(random_hex)"
set_env "INTERNAL_TOKEN" "$(random_hex)"
set_env "CDN_API_KEY" "$(random_hex)"
set_env "AWS_SECRET_ACCESS_KEY" "$(random_hex)"
set_env "MYSQL_PASSWORD" "$mysql_password"
set_env "MYSQL_ROOT_PASSWORD" "$mysql_root_password"
set_env "DB_PASSWORD" "$mysql_password"

# Prompt for the license key (optional now; can be set later).
if [ -t 0 ]; then
  printf "Enter your rtylr license key (provided by Voxire), or leave blank to set later: "
  read -r license_key || license_key=""
  if [ -n "$license_key" ]; then
    set_env "RTYLR_LICENSE_KEY" "$license_key"
  fi
fi

echo
echo "Created .env with generated local secrets."
echo
if ! grep -Eq '^RTYLR_LICENSE_KEY=.+$' .env; then
  echo "Next: set RTYLR_LICENSE_KEY in .env, then start the stack."
fi
echo "Start (self-contained, bundles MySQL/Redis/floci):"
echo "  docker compose --profile local-infra --env-file .env up -d"
echo
echo "Or bring your own MySQL/Redis/S3: set DB_HOST / REDIS_URL / S3_* in .env"
echo "and start without the profile:"
echo "  docker compose --env-file .env up -d"
