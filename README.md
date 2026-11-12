# DevOps Assessment

Terraform infrastructure is organized into reusable `terraform/modules/`
modules and independent `terraform/envs/dev` and `terraform/envs/prod`
environment roots. See [terraform/README.md](terraform/README.md) for backend
setup, validation, and deployment instructions.

## Local MySQL database

1. Copy `.env.example` to `.env` and replace both sample passwords.
2. Start MySQL with `docker compose up -d`.
3. Connect to `127.0.0.1:3306` using the database and user in `.env`.

The database is exposed only on the local machine and persists in a Docker
volume. Stop it with `docker compose down`; to also permanently delete its data,
use `docker compose down --volumes`.

### Backup and restore

Create a timestamped SQL dump in the ignored `backups/` directory:

```bash
bash scripts/backup.sh
```

Restore a dump into a new database without overwriting the configured database:

```bash
bash scripts/restore.sh backups/mysql_20261112T180000Z.sql
```

The restore script starts MySQL if needed and creates a fresh database named
`app_restore_<timestamp>`. An optional second argument sets the new database
name. If that database already exists, restore stops rather than replacing it.