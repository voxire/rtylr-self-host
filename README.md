# rtylr Self-Host

Public installer for running rtylr on customer-owned infrastructure, via a
**Helm chart** (primary) or **Docker Compose**.

This repo contains no product source code. It pulls public Docker images from
the `rtylr` Docker Hub namespace and wires together the API, worker, upload
service, and all frontends, with optional bundled MySQL, Redis, and floci
object storage.

## What you get

- Backend: `rtylr/api` (9999), `rtylr/worker`, `rtylr/upload` (8080)
- 11 frontends: `auth`, `dash`, `pos`, `erp`, `hr`, `crm`, `finance`, `flow`,
  `insights`, `recruit`, `menu`
- Optional bundled datastores (MySQL, Redis, floci S3) — or bring your own

The **only** external dependency is the hosted license authority
`https://license.voxire.com`, which the backend contacts to validate your
license key. See [docs/license.md](docs/license.md).

## Requirements

- A license key from Voxire sales (set as `RTYLR_LICENSE_KEY`)
- Helm 3.8+ and a Kubernetes cluster, **or** Docker + Compose v2

## Quick Start — Helm (primary)

```bash
helm upgrade --install rtylr ./helm/rtylr \
  --set image.tag=1.0.0 \
  --set-string license.key=YOUR_LICENSE_KEY \
  --set-string secrets.jwtSecret=$(openssl rand -hex 32) \
  --set ingress.domain=example.com
```

Add `--set localInfra.mysql.enabled=true` (etc.) to bundle datastores, or point
`database.*` / `redis.url` / `s3.*` at your own. Full reference:
[docs/helm.md](docs/helm.md).

## Quick Start — Docker Compose

```bash
./scripts/setup.sh   # creates .env, generates secrets, prompts for license key

# Self-contained (bundles MySQL/Redis/floci):
docker compose --profile local-infra --env-file .env up -d

# Or bring your own MySQL/Redis/S3 (set DB_HOST/REDIS_URL/S3_* in .env):
docker compose --env-file .env up -d

./scripts/doctor.sh  # validate the install
```

Local URLs (with `RTYLR_DOMAIN=localhost`): `http://dash.localhost`,
`http://auth.localhost`, `http://api.localhost`, `http://upload.localhost`, and
one per app. Full reference: [docs/compose.md](docs/compose.md).

## Configuration

Every app URL is configurable (no hosted domains are hardcoded). Set
`RTYLR_LICENSE_KEY`, `DEPLOYMENT_MODE=self_hosted`, the app URLs, and your
datastore config. See [docs/backend-env.md](docs/backend-env.md).

## Versioning

A single `RTYLR_VERSION` (in `versions.env`, e.g. `1.0.0`) pins all images to
the same tag. Upgrade with `./scripts/update.sh <version>` (Compose) or
`--set image.tag=<version>` (Helm). See [docs/upgrade.md](docs/upgrade.md).

## Backups

```bash
./scripts/backup.sh   # dumps bundled MySQL + archives floci storage to backups/
```

When using your own MySQL/S3, back those up with your provider's tooling.

## Documentation

- [Architecture](docs/architecture.md)
- [License flow](docs/license.md)
- [DNS setup](docs/dns.md)
- [Helm install](docs/helm.md)
- [Compose reference](docs/compose.md)
- [Backend env reference](docs/backend-env.md)
- [Image list](docs/images.md)
- [Upgrade flow](docs/upgrade.md)

## Notes

- Upload traffic goes to the upload service (`UPLOAD_URL`), not the API service.
- There is no license service to run — the backend validates against
  `https://license.voxire.com`.
- Keep `.env` private. It contains database passwords, service tokens, upload
  keys, and the license key.
