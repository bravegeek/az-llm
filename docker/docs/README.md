# Docker Setup for az-llm

This directory contains Docker configuration and management scripts for the az-llm project.

## Directory Structure

```
docker/
├── docs/
│   └── README.md           # This file
├── litellm/
│   └── config.yaml         # LiteLLM configuration
├── openwebui/              # OpenWebUI configurations
└── scripts/
    ├── start.sh            # Start services
    ├── stop.sh             # Stop services
    ├── logs.sh             # View logs
    └── health.sh           # Check service health
```

## Quick Start

### 1. Prerequisites

- Docker Engine 20.10+
- Docker Compose V2
- Azure OpenAI Service resource

### 2. Configuration

Copy the environment template and add your Azure credentials:

```bash
cp .env.example .env
nano .env  # Edit with your Azure OpenAI credentials
```

### 3. Start Services

```bash
# Using helper script
./docker/scripts/start.sh

# Or using docker compose directly
docker compose up -d
```

### 4. Access Services

- **OpenWebUI**: http://localhost:3000
- **LiteLLM**: http://localhost:4000 (localhost only)

## Management Commands

### Start Services
```bash
./docker/scripts/start.sh
```

### Stop Services
```bash
./docker/scripts/stop.sh
# Or: docker compose down
```

### View Logs
```bash
# All services
./docker/scripts/logs.sh

# Specific service
./docker/scripts/logs.sh litellm
./docker/scripts/logs.sh openwebui
```

### Check Health
```bash
./docker/scripts/health.sh
```

### Restart Services
```bash
docker compose restart
```

### Update Images
```bash
docker compose pull
docker compose up -d
```

## Configuration Files

### docker-compose.yml
Main orchestration file defining services, networks, and volumes.

### docker/litellm/config.yaml
LiteLLM configuration for Azure OpenAI integration.

### .env
Environment variables for secrets (not committed to git).

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Validate configuration
docker compose config
```

### Health checks failing
```bash
# Check specific service logs
docker compose logs litellm

# Check if ports are in use
lsof -i :3000
lsof -i :4000
```

### Reset everything
```bash
docker compose down -v  # Warning: removes volumes
docker compose up -d
```

## Production Considerations

- Pin image versions instead of using `main` tags
- Use Docker secrets for sensitive data
- Configure proper resource limits
- Set up log rotation
- Use managed Azure services (Container Apps, AKS)
- Implement proper backup strategies for volumes

## Azure Deployment

For production Azure deployment, consider:

1. **Azure Container Instances** - Simple serverless containers
2. **Azure Container Apps** - Microservices platform with built-in scaling
3. **Azure Kubernetes Service** - Full Kubernetes orchestration

See [Azure deployment documentation](../../specs/002-azure-infrastructure-as/README.md) for details.
