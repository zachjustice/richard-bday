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

# Start the server
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
```bash"
# Invite a new editor by email (sends invitation email)
rake "editors:invite[email@example.com]

# Create an editor directly (for testing)
rake "editors:create[username,password,email]"

# List all editors
rake editors:list

# Delete an editor
rake editors:delete[username]
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

### Useful Commands
```bash
# View logs
kamal app logs

# Access Rails console
kamal app exec --interactive --reuse "bin/rails console"

# SSH into container
kamal app exec --interactive --reuse "bash"
```
