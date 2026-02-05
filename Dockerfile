FROM alpine:latest

# Install essential tools, language runtimes, and utilities
RUN apk add --no-cache \
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
    yq \
    findutils \
    # Python
    python3 \
    py3-pip \
    # Node.js & npm
    nodejs \
    npm \
    # Go
    go

# Create non-root user
RUN addgroup -g 1000 opencode && \
    adduser -D -u 1000 -G opencode opencode

# Build argument for OpenCode version
ARG OPENCODE_VERSION=latest

# Install OpenCode CLI as root, then change ownership
RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
      curl -fsSL https://opencode.ai/install.sh | sh; \
    else \
      curl -fsSL https://opencode.ai/install.sh | sh -s -- --version $OPENCODE_VERSION; \
    fi

# Create directories for OpenCode data and set ownership
RUN mkdir -p /home/opencode/.config /home/opencode/.local && \
    chown -R opencode:opencode /home/opencode

# Expose the default port (can be overridden)
EXPOSE 4096

# Set default environment variables
ENV OPENCODE_HOSTNAME=0.0.0.0
ENV OPENCODE_PORT=4096

# Switch to non-root user
USER opencode
WORKDIR /home/opencode

# Run the OpenCode web server
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
