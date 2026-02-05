# OpenCode Docker

Docker image for running [OpenCode](https://opencode.ai) as a web server.

## Features

- **Rootless container**: Runs as non-root user (UID 1000) for enhanced security
- **Pre-installed tools**: Includes common development tools:
  - **Essentials**: git, curl, bash, ca-certificates
  - **Editors**: vim, nano
  - **Utilities**: jq, yq, findutils
  - **Language runtimes**: Python 3 + pip, Node.js + npm, Go
- **Persistent data**: Volume mounts for configuration, sessions, and workspace

## Usage

```bash
docker run -p 4096:4096 ghcr.io/fluxbase-eu/opencode-docker:latest
```

### With Volume Mount (Recommended)

Mount a local directory to `/workspace` to persist your work:

```bash
docker run -p 4096:4096 \
  -v $(pwd)/workspace:/workspace \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

### With Authentication

```bash
docker run -p 4096:4096 \
  -v $(pwd)/workspace:/workspace \
  -e OPENCODE_SERVER_PASSWORD=your-secret-password \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

### Custom Port

```bash
docker run -p 8080:8080 \
  -v $(pwd)/workspace:/workspace \
  -e OPENCODE_PORT=8080 \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

## Environment Variables

### Server Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_HOSTNAME` | Host to bind to | `0.0.0.0` |
| `OPENCODE_PORT` | Port to listen on | `4096` |
| `OPENCODE_SERVER_PASSWORD` | Optional password for authentication | (none) |
| `OPENCODE_SERVER_USERNAME` | Username for authentication | `opencode` |

### OpenCode Configuration

OpenCode can be configured using environment variables (see [OpenCode Config Docs](https://opencode.ai/docs/config/)):

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENCODE_CONFIG` | Path to custom config file | `/path/to/config.json` |
| `OPENCODE_CONFIG_CONTENT` | Inline JSON configuration | `{"model":"anthropic/claude-sonnet-4-5"}` |
| `OPENCODE_CONFIG_DIR` | Custom config directory for agents/commands | `/path/to/config-dir` |
| `OPENCODE_MODEL` | Default model to use | `anthropic/claude-sonnet-4-5` |
| `OPENCODE_SMALL_MODEL` | Model for lightweight tasks | `anthropic/claude-haiku-4-5` |
| `ANTHROPIC_API_KEY` | Anthropic API key | `sk-ant-...` |
| `OPENCODE_AUTOUPDATE` | Enable auto-updates | `true` |
| `OPENCODE_SHARE` | Sharing behavior | `manual` |

#### Configuration Examples

**Recommended: Using a config file with environment variable substitution**

The repository includes `opencode.json` with environment variable placeholders.

Run with environment variables:
```bash
docker run -p 4096:4096 \
  -v $(pwd)/opencode.json:/etc/opencode/opencode.json:ro \
  -e OPENCODE_MODEL=anthropic/claude-sonnet-4-5 \
  -e ANTHROPIC_API_KEY=sk-ant-your-key-here \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

**The config file uses `{env:VAR_NAME}` syntax to reference environment variables:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "{env:OPENCODE_MODEL}",
  "small_model": "{env:OPENCODE_SMALL_MODEL}",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}",
        "timeout": 300000
      }
    }
  },
  "tools": {
    "bash": true,
    "write": true,
    "edit": true
  }
}
```

**Using Docker Compose:**
```bash
# Create .env file from example
cp .env.example .env
# Edit .env and add your API keys

# Start OpenCode
docker-compose up -d
```

For more configuration options, see the [OpenCode documentation](https://opencode.ai/docs/config/).

## Persistent Data

OpenCode stores data in three locations that should be persisted for a better user experience:

| Path | Purpose |
|------|---------|
| `/home/opencode/.config/opencode` | Global configuration and user preferences |
| `/home/opencode/.local/share/opencode` | Session storage, cache, and authentication credentials |
| `/workspace` | Working directory for projects |

### Volume Mount Examples

#### Minimal (workspace only)
```bash
docker run -p 4096:4096 \
  -v $(pwd)/workspace:/workspace \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

#### Full persistence (recommended)
```bash
docker run -p 4096:4096 \
  -v opencode-config:/home/opencode/.config/opencode \
  -v opencode-data:/home/opencode/.local/share/opencode \
  -v opencode-workspace:/workspace \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

## Docker Compose

Docker Compose is recommended for easy deployment with all persistent volumes properly configured.

### Basic Usage

```bash
# Clone the repository
git clone https://github.com/fluxbase-eu/opencode-docker.git
cd opencode-docker

# Start OpenCode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop OpenCode
docker-compose down
```

### Configuration

1. Copy the example config file:
   ```bash
   cp opencode.json.example opencode.json
   ```

2. Create a `.env` file with your credentials:
   ```env
   # Model configuration
   OPENCODE_MODEL=anthropic/claude-sonnet-4-5
   OPENCODE_SMALL_MODEL=anthropic/claude-haiku-4-5

   # API keys (required for your chosen provider)
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```

3. Optionally customize `opencode.json` for your needs - it uses `{env:VAR_NAME}` placeholders.

### Custom Port

```bash
OPENCODE_PORT=8080 docker-compose up -d
```

## Kubernetes / Helm

A Helm chart is provided for Kubernetes deployments.

### Installation

```bash
# Install from local directory
helm install opencode ./helm/opencode

# Install from GitHub releases
helm install opencode oci://ghcr.io/fluxbase-eu/helm-charts/opencode

# Or download specific version from releases
helm install opencode https://github.com/fluxbase-eu/opencode-docker/releases/download/helm-v0.1.0/opencode-0.1.0.tgz

# With custom values
helm install opencode ./helm/opencode -f custom-values.yaml
```

**Note**: The Helm chart uses semantic versioning and is automatically published when changes are made to the `helm/opencode/` directory.

### Configuration

The Helm chart creates a ConfigMap with OpenCode configuration and uses Kubernetes secrets for API keys.

#### 1. Create secrets for your API keys:

```bash
# Create secret for Anthropic API key
kubectl create secret generic opencode-credentials \
  --from-literal=anthropic-api-key=sk-ant-your-key-here

# Optional: Add keys for other providers
kubectl create secret generic opencode-credentials \
  --from-literal=anthropic-api-key=sk-ant-your-key-here \
  --from-literal=openai-api-key=sk-your-openai-key \
  --from-literal=gemini-api-key=your-gemini-key \
  --from-literal=google-api-key=your-google-key \
  --from-literal=openrouter-api-key=your-openrouter-key \
  --dry-run=client -o yaml | kubectl apply -f -
```

#### 2. Configure via `values.yaml` or custom values file:

```yaml
# OpenCode configuration
opencode:
  model: "anthropic/claude-sonnet-4-5"
  smallModel: "anthropic/claude-haiku-4-5"
  autoupdate: true
  share: "manual"

  # Provider configuration
  provider:
    anthropic:
      options:
        timeout: 300000

    # Enable additional providers as needed
    # openai:
    #   options:
    #     timeout: 300000
    # gemini:
    #   options:
    #     timeout: 300000
    # awsBedrock:
    #   options:
    #     region: "us-east-1"

  # Tools configuration
  tools:
    bash: true
    write: true
    edit: true

# Secret references (API keys)
secrets:
  anthropicApiKey:
    name: opencode-credentials
    key: anthropic-api-key
    enabled: true

  # Enable additional providers
  # openaiApiKey:
  #   name: opencode-credentials
  #   key: openai-api-key
  #   enabled: true
  # geminiApiKey:
  #   name: opencode-credentials
  #   key: gemini-api-key
  #   enabled: true

# Extra environment variables if needed
extraEnv: []
# - name: CUSTOM_VAR
#   value: "custom-value"

# Service configuration
service:
  type: ClusterIP
  port: 4096

# Resources
resources:
  limits:
    cpu: 2
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi

# Ingress (optional)
ingress:
  enabled: false
  hosts:
    - host: opencode.example.com
```

#### 3. Install the chart:

```bash
helm install opencode ./helm/opencode -f custom-values.yaml
```

### Common Operations

```bash
# Upgrade release
helm upgrade opencode ./helm/opencode

# Uninstall release
helm uninstall opencode

# Port forward to access locally
kubectl port-forward svc/opencode 4096:4096
```

### Persistent Volume Claims

The Helm chart creates three PVCs:

- `opencode-config` - Configuration and preferences (1Gi)
- `opencode-data` - Sessions and cache (1Gi)
- `opencode-workspace` - Project workspace (1Gi)

These can be customized in `values.yaml`.

## Security

The container runs as a non-root user for enhanced security:

- **User**: `opencode` (UID 1000)
- **Group**: `opencode` (GID 1000)
- **Home directory**: `/home/opencode`
- **Security context**: The Helm chart enforces `runAsNonRoot: true` and drops all capabilities

This follows container security best practices and limits the potential impact of a container compromise.

## Backup Considerations

For production deployments, consider implementing a backup strategy for your persistent data:

- **Docker volumes**: Use `docker volume` commands or a backup solution
- **Kubernetes PVCs**: Use Velero, your cloud provider's backup solution, or regular snapshots
- **Important data**:
  - `/home/opencode/.local/share/opencode` - Contains active sessions and credentials
  - `/home/opencode/.config/opencode` - Contains user preferences and settings
  - `/workspace` - Contains your project files

## Development

The CI pipeline includes two automated workflows:

1. **Build and Push** (`.github/workflows/build.yml`): Builds and pushes Docker images to GitHub Container Registry on pushes to `main`. Also checks for new OpenCode versions daily and creates releases automatically.

2. **Helm Chart Publish** (`.github/workflows/helm-publish.yml`): Automatically publishes Helm chart updates when changes are detected in the `helm/opencode/` directory. Uses semantic versioning with auto-detection of version bump type (patch/minor/major) based on commit messages.
