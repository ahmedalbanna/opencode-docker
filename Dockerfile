FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy opencode binary from host directly
COPY --from=/home/frappe/.opencode/bin/opencode /usr/local/bin/opencode

# Create directories for opencode data
RUN mkdir -p /home/frappe/opencode-docker/storage \
    /home/frappe/opencode-docker/config \
    /home/frappe/opencode-docker/logs

# Set up opencode environment paths
ENV OPENCODE_DATA_DIR=/home/frappe/opencode-docker/storage \
    OPENCODE_CONFIG_DIR=/home/frappe/opencode-docker/config

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose configurable port
EXPOSE 8080

ENTRYPOINT ["entrypoint.sh"]