FROM debian:bookworm-slim

# Install essential tools, language runtimes, and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essentials
    curl \
    ca-certificates \
    bash \
    git \
    # Text editors
    vim \
    nano \
    # Utilities
    jq \
    findutils \
    # Go
    golang-go \
    # Python
    python3 \
    python3-pip \
    # Node.js & npm (from Debian repos for better compatibility)
    nodejs \
    npm \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install yq (prebuilt binary with multi-arch support)
RUN YQ_VERSION=v4.40.5 && \
    ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) YQ_ARCH="amd64" ;; \
        aarch64) YQ_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -L -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" && \
    chmod +x /usr/local/bin/yq

# Create non-root user
RUN groupadd -g 1000 opencode && \
    useradd -u 1000 -g opencode -m -s /bin/bash opencode

# Build argument for OpenCode version
ARG OPENCODE_VERSION=latest

# Install OpenCode CLI as root, then fix ownership
RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
      npm install -g opencode-ai; \
    else \
      npm install -g opencode-ai@$OPENCODE_VERSION; \
    fi && \
    chown -R opencode:opencode /usr/local/lib/node_modules /usr/local/bin/opencode

# Create directories that OpenCode needs
RUN mkdir -p /home/opencode/.config /home/opencode/.local/share /home/opencode/.local/state && \
    chown -R opencode:opencode /home/opencode

# Create entrypoint to fix volume permissions at startup
RUN echo '#!/bin/bash' > /usr/local/bin/opencode-entrypoint.sh && \
    echo '# Fix ownership of any root-owned directories' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo 'for dir in .config .local .local/share .local/state .local/share/opencode workspace; do' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '  dir_path="/home/opencode/$dir"' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '  if [ -d "$dir_path" ] && [ "$(stat -c %U "$dir_path" 2>/dev/null)" = "root" ]; then' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '    chown -R opencode:opencode "$dir_path"' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '  fi' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo 'done' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo '# Drop privileges and run as opencode user' >> /usr/local/bin/opencode-entrypoint.sh && \
    echo 'exec su - opencode -c "$*"' >> /usr/local/bin/opencode-entrypoint.sh && \
    chmod +x /usr/local/bin/opencode-entrypoint.sh

# Expose the default port (can be overridden)
EXPOSE 4000

# Set default environment variables
ENV OPENCODE_HOSTNAME=0.0.0.0
ENV OPENCODE_PORT=4000

# Don't switch users here - entrypoint handles it
WORKDIR /home/opencode/workspace

# Run the OpenCode web server via entrypoint
ENTRYPOINT ["/usr/local/bin/opencode-entrypoint.sh", "opencode", "web", "--hostname", "0.0.0.0", "--port", "4000"]
