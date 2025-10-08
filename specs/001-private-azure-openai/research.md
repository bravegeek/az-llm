# Research: Private AI Chatbot and Image Generator

**Date**: 2025-10-08
**Feature**: 001-private-azure-openai
**Purpose**: Research Open WebUI, LiteLLM, and Azure OpenAI integration for local Docker deployment

---

## Research Questions

### 1. Open WebUI Deployment Best Practices

**Decision**: Use official Docker image `ghcr.io/open-webui/open-webui:main`

**Rationale**:
- Official maintained image with regular updates
- Built-in SQLite database for data persistence
- Volume mount for conversation history preservation
- Native OpenAI API compatibility (connects to LiteLLM as OpenAI proxy)
- Web interface on port 8080 (mapped to host 3000)

**Alternatives Considered**:
- Building from source → Rejected: Adds complexity, requires Node.js/Python environment
- Using older `ollama-webui` image → Rejected: Deprecated, renamed to Open WebUI
- Running without Docker → Rejected: Doesn't meet NFR-001 (Docker deployment required)

**Key Configuration**:
- Environment variable `OPENAI_API_BASE` points to LiteLLM proxy (http://litellm:4000/v1)
- Data persisted in named Docker volume `open-webui`
- First-run creates admin account (no pre-configuration needed)

---

### 2. LiteLLM Proxy Configuration for Azure OpenAI

**Decision**: Use `ghcr.io/berriai/litellm:main-latest` with YAML configuration file

**Rationale**:
- Unified gateway for multiple Azure OpenAI deployments
- Automatic usage tracking (tokens, costs, requests) - satisfies FR-009
- OpenAI-compatible API format (no Open WebUI modifications needed)
- Configuration-as-code via `litellm_config.yaml`
- Built-in dashboard on `/ui` for usage analytics

**Alternatives Considered**:
- Direct Open WebUI to Azure OpenAI → Rejected: Azure API format differs from OpenAI (uses `/deployments` endpoint)
- Using LiteLLM Python SDK in custom app → Rejected: Violates simplicity principle (no custom code needed)
- Using Azure AI Proxy → Rejected: Adds another dependency, LiteLLM sufficient

**Key Configuration**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: azure/gpt-4-turbo
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
```

**Authentication Options**:
- API Key (via environment variables) - chosen for simplicity
- Azure DefaultAzureCredential - future enhancement for Azure Container Instances deployment

---

### 3. Azure OpenAI Service Requirements

**Decision**: Use existing Azure OpenAI resource with deployed models

**Rationale**:
- Requires pre-provisioned Azure OpenAI Service instance
- Models must be pre-deployed (not auto-provisioned)
- API key and endpoint URL required
- API version 2024-02-01 or later for latest features

**Required Azure Resources**:
1. Azure OpenAI Service instance (e.g., `your-resource.openai.azure.com`)
2. Deployed models:
   - GPT-4 Turbo (for advanced chat)
   - GPT-3.5 Turbo (for faster, cost-effective chat)
   - DALL-E 3 (for image generation)
3. API key with appropriate permissions

**Alternatives Considered**:
- Using OpenAI directly (non-Azure) → Rejected: Spec requires Azure OpenAI Service
- Provisioning via Bicep/ARM → Rejected: Out of scope for configuration-only project
- Using Azure AI Studio → Rejected: Azure OpenAI Service sufficient

**Prerequisites**:
- Active Azure subscription
- Azure OpenAI Service access (requires approval)
- Quota for desired models
- Network connectivity from local machine to Azure

---

### 4. Docker Compose Orchestration Pattern

**Decision**: Use docker-compose v3.8 with named volumes and environment variable injection

**Rationale**:
- Simple single-file orchestration (docker-compose.yml)
- Named volumes preserve data across container restarts (NFR-006)
- Environment variables from .env file for secrets (NFR-010)
- Container networking allows Open WebUI → LiteLLM communication via service names
- Health checks for container availability

**Best Practices Applied**:
- Use named volumes (not bind mounts) for database persistence
- .env file for secrets (excluded from git via .gitignore)
- .env.example template for setup instructions
- Container dependencies via `depends_on`
- Explicit port mappings (3000:8080 for Open WebUI, 4000:4000 for LiteLLM)

**Alternatives Considered**:
- Separate `docker run` commands → Rejected: Less maintainable, no orchestration
- Kubernetes → Rejected: Overkill for single-user local deployment
- Docker Swarm → Rejected: Not needed for 2-container setup

**Configuration Pattern**:
```yaml
version: '3.8'
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    volumes:
      - ./litellm_config.yaml:/app/config.yaml
    env_file: .env

  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OPENAI_API_BASE=http://litellm:4000/v1
    depends_on:
      - litellm
```

---

### 5. Usage Tracking and Cost Monitoring

**Decision**: Use LiteLLM's built-in analytics dashboard and logging

**Rationale**:
- Automatic per-request logging (tokens, cost, model, timestamp)
- Dashboard at `http://localhost:4000/ui` (FR-014)
- No additional monitoring infrastructure needed
- Satisfies NFR-005 (automatic logging)

**Tracked Metrics**:
- Input tokens (prompt)
- Output tokens (completion)
- Total tokens
- Estimated cost per model
- Request count
- Error rates
- Model usage distribution

**Alternatives Considered**:
- Custom logging solution → Rejected: LiteLLM provides this built-in
- Azure Monitor integration → Rejected: Adds complexity, local deployment doesn't need cloud monitoring
- Prometheus/Grafana → Rejected: Overkill for single-user system

---

### 6. Security and Credential Management

**Decision**: Store Azure credentials in .env file (gitignored)

**Rationale**:
- Simple for local development
- .env file excluded from version control
- .env.example provides template without secrets
- Docker Compose loads .env automatically

**Security Measures**:
- Add .env to .gitignore
- Provide .env.example with placeholder values
- Document credential rotation in SETUP.md
- Localhost-only access (no external exposure)

**Alternatives Considered**:
- Azure Key Vault → Rejected: Overkill for local development
- Managed Identity → Rejected: Only works when deployed to Azure (not local Docker)
- Hardcoded in YAML → Rejected: Security risk

**.env Format**:
```
AZURE_API_KEY=your-api-key-here
AZURE_API_BASE=https://your-resource.openai.azure.com
```

---

### 7. Testing Strategy

**Decision**: Manual integration testing via quickstart scenarios

**Rationale**:
- No application code to unit test (configuration only)
- Integration tests validate end-to-end flow
- Quickstart scenarios serve as acceptance tests
- Constitutional TDD principle modified for config-as-code (documented in Complexity Tracking)

**Test Scenarios** (to be defined in quickstart.md):
1. Container startup and health checks
2. Open WebUI admin account creation
3. Model selection and chat interaction
4. Image generation via DALL-E
5. Conversation history persistence (restart test)
6. Usage dashboard validation
7. Error handling (invalid credentials, quota exceeded)

**Alternatives Considered**:
- Automated integration tests → Rejected: Requires test framework, adds complexity for minimal benefit
- Contract tests for config files → Future enhancement: JSON Schema validation
- Load testing → Rejected: Single-user system (NFR-004)

---

## Technology Decisions Summary

| Component | Technology | Version/Image | Justification |
|-----------|-----------|---------------|---------------|
| Frontend | Open WebUI | ghcr.io/open-webui/open-webui:main | Feature-complete chat UI, no custom dev needed |
| Gateway | LiteLLM | ghcr.io/berriai/litellm:main-latest | Azure↔OpenAI API translation, usage tracking |
| Orchestration | Docker Compose | v3.8 | Simple 2-container setup, volume persistence |
| Storage | SQLite (in Open WebUI) | Default | Built-in, no separate DB container needed |
| Secrets | .env file | - | Simple local credential management |
| AI Service | Azure OpenAI | API 2024-02-01 | GPT-4, GPT-3.5, DALL-E 3 deployments |

---

## Dependencies

**External Services**:
- Azure OpenAI Service (requires active subscription + API key)

**Local Requirements**:
- Docker Engine 20.10+
- Docker Compose 2.0+
- Internet connection for Azure API calls
- ~2GB disk space for Docker images

**Configuration Files**:
- docker-compose.yml (created in Phase 1)
- litellm_config.yaml (created in Phase 1)
- .env (user creates from .env.example)
- .env.example (created in Phase 1)

---

## Known Limitations

1. **Local-only**: No external access (localhost:3000 only)
2. **Single-user**: Open WebUI supports multi-user, but spec limits to 1 admin
3. **No Managed Identity**: API keys required (Managed Identity only works in Azure)
4. **Best-effort latency**: Depends on Azure OpenAI Service response time
5. **Manual testing**: No automated test suite (configuration-as-code project)

---

## Next Steps

✅ All unknowns resolved - proceed to Phase 1 (Design & Contracts)

**Phase 1 Outputs**:
- data-model.md (entity relationships)
- contracts/ (OpenAPI specs, config schemas)
- quickstart.md (deployment and validation scenarios)
- CLAUDE.md update (incremental context addition)
