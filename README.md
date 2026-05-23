# Blanksies

A Rails application for playing collaborative fill-in-the-blank stories with friends.

## Development Setup

### Prerequisites
- Ruby 3.4.1
- SQLite3
- Foreman

### Local Development
```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Setup RAILS_MASTER_KEY
# Copy over config/master.key or create a new one

# Start the server; use ./bin/dev for tailwindcss
./bin/dev
```

### Manual Deployment (if needed)
```bash
# Install Kamal locally
gem install kamal

# Deploy manually
kamal deploy
```

### Editor Management
```bash
# Invite a new editor by email (sends invitation email)
bundle exec rake "editors:invite[email@example.com]"

# Create an editor directly (for testing)
bundle exec rake "editors:create[username,password,email]"

# List all editors
bundle exec rake editors:list

# Delete an editor
bundle exec rake editors:delete[username]
```

### Database Backup & Restore
```bash
# Backup
bin/backup-db development
bin/backup-db production

# Restore
bin/restore-db development backups/development_backup_20260207_143000.sqlite3
bin/restore-db production backups/production_backup_20260207_143000.sqlite3
```

### Scaling Notes

The production droplet is a 1 GB / 1 vCPU DigitalOcean instance, which is tight for
Rails 8 + Solid Queue. A few things are trimmed to fit and should be reversed when
the droplet is sized up:

- `config/deploy.yml` — Bump up `WEB_CONCURRENCY: 0` (Puma single mode), `JOB_CONCURRENCY: 1`,
  `RAILS_MAX_THREADS: 4`. The commented-out `job:` role can be enabled for a dedicated
  jobs container (also flip `SOLID_QUEUE_IN_PUMA` to false in that case).
- `config/queue.yml` — Solid Queue workers run with `threads: 2`. Bump back to 3+ when
  RAM allows.
- `config/recurring.yml` — recurring jobs are disabled in production to avoid spawning
  a Solid Queue scheduler process (~150 MB). Until re-enabled, run these manually:
  ```bash
  kamal app exec --reuse "bin/rails runner 'SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)'"
  kamal app exec --reuse "bin/rails runner 'CleanupExpiredTokensJob.perform_now'"
  ```

The droplet also has a 1 GB swapfile and the Dockerfile preloads jemalloc (cuts Ruby
RSS ~25-40%).

Once on a 2 GB+ host, the right order to undo these is to (1) re-enable
`recurring.yml` (2) bump worker threads and (3) enable the `job:` role.

### Useful Commands
```bash
# View logs
kamal app logs

# Access Rails console
kamal app exec --interactive --reuse "bin/rails console"

# SSH into container
kamal app exec --interactive --reuse "bash"
```
