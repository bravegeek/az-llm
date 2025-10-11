# Setup Guide: Private AI Chatbot and Image Generator

Complete step-by-step instructions for deploying Open WebUI + LiteLLM with Azure OpenAI Service.

## Prerequisites Checklist

Before starting, ensure you have:

### Local Machine Requirements
- [ ] Docker Engine 20.10+ installed
  ```bash
  docker --version
  ```
- [ ] Docker Compose 2.0+ installed (or Docker CLI with compose plugin)
  ```bash
  docker compose version
  ```
- [ ] ~2GB free disk space for Docker images
- [ ] Internet connection for Azure API access

### Azure Requirements
- [ ] Active Azure subscription
- [ ] Azure OpenAI Service access (requires application approval)
- [ ] Azure OpenAI resource provisioned
- [ ] Models deployed in your Azure OpenAI resource:
  - GPT-4 Turbo (or GPT-4)
  - GPT-3.5 Turbo
  - DALL-E 3
- [ ] API key and endpoint URL from Azure Portal

---

## Part 1: Azure OpenAI Setup

### Step 1: Create Azure OpenAI Resource

If you don't have an Azure OpenAI resource yet:

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Click **Create a resource**
3. Search for **Azure OpenAI**
4. Click **Create**
5. Fill in:
   - **Subscription**: Your Azure subscription
   - **Resource group**: Create new or use existing
   - **Region**: Choose a region (e.g., East US, West Europe)
   - **Name**: Choose a unique name (e.g., `my-openai-resource`)
   - **Pricing tier**: Standard S0
6. Click **Review + Create**, then **Create**
7. Wait 2-5 minutes for deployment

### Step 2: Deploy Models

After resource creation:

1. Navigate to your Azure OpenAI resource
2. Click **Model deployments** (or **Go to Azure OpenAI Studio**)
3. In Azure OpenAI Studio, click **Deployments** → **Create new deployment**

Deploy each model:

#### GPT-4 Deployment
- **Model**: GPT-4 Turbo (or GPT-4)
- **Deployment name**: `gpt-4-turbo` (remember this!)
- **Model version**: Latest available
- **Deployment type**: Standard
- **Tokens per minute rate limit**: 10K (adjust based on quota)

#### GPT-3.5 Turbo Deployment
- **Model**: GPT-3.5 Turbo
- **Deployment name**: `gpt-35-turbo`
- **Model version**: Latest available
- **Tokens per minute rate limit**: 60K

#### DALL-E 3 Deployment
- **Model**: DALL-E 3
- **Deployment name**: `dall-e-3`
- **Capacity**: 1 (images per minute)

**Important**: Remember your deployment names - you'll need them for litellm_config.yaml!

### Step 3: Get API Key and Endpoint

1. In Azure Portal, navigate to your Azure OpenAI resource
2. Click **Keys and Endpoint** (left sidebar)
3. Copy:
   - **KEY 1** (or KEY 2) - this is your AZURE_API_KEY
   - **Endpoint** - this is your AZURE_API_BASE (format: `https://your-resource.openai.azure.com`)

Keep these values handy for the next section.

---

## Part 2: Local Deployment Setup

### Step 1: Clone Repository

```bash
cd ~/dev  # or your preferred directory
git clone <repository-url>
cd az-llm
```

### Step 2: Configure Environment Variables

Create `.env` file from template:

```bash
cp .env.example .env
```

Edit `.env` and add your Azure credentials:

```bash
nano .env  # or use your preferred editor
```

Replace placeholder values:

```env
# Azure OpenAI API Key (from Azure Portal → Keys and Endpoint)
AZURE_API_KEY=1234567890abcdef1234567890abcdef

# Azure OpenAI Endpoint URL (from Azure Portal → Keys and Endpoint)
AZURE_API_BASE=https://your-resource.openai.azure.com
```

**Security Note**: Never commit `.env` to version control! It's already in `.gitignore`.

### Step 3: Configure Models

Edit `litellm_config.yaml` to match your Azure deployment names:

```bash
nano litellm_config.yaml
```

Update the `model` fields with your actual deployment names from Azure:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: azure/gpt-4-turbo  # ← Replace with your deployment name
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
      timeout: 600

  - model_name: gpt-35-turbo
    litellm_params:
      model: azure/gpt-35-turbo  # ← Replace with your deployment name
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
      timeout: 600

  - model_name: dall-e-3
    litellm_params:
      model: azure/dall-e-3  # ← Replace with your deployment name
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
      timeout: 600
```

**Example**: If your GPT-4 deployment is named `my-gpt4-deployment`, change:
```yaml
model: azure/my-gpt4-deployment
```

### Step 4: Validate Configuration

Check that docker-compose.yml is valid:

```bash
docker compose config
```

Expected output: Configuration details (warnings about missing .env variables are okay if you haven't created .env yet)

### Step 5: Start Containers

Pull images and start containers:

```bash
docker compose up -d
```

First run will download ~2GB of Docker images (5-10 minutes depending on connection).

Expected output:
```
[+] Running 3/3
 ✔ Network az-llm_default    Created
 ✔ Container litellm         Started
 ✔ Container openwebui       Started
```

### Step 6: Verify Containers Are Running

```bash
docker compose ps
```

Expected output:
```
NAME        IMAGE                                    STATUS
litellm     ghcr.io/berriai/litellm:main-latest      Up X seconds
openwebui   ghcr.io/open-webui/open-webui:main       Up X seconds
```

Check logs for errors:

```bash
# LiteLLM logs
docker compose logs litellm

# Open WebUI logs
docker compose logs openwebui
```

**Success indicators**:
- LiteLLM: `Uvicorn running on http://0.0.0.0:4000`
- Open WebUI: `Application startup complete`

---

## Part 3: First-Time Access

### Step 1: Create Admin Account

1. Open browser to `http://localhost:3000`
2. You should see "Create Account" form (first-time only)
3. Fill in:
   - **Username**: Your choice (e.g., `admin`)
   - **Email**: Optional
   - **Password**: At least 8 characters
4. Click **Create Account**
5. You'll be automatically logged in

**Note**: The first account is automatically the admin account.

### Step 2: Test Chat

1. Select a model from dropdown (e.g., "gpt-4")
2. Type a test message: "What is the capital of France?"
3. Press Enter
4. Verify you see a streaming response within 2-3 seconds

**Troubleshooting**: If you see an error, check:
- `.env` has correct AZURE_API_KEY and AZURE_API_BASE
- `litellm_config.yaml` deployment names match Azure
- `docker compose logs litellm` for authentication errors

### Step 3: Test Image Generation

1. Switch to "dall-e-3" model in dropdown
2. Type prompt: "A serene mountain lake at sunrise"
3. Press Enter
4. Wait 60-120 seconds for generation
5. Verify image appears in chat

### Step 4: Check Usage Dashboard

1. Navigate to `http://localhost:4000/ui`
2. Review usage statistics:
   - Request count
   - Token usage
   - Cost estimates

---

## Part 4: Optional Configuration

### Change Ports

If port 3000 or 4000 is already in use:

Edit `docker-compose.yml`:

```yaml
services:
  litellm:
    ports:
      - "4001:4000"  # Change host port (left side)

  openwebui:
    ports:
      - "3001:8080"  # Change host port (left side)
```

Then restart:

```bash
docker compose down
docker compose up -d
```

Access at `http://localhost:3001` instead.

### Add More Models

Edit `litellm_config.yaml` and add another model:

```yaml
model_list:
  # ... existing models ...

  - model_name: gpt-4o
    litellm_params:
      model: azure/your-gpt4o-deployment
      api_base: ${AZURE_API_BASE}
      api_key: ${AZURE_API_KEY}
      api_version: "2024-02-01"
      timeout: 600
```

Restart LiteLLM:

```bash
docker compose restart litellm
```

### Enable HTTPS (Production)

For production use, add a reverse proxy:

**Option 1: Nginx**
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Option 2: Caddy** (automatic HTTPS)
```
your-domain.com {
    reverse_proxy localhost:3000
}
```

---

## Part 5: Data Backup

### Backup Conversations

Open WebUI stores all conversations in a Docker volume. To backup:

```bash
# Create backup directory
mkdir -p backups

# Backup volume
docker run --rm \
  -v az-llm_open-webui:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/openwebui-$(date +%Y%m%d).tar.gz /data
```

### Restore from Backup

```bash
# Stop containers
docker compose down

# Restore volume
docker run --rm \
  -v az-llm_open-webui:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/openwebui-20241008.tar.gz -C /

# Restart containers
docker compose up -d
```

---

## Part 6: Maintenance

### Update Images

Pull latest versions:

```bash
# Stop containers
docker compose down

# Pull latest images
docker compose pull

# Restart
docker compose up -d
```

### View Logs

```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f litellm
docker compose logs -f openwebui
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart litellm
```

### Clean Up

```bash
# Stop and remove containers (keeps data)
docker compose down

# Remove containers AND data (DESTRUCTIVE!)
docker compose down -v

# Remove unused images
docker image prune -a
```

---

## Verification Checklist

After setup, verify:

- [ ] Containers running: `docker compose ps` shows both "Up"
- [ ] Open WebUI accessible: `http://localhost:3000`
- [ ] Admin account created and can log in
- [ ] Chat works with GPT-4 (streaming response)
- [ ] Chat works with GPT-3.5 Turbo
- [ ] Image generation works with DALL-E 3 (60-120 sec)
- [ ] Model switching preserves conversation
- [ ] Usage dashboard shows data: `http://localhost:4000/ui`
- [ ] Conversations persist after restart: `docker compose down && docker compose up -d`

---

## Next Steps

- **Read [USAGE.md](USAGE.md)** - Learn advanced features
- **Read [TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues
- **Monitor costs** - Check LiteLLM dashboard and Azure Cost Management
- **Schedule backups** - Set up cron job for volume backups

---

## Support Resources

- **Open WebUI Documentation**: https://docs.openwebui.com
- **LiteLLM Documentation**: https://docs.litellm.ai
- **Azure OpenAI Documentation**: https://learn.microsoft.com/azure/ai-services/openai/
- **Azure OpenAI Pricing**: https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/

---

**Setup Complete!** 🎉

You now have a fully functional private AI chatbot with image generation capabilities.
