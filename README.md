# Richard Birthday App

A Rails application for managing birthday party games and activities.

## Development Setup

### Prerequisites
- Ruby 3.4.1
- SQLite3

### Local Development
```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start the server
bin/rails server
```

## Deployment to Digital Ocean

This application is configured for deployment to Digital Ocean using Kamal with GitHub Actions for continuous deployment.

### Prerequisites
- Digital Ocean Ubuntu 22.04 droplet
- GitHub repository with Actions enabled
- GitHub Personal Access Token with packages:write permission

### Server Setup

1. **Run the setup script on your Digital Ocean droplet:**
   ```bash
   # Copy the setup script to your server
   scp server-setup.sh root@YOUR_DROPLET_IP:/tmp/
   
   # SSH into your server and run the setup
   ssh root@YOUR_DROPLET_IP
   chmod +x /tmp/server-setup.sh
   /tmp/server-setup.sh
   ```

2. **Log out and back in** for Docker group changes to take effect.

### Configuration

3. **Set up GitHub Repository Secrets:**
   Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:
   - `DEPLOY_SSH_KEY`: Private SSH key for server access
   - `RAILS_MASTER_KEY`: Rails credentials master key
   - `GHCR_TOKEN`: GitHub Personal Access Token with packages:write scope
   - `DROPLET_IP`: Digital Ocean droplet IP address

### Deployment

1. **Generate SSH key pair for deployment:**
   ```bash
   ssh-keygen -t ed25519 -C "deploy@richard-bday"
   # Copy the public key to your server's ~/.ssh/authorized_keys
   # Add the private key to GitHub Secrets as DEPLOY_SSH_KEY
   ```

2. **Push to main branch:**
   ```bash
   git add .
   git commit -m "Deploy to Digital Ocean"
   git push origin main
   ```

3. **Monitor deployment:**
   - Check GitHub Actions tab for deployment progress
   - Access your app at `http://YOUR_DROPLET_IP`

### Manual Deployment (if needed)
```bash
# Install Kamal locally
gem install kamal

# Deploy manually
kamal deploy
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

## Architecture

- **Framework:** Ruby on Rails 8.0
- **Database:** SQLite3 (production-ready with solid_cache, solid_queue, solid_cable)
- **Web Server:** Puma with Thruster
- **Deployment:** Kamal with Docker containers
- **CI/CD:** GitHub Actions
- **Container Registry:** GitHub Container Registry (ghcr.io)
