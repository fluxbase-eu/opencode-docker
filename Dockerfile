FROM alpine:latest

RUN apk add --no-cache curl

# Build argument for OpenCode version
ARG OPENCODE_VERSION=latest

# Install OpenCode CLI at specified version
RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
      curl -fsSL https://opencode.ai/install.sh | sh; \
    else \
      curl -fsSL https://opencode.ai/install.sh | sh -s -- --version $OPENCODE_VERSION; \
    fi

# Expose the default port (can be overridden)
EXPOSE 4096

# Set default environment variables
ENV OPENCODE_HOSTNAME=0.0.0.0
ENV OPENCODE_PORT=4096

# Run the OpenCode web server
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
