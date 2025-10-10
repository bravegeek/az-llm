# Quickstart Guide: Private AI Chatbot and Image Generator

**Feature**: 001-private-azure-openai
**Purpose**: Step-by-step deployment and validation scenarios
**Audience**: End users deploying the system locally

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Docker Engine 20.10+ installed (`docker --version`)
- [ ] Docker Compose 2.0+ installed (`docker-compose --version`)
- [ ] Active Azure subscription
- [ ] Azure OpenAI Service instance provisioned
- [ ] Azure OpenAI models deployed:
  - [ ] GPT-4 Turbo (or GPT-4)
  - [ ] GPT-3.5 Turbo
  - [ ] DALL-E 3
- [ ] Azure OpenAI API key and endpoint URL
- [ ] Internet connection for Azure API access
- [ ] ~2GB free disk space for Docker images

---

## Quick Start (5 Minutes)

### Step 1: Clone Repository and Configure

```bash
# Clone the repository
cd /home/greg/dev/az-llm

# Create .env file from template
cp .env.example .env

# Edit .env with your Azure credentials
nano .env
```

**Required .env values:**
```
AZURE_API_KEY=your-azure-openai-api-key-here
AZURE_API_BASE=https://your-resource.openai.azure.com
```

### Step 2: Configure Models

Edit `docker/litellm/config.yaml` to match your Azure OpenAI deployments:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: azure/your-gpt4-deployment-name  # ← Update this
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
```

**Important**: Replace `your-gpt4-deployment-name` with your actual Azure deployment names.

### Step 3: Start Containers

```bash
# Using helper script (recommended)
./docker/scripts/start.sh

# Or using docker compose directly
docker compose up -d

# Verify containers are running
docker compose ps
```

**Expected output:**
```
NAME               IMAGE                                    STATUS
az-llm-litellm     ghcr.io/berriai/litellm:main-latest      Up 10 seconds (healthy)
az-llm-openwebui   ghcr.io/open-webui/open-webui:main       Up 10 seconds
```

### Step 4: Access Open WebUI

1. Open browser to `http://localhost:3000`
2. Create admin account (first-time only):
   - Username: (your choice)
   - Password: (min 8 characters)
3. Log in with your credentials

### Step 5: Test Chat

1. Select model from dropdown (e.g., "gpt-4")
2. Type a message: "What is the capital of France?"
3. Verify streaming response appears
4. Confirm usage logged in LiteLLM dashboard: `http://localhost:4000/ui`

✅ **System is now running!**

---

## Detailed Validation Scenarios

### Scenario 1: Container Health Check

**Purpose**: Verify both containers started successfully

```bash
# Check container status
docker compose ps

# Check container logs
docker compose logs litellm
docker compose logs openwebui

# Or use helper script
./docker/scripts/logs.sh litellm
./docker/scripts/logs.sh openwebui

# Check health status
./docker/scripts/health.sh

# Verify LiteLLM loaded config
docker compose logs litellm | grep "model_list"
```

**Success Criteria**:
- Both containers show "Up" status
- LiteLLM logs show "Uvicorn running on http://0.0.0.0:4000"
- Open WebUI logs show "Application startup complete"
- No error messages in logs

**Troubleshooting**:
- If LiteLLM fails: Check `.env` file has correct `AZURE_API_KEY` and `AZURE_API_BASE`
- If config not found: Verify `docker/litellm/config.yaml` exists
- If Open WebUI fails: Check port 3000 is not in use (`lsof -i :3000`)
- For detailed diagnostics: `./docker/scripts/health.sh`

---

### Scenario 2: Admin Account Creation

**Purpose**: Verify Open WebUI authentication works

**Steps**:
1. Navigate to `http://localhost:3000`
2. See "Create Account" form (first-time only)
3. Enter username: `admin`
4. Enter email: `admin@example.com` (optional)
5. Enter password: `SecurePass123`
6. Click "Create Account"
7. Verify redirect to chat interface

**Success Criteria**:
- Account created without errors
- Automatically logged in
- Chat interface visible with model dropdown

**Troubleshooting**:
- If stuck on loading: Check `docker-compose logs openwebui` for errors
- If can't connect: Verify container is running (`docker-compose ps`)

---

### Scenario 3: Chat with GPT-4

**Purpose**: Validate end-to-end chat flow with streaming

**Steps**:
1. Log into Open WebUI (`http://localhost:3000`)
2. Click model dropdown, select "gpt-4"
3. Type message: "Explain quantum computing in one sentence"
4. Press Enter
5. Observe response streaming word-by-word
6. Wait for complete response
7. Verify message appears in conversation history

**Success Criteria**:
- Model dropdown shows "gpt-4" (and other configured models)
- Response begins streaming within 2-3 seconds
- Tokens appear incrementally (not all at once)
- Complete response displays when finished
- Message persists in conversation after page refresh

**Troubleshooting**:
- If no response: Check LiteLLM logs (`docker-compose logs litellm`)
- If error "Invalid model": Verify deployment name in `litellm_config.yaml` matches Azure
- If 429 error: Azure quota exceeded, check Azure Portal quota settings

---

### Scenario 4: Image Generation with DALL-E 3

**Purpose**: Validate image generation flow

**Steps**:
1. Log into Open WebUI
2. Select "dall-e-3" from model dropdown
3. Type prompt: "A serene mountain lake at sunrise"
4. Press Enter
5. Wait 60-120 seconds for generation
6. Verify image appears in chat
7. Right-click image → Save As → Confirm download works

**Success Criteria**:
- DALL-E 3 appears in model dropdown
- Status shows "Generating..." during wait
- Image displays in chat interface
- Image is downloadable
- Conversation history shows image prompt and result

**Troubleshooting**:
- If timeout: DALL-E can take 120 seconds, increase `timeout` in litellm_config.yaml
- If content policy error: Prompt violated safety guidelines, try different prompt
- If 404 error: Verify DALL-E 3 is deployed in your Azure OpenAI resource

---

### Scenario 5: Model Switching

**Purpose**: Verify switching models mid-conversation preserves context

**Steps**:
1. Start new conversation
2. Select "gpt-35-turbo"
3. Send message: "Remember the number 42"
4. Receive confirmation response
5. Switch to "gpt-4" via dropdown
6. Send message: "What number did I ask you to remember?"
7. Verify response mentions "42"

**Success Criteria**:
- Model switches without clearing conversation
- Subsequent messages use new model
- Conversation context preserved (model can reference previous messages)

**Expected Behavior**:
- Open WebUI sends full conversation history with each request
- LiteLLM routes to different Azure deployment based on selected model
- Azure OpenAI uses conversation history for context

**Troubleshooting**:
- If model doesn't switch: Refresh page and try again
- If context lost: This is expected - each model call is independent unless conversation history is sent

---

### Scenario 6: Usage Tracking Validation

**Purpose**: Confirm LiteLLM logs usage metrics

**Steps**:
1. Send 3 chat messages (any model)
2. Generate 1 DALL-E image
3. Navigate to `http://localhost:4000/ui`
4. Log in to LiteLLM dashboard (if prompted)
5. Review usage statistics

**Success Criteria**:
- Dashboard shows 3 chat requests
- Dashboard shows 1 image request
- Token counts displayed (input/output)
- Cost estimates shown
- Per-model breakdown visible

**Troubleshooting**:
- If dashboard 404: LiteLLM may not have UI enabled, check logs
- If no data: Usage logging may require Redis (check LiteLLM docs)
- If costs wrong: Verify `base_model` set correctly in litellm_config.yaml

---

### Scenario 7: Conversation Persistence

**Purpose**: Verify data persists across container restarts

**Steps**:
1. Create conversation with 3 messages
2. Note conversation title
3. Stop containers: `docker-compose down`
4. Verify containers stopped: `docker-compose ps`
5. Start containers: `docker-compose up -d`
6. Wait for startup (30 seconds)
7. Navigate to `http://localhost:3000`
8. Log in
9. Verify conversation still exists

**Success Criteria**:
- Conversation appears in sidebar
- All 3 messages present
- Message content unchanged
- Conversation title preserved

**Troubleshooting**:
- If conversation lost: Check Docker volume exists (`docker volume ls | grep open-webui`)
- If volume missing: Data was not persisted, recreate with named volume in docker-compose.yml

---

### Scenario 8: Error Handling - Invalid Credentials

**Purpose**: Verify graceful error handling for Azure API errors

**Steps**:
1. Stop containers: `docker-compose down`
2. Edit `.env`, set invalid `AZURE_API_KEY=invalid-key-123`
3. Start containers: `docker-compose up -d`
4. Navigate to `http://localhost:3000`
5. Try sending a chat message

**Success Criteria**:
- Open WebUI displays error message (not blank page)
- Error mentions authentication failure
- Container doesn't crash
- User can retry after fixing credentials

**Expected Error**:
```
Error: Authentication failed. Please check your API key.
```

**Recovery**:
1. Stop containers: `docker-compose down`
2. Fix `.env` with correct `AZURE_API_KEY`
3. Start containers: `docker-compose up -d`

---

### Scenario 9: Error Handling - Quota Exceeded

**Purpose**: Verify handling of Azure rate limits

**Simulated Test** (manual quota reduction not recommended):
1. Send rapid-fire messages (10+ in quick succession)
2. Observe response behavior

**Success Criteria**:
- 429 error displayed in Open WebUI
- LiteLLM logs show rate limit error
- Usage dashboard tracks failed requests
- Subsequent requests succeed after quota resets

**Expected Error**:
```
Error: Rate limit exceeded. Please try again later.
```

---

### Scenario 10: Cleanup

**Purpose**: Properly stop and remove containers

**Steps**:
```bash
# Stop containers (keep data)
docker compose stop

# Stop and remove containers (keep data)
docker compose down
# Or use helper script
./docker/scripts/stop.sh

# Remove containers AND data (DESTRUCTIVE)
docker compose down -v
```

**Success Criteria**:
- `docker compose stop`: Containers stopped, data preserved
- `docker compose down`: Containers removed, data preserved
- `docker compose down -v`: Everything removed (clean slate)

---

## Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| Port conflict | `Error: port is already allocated` | Change host port in docker-compose.yml (e.g., `3001:8080`) |
| Invalid credentials | `Authentication failed` | Verify `.env` has correct `AZURE_API_KEY` |
| Model not found | `Model 'gpt-4' not found` | Check deployment name in `docker/litellm/config.yaml` matches Azure |
| Config not found | `FileNotFoundError` | Verify `docker/litellm/config.yaml` exists |
| No response | Request hangs | Check internet connection, verify Azure endpoint reachable |
| Quota exceeded | 429 error | Wait for Azure quota reset, increase quota in Azure Portal |
| Data loss on restart | Conversations gone | Ensure `open-webui` named volume in docker-compose.yml |

---

## Performance Expectations

| Operation | Expected Latency | Notes |
|-----------|------------------|-------|
| Container startup | 30-60 seconds | First run downloads images (~2GB) |
| Admin account creation | <1 second | Local SQLite write |
| Chat first token | 1-3 seconds | Depends on Azure OpenAI latency |
| Chat full response | 5-15 seconds | Depends on response length |
| Image generation | 60-120 seconds | DALL-E 3 is slow |
| Model switch | <1 second | UI update only |
| Conversation load | <1 second | Local database query |

---

## Next Steps

After completing quickstart:

1. **Customize Models**: Edit `docker/litellm/config.yaml` to add/remove models
2. **Review Docker Setup**: See [docker/docs/README.md](../../docker/docs/README.md) for detailed Docker documentation
3. **Enable HTTPS**: Add reverse proxy (Nginx, Caddy) for production
4. **Backup Data**: Schedule Docker volume backups (`open-webui` volume)
5. **Monitor Costs**: Check LiteLLM dashboard and Azure Cost Management regularly
6. **Explore Features**: Try Open WebUI's advanced features (RAG, tools, personas)
7. **Azure Deployment**: See [specs/002-azure-infrastructure-as](../002-azure-infrastructure-as/) for production deployment

---

## Testing Checklist

Use this checklist to validate a fresh deployment:

- [ ] Scenario 1: Container Health Check
- [ ] Scenario 2: Admin Account Creation
- [ ] Scenario 3: Chat with GPT-4
- [ ] Scenario 4: Image Generation with DALL-E 3
- [ ] Scenario 5: Model Switching
- [ ] Scenario 6: Usage Tracking Validation
- [ ] Scenario 7: Conversation Persistence
- [ ] Scenario 8: Error Handling - Invalid Credentials
- [ ] Scenario 9: Error Handling - Quota Exceeded
- [ ] Scenario 10: Cleanup

**All scenarios passing = Deployment successful!**
