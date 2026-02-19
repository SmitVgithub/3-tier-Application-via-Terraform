#!/bin/bash
#
# Backend Deployment Script for Node.js Application
# This script can be run manually or via CI/CD pipeline
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
APP_DIR="${APP_DIR:-/home/ubuntu/app}"
APP_NAME="${APP_NAME:-backend}"
NODE_ENV="${NODE_ENV:-production}"

log_info "Starting deployment for $APP_NAME"
log_info "Application directory: $APP_DIR"

# Check if directory exists
if [ ! -d "$APP_DIR" ]; then
    log_error "Application directory $APP_DIR does not exist!"
    exit 1
fi

cd "$APP_DIR"

# Pull latest code if git repo
if [ -d ".git" ]; then
    log_info "Pulling latest changes from git..."
    git fetch origin
    git pull origin main
else
    log_warn "Not a git repository, skipping git pull"
fi

# Install dependencies
log_info "Installing Node.js dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci --production
else
    npm install --production
fi

# Run database migrations if script exists
if [ -f "package.json" ] && grep -q '"migrate"' package.json; then
    log_info "Running database migrations..."
    npm run migrate || log_warn "Migration script failed or not configured"
fi

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    log_error "PM2 is not installed. Installing globally..."
    sudo npm install -g pm2
fi

# Restart or start the application
log_info "Managing application process with PM2..."
if pm2 list | grep -q "$APP_NAME"; then
    log_info "Restarting existing $APP_NAME process..."
    pm2 restart "$APP_NAME" --update-env
else
    log_info "Starting new $APP_NAME process..."
    pm2 start npm --name "$APP_NAME" -- start
fi

# Save PM2 process list
pm2 save

# Display status
log_info "Current PM2 status:"
pm2 list

# Health check
log_info "Performing health check..."
sleep 5

PORT="${PORT:-3000}"
if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
    log_info "✅ Health check passed!"
elif curl -sf "http://localhost:$PORT/" > /dev/null 2>&1; then
    log_info "✅ Application is responding on port $PORT"
else
    log_warn "⚠️ Health check endpoint not responding, check application logs"
    pm2 logs "$APP_NAME" --lines 20 --nostream
fi

log_info "🎉 Deployment completed successfully!"