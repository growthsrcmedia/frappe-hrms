#!/bin/bash

# Exit on error
set -e

# Use the path to the bench
BENCH_DIR="/home/frappe/frappe-bench"
cd "$BENCH_DIR"

# Ensure common_site_config.json exists (in case sites volume is empty)
if [ ! -f "sites/common_site_config.json" ]; then
    echo "Initializing common_site_config.json..."
    echo '{}' > sites/common_site_config.json
fi

# Configure hosts (idempotent)
echo "Configuring database and redis hosts..."
bench set-mariadb-host "${DB_HOST:-mariadb}"
bench set-redis-cache-host "redis://${REDIS_CACHE:-redis:6379}"
bench set-redis-queue-host "redis://${REDIS_QUEUE:-redis:6379}"
bench set-redis-socketio-host "redis://${REDIS_SOCKETIO:-redis:6379}"

# Remove redis, watch from Procfile (handled by other services/containers)
if [ -f "./Procfile" ]; then
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile
fi

# Site setup
SITE_NAME="${SITE_NAME:-hrms.localhost}"

if [ ! -d "sites/$SITE_NAME" ]; then
    echo "Creating site $SITE_NAME..."
    # Attempt to create site
    bench new-site "$SITE_NAME" \
        --mariadb-root-password "${DB_ROOT_PASSWORD:-123}" \
        --admin-password "${ADMIN_PASSWORD:-admin}" \
        --no-mariadb-socket
    
    echo "Installing hrms app..."
    bench --site "$SITE_NAME" install-app hrms
    
    if [ "${DEVELOPER_MODE}" = "1" ]; then
        bench --site "$SITE_NAME" set-config developer_mode 1
    fi
    
    bench --site "$SITE_NAME" enable-scheduler
else
    echo "Site $SITE_NAME exists. Running migrations..."
    bench --site "$SITE_NAME" migrate
fi

bench use "$SITE_NAME"

echo "Starting Bench..."
bench start