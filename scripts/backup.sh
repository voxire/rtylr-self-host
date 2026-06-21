#!/usr/bin/env bash
set -euo pipefail

# Backs up the MySQL database and the local floci object storage.
# When you bring your own MySQL/S3, back those up with your provider's tooling
# instead — this script targets the bundled local-infra services.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f .env ]; then
  echo ".env missing; run ./scripts/setup.sh first."
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="backups/${timestamp}"
mkdir -p "$backup_dir"

if docker compose --profile local-infra --env-file .env ps db --status running >/dev/null 2>&1 \
   && [ -n "$(docker compose --profile local-infra --env-file .env ps -q db 2>/dev/null)" ]; then
  echo "Dumping MySQL database..."
  docker compose --profile local-infra --env-file .env exec -T db \
    sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > "${backup_dir}/mysql.sql"
else
  echo "Bundled MySQL not running; skipping DB dump (back up your external MySQL separately)."
fi

# Find the floci data volume by its compose volume label (project-prefixed name).
floci_volume="$(docker volume ls --format '{{.Name}}' | grep -E '_floci_data$' | head -n1 || true)"
if [ -n "$floci_volume" ]; then
  echo "Archiving floci object storage (volume: ${floci_volume})..."
  docker run --rm \
    -v "${floci_volume}:/data:ro" \
    -v "${repo_root}/${backup_dir}:/backup" \
    alpine:3.20 \
    tar -czf /backup/floci.tgz -C /data .
else
  echo "No bundled floci volume found; skipping object-storage archive."
fi

echo "Backup written to ${backup_dir}"
