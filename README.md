# n8n-ai-gen-videos-yt

A project for generating AI videos for YouTube using n8n.

## Description

This repository contains the workflows and configurations for automating the creation of AI-generated videos for YouTube using n8n.

## Getting Started

### Prerequisites

- Docker and Docker Compose
- API keys for AI services (configured via `.env`)

### Installation

1. Clone the repository and enter the project directory:
   ```bash
   git clone https://github.com/your-username/n8n-ai-gen-videos-yt.git
   cd n8n-ai-gen-videos-yt
   ```
2. Create a `.env` file with at least `N8N_ENCRYPTION_KEY`, `N8N_USER_MANAGEMENT_JWT_SECRET`, `REDIS_PASSWORD`, and your workflow API keys.

### Running n8n (Docker)

**Always run Compose from the repository root** (the directory that contains `docker-compose.yaml`). The data directories `./n8n_data` and `./redis_data` are bind-mounted with paths relative to that directory. If you run `docker compose` from another folder, Compose will use a different (often empty) `n8n_data`, and n8n will look like a fresh install.

```bash
docker compose up -d --build
```

The Compose project name is fixed as `n8n-ai-studio` so networks and services stay predictable across machines.

### Secrets and persistence

- **Do not change** `N8N_ENCRYPTION_KEY` or `N8N_USER_MANAGEMENT_JWT_SECRET` after you have stored credentials in n8n. Changing them invalidates encrypted data and sessions; it can look like everything was wiped even when the database file is still present.
- The n8n container runs as the image default user (`node`, UID 1000) so files in `n8n_data` stay consistent. If you previously ran as root and see permission errors, fix ownership once:
  ```bash
  sudo chown -R 1000:1000 n8n_data files
  ```

### Automated backups

A `backup` service builds from [Dockerfile.backup](Dockerfile.backup) and runs [scripts/backup-n8n.sh](scripts/backup-n8n.sh) on a schedule. Each run writes a timestamped folder under `./backups/` containing:

- `manifest.txt` (notes that restore needs the same encryption and JWT secrets)
- `n8n-database.sqlite` (SQLite online backup of the live database)
- `n8n_data.tar.gz` (rest of `n8n_data` without the live `database.sqlite*` files)
- `redis-dump.rdb` and `redis_data.tar.gz` (after `redis-cli SAVE`)

Optional environment variables (defaults in [docker-compose.yaml](docker-compose.yaml)):

| Variable | Default | Meaning |
|----------|---------|---------|
| `BACKUP_INTERVAL` | `300` | Seconds between backup runs |
| `BACKUP_RETENTION` | `30` | Number of backup folders to keep (oldest removed after each run) |

Manual one-off backup (same script as the service):

```bash
docker compose run --rm backup /scripts/backup-n8n.sh
```

The `./backups` directory is gitignored; copy important snapshots elsewhere if you need off-machine recovery.

### Restore from a backup

1. Stop the stack: `docker compose down`
2. Pick a backup directory under `backups/`, for example `backups/20250407-143022/`.
3. Clear or replace the live data directories (adjust paths if you use a fresh clone):
   ```bash
   rm -rf n8n_data/* redis_data/*
   ```
4. Restore n8n files from the archive, then install the consistent database file:
   ```bash
   tar -xzf backups/20250407-143022/n8n_data.tar.gz -C n8n_data
   cp backups/20250407-143022/n8n-database.sqlite n8n_data/database.sqlite
   rm -f n8n_data/database.sqlite-wal n8n_data/database.sqlite-shm
   ```
5. Restore Redis data:
   ```bash
   tar -xzf backups/20250407-143022/redis_data.tar.gz -C redis_data
   ```
6. Ensure `.env` uses the **same** `N8N_ENCRYPTION_KEY` and `N8N_USER_MANAGEMENT_JWT_SECRET` as when the backup was taken.
7. Fix ownership if needed: `sudo chown -R 1000:1000 n8n_data files redis_data`
8. Start again: `docker compose up -d --build`

## Usage

Explain how to use the n8n workflows.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
