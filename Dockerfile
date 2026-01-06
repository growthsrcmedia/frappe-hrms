FROM frappe/bench:latest

USER frappe
WORKDIR /home/frappe

# Initialize bench
RUN bench init --skip-redis-config-generation --skip-assets --python python3 frappe-bench

WORKDIR /home/frappe/frappe-bench

# Install erpnext
RUN bench get-app erpnext --skip-assets

# Copy the local hrms app into the bench
# Note: Dokploy will have the repo content in the build context
COPY --chown=frappe:frappe . ./apps/hrms

# Install the local app
RUN bench get-app hrms --skip-assets

# Build assets
RUN bench build

# Copy our custom init script
COPY --chown=frappe:frappe ./docker/init.sh /home/frappe/init.sh
RUN chmod +x /home/frappe/init.sh

ENTRYPOINT ["/home/frappe/init.sh"]
