# OpenCode Docker

Docker image for running [OpenCode](https://opencode.ai) as a web server.

## Usage

```bash
docker run -p 4096:4096 ghcr.io/fluxbase-eu/opencode-docker:latest
```

### With Authentication

```bash
docker run -p 4096:4096 \
  -e OPENCODE_SERVER_PASSWORD=your-secret-password \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

### Custom Port

```bash
docker run -p 8080:8080 \
  -e OPENCODE_PORT=8080 \
  ghcr.io/fluxbase-eu/opencode-docker:latest
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_HOSTNAME` | Host to bind to | `0.0.0.0` |
| `OPENCODE_PORT` | Port to listen on | `4096` |
| `OPENCODE_SERVER_PASSWORD` | Optional password for authentication | (none) |
| `OPENCODE_SERVER_USERNAME` | Username for authentication | `opencode` |

## Development

The CI pipeline automatically builds and pushes images to GitHub Container Registry on pushes to `main`.
