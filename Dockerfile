FROM alpine:latest

RUN apk add --no-cache curl

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install.sh | sh

# Expose the default port (can be overridden)
EXPOSE 4096

# Set default environment variables
ENV OPENCODE_HOSTNAME=0.0.0.0
ENV OPENCODE_PORT=4096

# Run the OpenCode web server
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
