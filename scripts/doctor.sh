#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0

pass() {
  echo "[ok] $1"
}

warn() {
  echo "[warn] $1"
}

fail() {
  echo "[fail] $1"
  failures=$((failures + 1))
}

if command -v docker >/dev/null 2>&1; then
  pass "docker cli found"
else
  fail "docker cli not found"
fi

if docker compose version >/dev/null 2>&1; then
  pass "docker compose v2 found"
else
  fail "docker compose v2 not available"
fi

if docker info >/dev/null 2>&1; then
  pass "docker daemon reachable"
else
  fail "docker daemon not reachable"
fi

if [ -f .env ]; then
  pass ".env exists"
else
  fail ".env missing; run ./scripts/setup.sh"
fi

if [ -f .env ]; then
  if grep -Eq '^RTYLR_LICENSE_KEY=.+$' .env; then
    pass "RTYLR_LICENSE_KEY is set"
  else
    warn "RTYLR_LICENSE_KEY is not set — set the license key Voxire provided"
  fi

  if grep -Eq '^JWT_SECRET=change_me' .env || ! grep -Eq '^JWT_SECRET=.{32,}$' .env; then
    fail "JWT_SECRET is missing or too short; run ./scripts/setup.sh to generate one"
  else
    pass "JWT_SECRET looks set"
  fi

  if grep -Eq '^DEPLOYMENT_MODE=self_hosted$' .env; then
    pass "DEPLOYMENT_MODE=self_hosted"
  else
    warn "DEPLOYMENT_MODE is not self_hosted"
  fi
fi

if [ -f .env ]; then
  if docker compose --env-file .env config >/dev/null 2>&1; then
    pass "compose config is valid (external infra)"
  else
    fail "compose config is invalid"
  fi
  if docker compose --profile local-infra --env-file .env config >/dev/null 2>&1; then
    pass "compose config is valid (local-infra profile)"
  else
    fail "compose config (local-infra) is invalid"
  fi
fi

if [ "$failures" -gt 0 ]; then
  echo
  echo "$failures required check(s) failed."
  exit 1
fi

echo
echo "Self-host checks passed."
