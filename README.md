# Private AI Chatbot and Image Generator

A private, locally-hosted AI chatbot with image generation capabilities powered by Azure OpenAI Service. Built using Open WebUI and LiteLLM proxy gateway running in Docker containers.

## Overview

This system provides a full-featured ChatGPT-like interface with:
- **Multi-model chat** - 5 Azure OpenAI models: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1
- **Image generation** - FLUX-1.1-pro integration for high-quality images
- **Minimal infrastructure** - Single 214-line Bicep file deploys everything to Azure
- **Conversation management** - Full chat history with persistence
- **Real-time streaming** - Word-by-word response rendering
- **Usage tracking** - Automatic cost and token monitoring (260 TPM total capacity)
- **Private deployment** - Runs entirely on your local machine

## Technology Stack

- **Frontend**: [Open WebUI](https://github.com/open-webui/open-webui) - Full-featured chat interface
- **Gateway**: [LiteLLM](https://github.com/BerriAI/litellm) - Azure OpenAI proxy with usage tracking
- **AI Service**: [Azure OpenAI Service](https://azure.microsoft.com/en-us/products/ai-services/openai-service) - GPT and DALL-E models
- **Orchestration**: Docker Compose - Container management
- **Storage**: SQLite (in Docker volume) - Conversation persistence

## Quick Start (10 Minutes)

### Prerequisites

- **Azure**: Azure CLI 2.50+, Bicep CLI 0.18+, active subscription with OpenAI service
- **Docker**: Docker Engine 20.10+, Docker Compose 2.0+

### Setup

#### Option 1: Deploy New Azure Infrastructure (Recommended)

1. **Deploy minimal Azure OpenAI infrastructure**
   ```bash
   cd /home/greg/dev/az-llm

   # Configure parameters
   cp infra/main.parameters.json infra/main.parameters.local.json
   nano infra/main.parameters.local.json  # Set unique openAIAccountName

   # Deploy to Azure (5-7 minutes)
   ./scripts/deploy.sh <your-resource-group> @infra/main.parameters.local.json

   # Extract outputs
   ./scripts/outputs.sh <your-resource-group>
   # Creates .env.azure-openai with 7 environment variables
   ```

   This deploys:
   - 1 Azure OpenAI Account (S0 tier)
   - 5 Model Deployments: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1
   - Total: 260 TPM capacity

   See [infra/README.md](infra/README.md) for detailed deployment guide.

2. **Configure Docker**
   ```bash
   # Environment variables already extracted to .env.azure-openai
   source .env.azure-openai

   # Start containers
   docker compose up -d
   ```

3. **Access the interface**

   Open browser to `http://localhost:3000`

   Create admin account on first visit, then start chatting with 5 models!

#### Option 2: Use Existing Azure OpenAI

If you already have Azure OpenAI deployed:

1. **Configure environment**
   ```bash
   cp .env.example .env
   nano .env  # Add your Azure endpoint and API key
   ```

2. **Update model configuration**

   Edit `docker/litellm/config.yaml` with your deployment names:
   ```yaml
   model_list:
     - model_name: gpt-4.1
       litellm_params:
         model: azure/your-gpt4-deployment-name  # ← Update this
   ```

3. **Start containers**
   ```bash
   docker compose up -d
   ```

### Verification

- **Open WebUI**: `http://localhost:3000` - Chat interface with model selector
- **LiteLLM Dashboard**: `http://localhost:4000/ui` - Usage tracking

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Browser                           │
│                   http://localhost:3000                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Open WebUI Container (Port 3000)                           │
│  - Chat interface                                           │
│  - Conversation management                                  │
│  - SQLite database (Docker volume)                          │
└────────────────────────┬────────────────────────────────────┘
                         │ OpenAI API format
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  LiteLLM Container (Port 4000)                              │
│  - OpenAI ↔ Azure API translation                          │
│  - Usage tracking and cost monitoring                       │
│  - Model routing                                            │
└────────────────────────┬────────────────────────────────────┘
                         │ Azure OpenAI API
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Azure OpenAI Service (Cloud)                               │
│  - GPT-4, GPT-3.5 Turbo deployments                         │
│  - DALL-E 3 deployment                                      │
└─────────────────────────────────────────────────────────────┘
```

## Features

### Chat Interface
- Multiple model selection (GPT-4, GPT-3.5 Turbo, custom models)
- Real-time streaming responses
- Conversation history with search
- Markdown rendering
- Code syntax highlighting
- Model switching mid-conversation

### Image Generation
- DALL-E 3 integration
- High-quality image generation (1024x1024, 1024x1792, 1792x1024)
- Image download and sharing
- Integrated into conversation flow

### Data Persistence
- All conversations saved to Docker volume
- Survives container restarts
- SQLite database (no external DB needed)

### Usage Monitoring
- Automatic token tracking
- Cost estimation per model
- Request count and latency
- LiteLLM dashboard at `http://localhost:4000/ui`

## Documentation

### Infrastructure Deployment
- **[Infrastructure README](infra/README.md)** - Minimal Bicep deployment guide (5 models, 214 lines)
- **[Quickstart Guide](specs/003-create-a-minimal/quickstart.md)** - 6 integration scenarios with examples

### Application Usage
- **[Setup Guide](docs/SETUP.md)** - Detailed setup instructions with Azure provisioning
- **[Usage Guide](docs/USAGE.md)** - Feature walkthrough and best practices
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Common Commands

```bash
# Start containers
docker compose up -d

# View logs
docker compose logs -f

# Stop containers (keeps data)
docker compose stop

# Stop and remove containers (keeps data)
docker compose down

# Remove everything including data (DESTRUCTIVE)
docker compose down -v

# Restart containers
docker compose restart
```

## Performance Expectations

| Operation | Expected Latency |
|-----------|------------------|
| Chat first token | 1-3 seconds |
| Chat full response | 5-15 seconds |
| Image generation | 60-120 seconds |
| Model switching | <1 second |
| Container startup | 30-60 seconds |

## Security Notes

- **Localhost only** - No external network access
- **API keys in .env** - Never commit .env to version control
- **No Managed Identity** - API keys required for local Docker deployment
- **Single-user** - First account has admin privileges

## Cost Management

Azure OpenAI Service charges by usage:
- **GPT-4**: ~$0.01 per 1K input tokens, ~$0.03 per 1K output tokens
- **GPT-3.5 Turbo**: ~$0.0005 per 1K input tokens, ~$0.0015 per 1K output tokens
- **DALL-E 3**: ~$0.04 per image

Monitor costs via:
- LiteLLM dashboard (`http://localhost:4000/ui`)
- Azure Portal Cost Management

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

Quick fixes:
- **Port conflict**: Change `3000:8080` to `3001:8080` in docker-compose.yml
- **Authentication failed**: Verify AZURE_API_KEY in .env
- **Model not found**: Check deployment names in litellm_config.yaml match Azure

## Contributing

This is a configuration-as-code project - no custom application code. To customize:

1. **Add models**: Edit litellm_config.yaml
2. **Change ports**: Edit docker-compose.yml
3. **Enable HTTPS**: Add reverse proxy (Nginx, Caddy)

## License

This project uses:
- [Open WebUI](https://github.com/open-webui/open-webui) - MIT License
- [LiteLLM](https://github.com/BerriAI/litellm) - MIT License

Configuration files in this repository are provided as-is.

## Support

- **Open WebUI docs**: https://docs.openwebui.com
- **LiteLLM docs**: https://docs.litellm.ai
- **Azure OpenAI docs**: https://learn.microsoft.com/azure/ai-services/openai/

---

**Project Status**: ✅ Production Ready

**Latest Features**:
- ✅ **Minimal Single-File Bicep** (Feature 003) - 214-line infrastructure for 5 Azure OpenAI models
- ✅ **5 Model Deployments** - gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1 (260 TPM)
- ✅ **TDD Validated** - 11 test scripts, contract schemas, 6 integration scenarios
- ✅ **Docker Integration** - LiteLLM config with environment variable support

Built with the [Specify Framework](https://github.com/specify-sh/specify) - Constitutional development workflow for Azure-native applications.
