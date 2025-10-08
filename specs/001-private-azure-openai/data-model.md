# Data Model: Private AI Chatbot and Image Generator

**Date**: 2025-10-08
**Feature**: 001-private-azure-openai
**Purpose**: Define entities, relationships, and data structures for Open WebUI + LiteLLM deployment

---

## Entity Relationship Overview

```
┌─────────────────┐
│   User Account  │
│  (Open WebUI)   │
└────────┬────────┘
         │ 1:N
         │
         ▼
┌─────────────────┐       ┌──────────────────┐
│  Conversation   │ N:1   │ Model Config     │
│  (Open WebUI)   │──────▶│ (LiteLLM YAML)   │
└────────┬────────┘       └──────────────────┘
         │ 1:N
         │
         ▼
┌─────────────────┐       ┌──────────────────┐
│    Message      │       │   Usage Record   │
│  (Open WebUI)   │       │   (LiteLLM Log)  │
└─────────────────┘       └──────────────────┘
                                   │
                                   │ N:1
                                   ▼
                          ┌──────────────────┐
                          │  Azure OpenAI    │
                          │   Deployment     │
                          └──────────────────┘
```

---

## Entities

### 1. User Account
**Owner**: Open WebUI (SQLite database in Docker volume)
**Lifecycle**: Created on first access, persists indefinitely

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| id | UUID | Required, Unique | User identifier |
| username | String | Required, 3-50 chars, Unique | Login username |
| password_hash | String | Required, bcrypt | Hashed password (never plaintext) |
| email | String | Optional, Email format | User email (optional) |
| role | Enum | Required, `admin\|user` | Admin for first user, user for subsequent |
| created_at | Timestamp | Auto-generated | Account creation time |
| last_login | Timestamp | Auto-updated | Last login timestamp |

**State Transitions**:
- New → Active (on first login)
- Active → Locked (manual admin action, out of scope for single-user)

**Relationships**:
- 1 User : N Conversations

**Storage**: Open WebUI SQLite database (`/app/backend/data/webui.db` in container)

---

### 2. Conversation
**Owner**: Open WebUI (SQLite database)
**Lifecycle**: Created on new chat, persists until manually deleted by user

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| id | UUID | Required, Unique | Conversation identifier |
| user_id | UUID | Required, FK to User | Owner of conversation |
| title | String | Auto-generated or user-set | Chat title (derived from first message) |
| model | String | Required | Model used (e.g., "gpt-4", "gpt-35-turbo") |
| created_at | Timestamp | Auto-generated | Conversation start time |
| updated_at | Timestamp | Auto-updated | Last message timestamp |
| archived | Boolean | Default: false | Soft delete flag |

**State Transitions**:
- New → Active (on first message)
- Active → Archived (user deletes conversation)

**Relationships**:
- N Conversations : 1 User
- 1 Conversation : N Messages
- N Conversations : 1 Model Configuration (logical, not enforced FK)

**Storage**: Open WebUI SQLite database

**Business Rules**:
- Title auto-generated from first user message (first 50 chars)
- Model can be changed mid-conversation (new messages use new model)
- Archived conversations hidden from UI but preserved in database

---

### 3. Message
**Owner**: Open WebUI (SQLite database)
**Lifecycle**: Created on send (user) or receive (assistant), immutable after creation

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| id | UUID | Required, Unique | Message identifier |
| conversation_id | UUID | Required, FK to Conversation | Parent conversation |
| role | Enum | Required, `user\|assistant\|system` | Message sender |
| content | Text | Required, Max 32K chars | Message text (prompt or response) |
| timestamp | Timestamp | Auto-generated | Message creation time |
| token_count | Integer | Optional, Calculated | Approximate token count (from LiteLLM) |
| model | String | Required | Model that generated response (for assistant role) |
| finish_reason | Enum | Optional, `stop\|length\|content_filter` | Why generation stopped |
| metadata | JSON | Optional | Additional data (e.g., image URLs for DALL-E) |

**State Transitions**:
- None (immutable after creation)

**Relationships**:
- N Messages : 1 Conversation

**Storage**: Open WebUI SQLite database

**Business Rules**:
- User messages created immediately on send
- Assistant messages created incrementally during streaming (final version persisted)
- System messages rare (used for context injection, out of scope)
- DALL-E responses store image URL in metadata field

---

### 4. Model Configuration
**Owner**: LiteLLM (YAML configuration file)
**Lifecycle**: Defined at deployment time, modified by editing litellm_config.yaml and restarting container

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| model_name | String | Required, Unique | Display name in Open WebUI (e.g., "gpt-4") |
| litellm_params.model | String | Required | Azure model path (e.g., "azure/gpt-4-turbo") |
| litellm_params.api_base | String | Required, URL | Azure OpenAI endpoint |
| litellm_params.api_key | String | Required | Azure API key (from env var) |
| litellm_params.api_version | String | Required | Azure API version (e.g., "2024-02-01") |
| litellm_params.timeout | Integer | Optional, Default: 600 | Request timeout in seconds |

**Example**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: azure/gpt-4-turbo
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
```

**State Transitions**:
- None (configuration file, not runtime data)

**Relationships**:
- N Conversations use 1 Model Configuration (logical, not enforced)
- 1 Model Configuration : 1 Azure OpenAI Deployment

**Storage**: litellm_config.yaml file

**Business Rules**:
- Environment variables (${VAR}) injected from .env file
- Changes require LiteLLM container restart
- Model names must match Azure deployment names
- Invalid config prevents LiteLLM startup (fail-fast)

---

### 5. Usage Record
**Owner**: LiteLLM (automatic logging)
**Lifecycle**: Created on each API request to Azure OpenAI, retained indefinitely (or until container restart if not using persistent logging)

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| request_id | UUID | Auto-generated | Unique request identifier |
| timestamp | Timestamp | Auto-generated | Request timestamp |
| model | String | Required | Model used (e.g., "gpt-4") |
| input_tokens | Integer | Required | Prompt tokens |
| output_tokens | Integer | Required | Completion tokens |
| total_tokens | Integer | Calculated | input + output |
| cost_usd | Decimal | Calculated | Estimated cost based on Azure pricing |
| status | Enum | Required, `success\|error` | Request outcome |
| error_message | String | Optional | Error details if failed |
| latency_ms | Integer | Auto-calculated | Time to first token |

**State Transitions**:
- None (immutable logs)

**Relationships**:
- N Usage Records : 1 Model Configuration
- N Usage Records : 1 Azure OpenAI Deployment (logical)

**Storage**: LiteLLM container logs (stdout), optionally Redis if configured

**Business Rules**:
- Automatic creation on every Azure OpenAI API call
- Costs calculated using Azure OpenAI pricing (model-specific)
- Error records include 429 (quota), 400 (invalid), 500 (Azure issues)
- Logs accessible via `docker-compose logs litellm`
- Dashboard aggregates by model, time period, status

---

### 6. Azure OpenAI Deployment
**Owner**: Azure OpenAI Service (external)
**Lifecycle**: Provisioned manually in Azure Portal, referenced in LiteLLM config

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| deployment_name | String | Required, Unique in resource | Deployment identifier (e.g., "gpt-4-turbo-2024-04-09") |
| model_name | String | Required | Base model (e.g., "gpt-4", "dall-e-3") |
| model_version | String | Required | Model version (e.g., "0613", "turbo-2024-04-09") |
| endpoint_url | URL | Required | Full resource URL (e.g., "https://your-resource.openai.azure.com") |
| api_key | String | Required | Access key (managed in Azure Portal) |
| quota_tpm | Integer | Required | Tokens per minute quota |
| quota_rpm | Integer | Required | Requests per minute quota |

**State Transitions**:
- Provisioned → Active (manual Azure Portal action)
- Active → Disabled (manual Azure Portal action)

**Relationships**:
- 1 Deployment : N Model Configurations (can reuse same deployment)
- 1 Deployment : N Usage Records

**Storage**: Azure cloud (external system)

**Business Rules**:
- Must be pre-provisioned (not created by this system)
- API key required (Managed Identity not supported for local Docker)
- Quota limits enforced by Azure (429 errors on exceed)
- Endpoint URL format: `https://{resource-name}.openai.azure.com`

---

### 7. Docker Container
**Owner**: Docker Engine (orchestrated by Docker Compose)
**Lifecycle**: Created on `docker-compose up`, destroyed on `docker-compose down` (volumes persist)

| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| container_name | String | Required, Unique | Container identifier (e.g., "openwebui", "litellm") |
| image | String | Required | Docker image (e.g., "ghcr.io/open-webui/open-webui:main") |
| status | Enum | Required, `running\|stopped\|exited` | Current state |
| port_mappings | Array | Required | Host:Container port bindings |
| volumes | Array | Required | Volume mounts |
| environment | Map | Optional | Environment variables |
| created_at | Timestamp | Auto-generated | Container creation time |

**State Transitions**:
- Created → Running (`docker-compose up`)
- Running → Stopped (`docker-compose stop`)
- Stopped → Running (`docker-compose start`)
- Running → Exited (crash or `docker-compose down`)

**Relationships**:
- 1 Docker Compose : N Containers
- 1 Container : 1 Docker Volume (for Open WebUI)

**Storage**: Docker Engine metadata

**Business Rules**:
- Containers ephemeral (state lost on `down`)
- Volumes persist data across container lifecycle
- Health checks monitor container availability
- Restart policy: `unless-stopped` (auto-restart on crash)

---

### 8. Configuration Files
**Owner**: Git repository (user-managed)
**Lifecycle**: Created during initial setup, versioned in git (except .env)

#### docker-compose.yml
| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| version | String | Required, "3.8" | Compose file version |
| services | Map | Required | Container definitions |
| volumes | Map | Required | Named volume declarations |
| networks | Map | Optional | Network definitions (default bridge sufficient) |

#### litellm_config.yaml
| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| model_list | Array | Required | List of model configurations |

#### .env
| Field | Type | Validation | Description |
|-------|------|------------|-------------|
| AZURE_API_KEY | String | Required | Azure OpenAI API key |
| AZURE_API_BASE | URL | Required | Azure OpenAI endpoint URL |

**Storage**: File system (repository root)

**Business Rules**:
- .env excluded from git (.gitignore)
- .env.example committed as template
- docker-compose.yml and litellm_config.yaml versioned
- Changes require container restart

---

## Data Flow

### Chat Request Flow
```
1. User enters message in Open WebUI (localhost:3000)
2. Open WebUI creates Message (role=user) in SQLite
3. Open WebUI sends POST /v1/chat/completions to LiteLLM (http://litellm:4000)
4. LiteLLM logs Usage Record (input tokens, start time)
5. LiteLLM translates request to Azure OpenAI format
6. LiteLLM sends POST to Azure OpenAI Service (https://your-resource.openai.azure.com/openai/deployments/{model}/chat/completions)
7. Azure OpenAI Service streams response tokens
8. LiteLLM forwards stream to Open WebUI
9. Open WebUI displays tokens in real-time
10. On completion, Open WebUI creates Message (role=assistant) in SQLite
11. LiteLLM logs Usage Record (output tokens, total cost, latency)
```

### Image Generation Flow
```
1. User selects DALL-E model and enters prompt in Open WebUI
2. Open WebUI sends POST /v1/images/generations to LiteLLM
3. LiteLLM logs Usage Record (start time)
4. LiteLLM sends POST to Azure OpenAI Service (DALL-E deployment)
5. Azure OpenAI generates image (60-120 seconds)
6. Azure returns image URL
7. LiteLLM logs Usage Record (cost, latency)
8. LiteLLM forwards image URL to Open WebUI
9. Open WebUI creates Message with image URL in metadata
10. Open WebUI displays image in chat interface
```

### Container Restart Data Persistence
```
1. User runs: docker-compose down
2. Containers stopped and removed
3. Named volume "open-webui" persists (contains SQLite database)
4. litellm_config.yaml persists (file system)
5. User runs: docker-compose up
6. Containers recreated from images
7. Open WebUI mounts persisted volume
8. LiteLLM loads litellm_config.yaml
9. User logs in → sees all conversation history
```

---

## Validation Rules

### User Account
- Username: 3-50 characters, alphanumeric + underscore
- Password: Minimum 8 characters (Open WebUI default)
- Email: Valid email format (if provided)

### Conversation
- Title: Maximum 200 characters
- Model: Must exist in litellm_config.yaml

### Message
- Content: Maximum 32,000 characters (Azure OpenAI model limit)
- Role: Must be "user", "assistant", or "system"

### Model Configuration
- model_name: No spaces, alphanumeric + hyphen
- api_base: Valid HTTPS URL
- api_version: Format "YYYY-MM-DD"

### Azure OpenAI Deployment
- deployment_name: Must match LiteLLM config
- API key: 32-character hex string

---

## Indexing Strategy

**Open WebUI SQLite**:
- Primary keys on all entity IDs (auto-indexed)
- Index on `conversation.user_id` (conversation list queries)
- Index on `message.conversation_id` (message retrieval)
- Index on `conversation.updated_at` (recent conversations sort)

**LiteLLM Logs**:
- No persistent database (ephemeral logs)
- If using Redis (optional): Index on timestamp, model, status

---

## Data Retention

| Entity | Retention | Cleanup Mechanism |
|--------|-----------|-------------------|
| User Account | Indefinite | Manual deletion (out of scope) |
| Conversation | Indefinite | User deletes via UI (soft delete) |
| Message | Indefinite | Deleted when parent conversation deleted |
| Model Configuration | Indefinite | Manual YAML edit |
| Usage Record | Container lifetime | Lost on `docker-compose down` (unless Redis configured) |
| Azure Deployment | Azure-managed | N/A |
| Docker Container | Until `down` | `docker-compose down` |
| Configuration Files | Indefinite | Git version control |

**Note**: Original spec mentioned 30-day retention (FR-007 in old spec), but Open WebUI doesn't have automatic expiration. Users must manually delete old conversations.

---

## Security Considerations

1. **Passwords**: Bcrypt hashed (Open WebUI default), never plaintext
2. **API Keys**: Stored in .env (gitignored), injected via environment variables
3. **Database**: SQLite file in Docker volume (no network exposure)
4. **Localhost Only**: No external network access (NFR-003)
5. **No Managed Identity**: API keys required (limitation of local Docker deployment)

---

## Next Steps

✅ Data model complete → Proceed to contract generation (Phase 1 continued)
