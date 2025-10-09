# Troubleshooting Guide: Private AI Chatbot and Image Generator

Common issues and solutions for Open WebUI + LiteLLM deployment with Azure OpenAI.

---

## Quick Diagnostics

Run these commands first:

```bash
# Check container status
docker compose ps

# Check recent logs
docker compose logs --tail=50

# Check specific service
docker compose logs litellm
docker compose logs openwebui

# Verify configuration syntax
docker compose config
```

---

## Common Issues

### 1. Port Already in Use

**Symptom**:
```
Error: Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Cause**: Another application is using port 3000 or 4000

**Solution**:

Option A - Find and stop conflicting process:
```bash
# Find process using port 3000
lsof -i :3000
sudo kill <PID>
```

Option B - Change port in docker-compose.yml:
```yaml
services:
  openwebui:
    ports:
      - "3001:8080"  # Change 3000 to 3001
```

Then restart:
```bash
docker compose down
docker compose up -d
```

Access at `http://localhost:3001` instead.

---

### 2. Authentication Failed / Invalid API Key

**Symptom**:
```
Error: Authentication failed. Please check your API key.
```

**Cause**: Incorrect AZURE_API_KEY in .env file

**Solution**:

1. Verify API key in Azure Portal:
   - Go to your Azure OpenAI resource
   - Click **Keys and Endpoint**
   - Copy KEY 1 or KEY 2

2. Check `.env` file:
   ```bash
   cat .env
   ```

3. Ensure no extra spaces or quotes:
   ```env
   # ✅ Correct
   AZURE_API_KEY=1234567890abcdef1234567890abcdef

   # ❌ Wrong (quotes)
   AZURE_API_KEY="1234567890abcdef1234567890abcdef"

   # ❌ Wrong (spaces)
   AZURE_API_KEY = 1234567890abcdef1234567890abcdef
   ```

4. Restart containers:
   ```bash
   docker compose down
   docker compose up -d
   ```

---

### 3. Model Not Found

**Symptom**:
```
Error: Model 'gpt-4' not found
```

**Cause**: Deployment name in `litellm_config.yaml` doesn't match Azure

**Solution**:

1. Check your Azure deployment names:
   - Azure Portal → Your OpenAI resource → **Model deployments**
   - Note exact deployment names (case-sensitive)

2. Edit `litellm_config.yaml`:
   ```yaml
   model_list:
     - model_name: gpt-4
       litellm_params:
         model: azure/your-actual-deployment-name  # ← Must match Azure
   ```

3. Common mistakes:
   ```yaml
   # ❌ Wrong - missing "azure/" prefix
   model: gpt-4-turbo

   # ✅ Correct
   model: azure/gpt-4-turbo
   ```

4. Restart LiteLLM:
   ```bash
   docker compose restart litellm
   ```

---

### 4. No Response / Request Hangs

**Symptom**: Message sends but no response appears

**Possible Causes**:

#### A. Internet connection issue

**Test**:
```bash
# Test Azure endpoint reachability
curl -I https://your-resource.openai.azure.com
```

**Solution**: Check firewall, VPN, or network connectivity

#### B. Azure quota exceeded

**Check logs**:
```bash
docker compose logs litellm | grep -i "429\|quota"
```

**Solution**:
- Wait for quota to reset (usually 1 minute)
- Increase quota in Azure Portal
- Switch to a lower-usage model (GPT-3.5 Turbo)

#### C. Timeout (DALL-E)

**Symptom**: Image generation times out after 10 minutes

**Solution**: DALL-E takes 60-120 seconds - this is normal. Increase timeout:

```yaml
# litellm_config.yaml
- model_name: dall-e-3
  litellm_params:
    model: azure/dall-e-3
    timeout: 600  # 10 minutes (increase if needed)
```

---

### 5. Quota Exceeded (429 Error)

**Symptom**:
```
Error: Rate limit exceeded. Please try again later.
```

**Cause**: Azure OpenAI quota limits reached

**Check quota**:
1. Azure Portal → Your OpenAI resource → **Quotas**
2. Check tokens-per-minute (TPM) and requests-per-minute (RPM)

**Solutions**:

- **Wait**: Quotas reset every minute
- **Increase quota**: Azure Portal → Request quota increase
- **Use different model**: Switch to GPT-3.5 Turbo (higher default quota)
- **Reduce parallel requests**: Wait between messages

---

### 6. Conversations Lost After Restart

**Symptom**: After `docker compose down`, all conversations are gone

**Cause**: Docker volume was deleted with `-v` flag

**Prevention**:

```bash
# ✅ Correct - keeps data
docker compose down

# ❌ Wrong - deletes data
docker compose down -v
```

**Recovery**: Restore from backup (see [SETUP.md](SETUP.md) Part 5)

**Verification**:
```bash
# Check volume exists
docker volume ls | grep open-webui

# Expected output:
# az-llm_open-webui
```

---

### 7. Container Crashes on Startup

**Symptom**:
```
docker compose ps
NAME      STATUS
litellm   Exited (1)
```

**Diagnosis**:
```bash
docker compose logs litellm
```

**Common causes**:

#### A. Invalid litellm_config.yaml syntax

**Check**:
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('litellm_config.yaml'))"
```

**Fix**: Correct YAML indentation, missing colons, or quotes

#### B. Missing configuration file

**Error**:
```
FileNotFoundError: /app/config.yaml
```

**Fix**: Ensure `litellm_config.yaml` exists in repository root

#### C. Environment variable not set

**Error**:
```
KeyError: 'AZURE_API_KEY'
```

**Fix**: Ensure `.env` file exists and has correct variables

---

### 8. Cannot Access Open WebUI (Connection Refused)

**Symptom**: Browser shows "Connection refused" at `http://localhost:3000`

**Diagnosis**:

1. Check container is running:
   ```bash
   docker compose ps
   ```

2. If not running, check logs:
   ```bash
   docker compose logs openwebui
   ```

**Solutions**:

- **Container not started**: `docker compose up -d`
- **Wrong port**: Try `http://localhost:8080` (container internal port)
- **Port mapping issue**: Check docker-compose.yml has `3000:8080`
- **Firewall**: Disable firewall temporarily to test

---

### 9. LiteLLM Dashboard Not Loading

**Symptom**: `http://localhost:4000/ui` shows 404 or doesn't load

**Cause**: Some LiteLLM versions don't include UI by default

**Workaround**: Use logs instead of dashboard

```bash
# View usage logs
docker compose logs litellm | grep -i "tokens\|cost"
```

**Alternative**: Add Redis for persistent logging (advanced)

---

### 10. Image Generation Returns Error

**Symptom**:
```
Error: Content policy violation
```

**Cause**: DALL-E 3 rejected prompt due to safety guidelines

**Solution**: Modify prompt to be more neutral/safe

**Examples**:
- ❌ "violent battle scene"
- ✅ "peaceful medieval festival"

---

### 11. Slow Performance

**Symptom**: Responses take >30 seconds

**Possible causes**:

#### A. Network latency
**Test**: `ping your-resource.openai.azure.com`
**Solution**: Choose Azure region closer to you

#### B. Large context window
**Cause**: Long conversation history sent with each request
**Solution**: Start new conversation for unrelated topics

#### C. Azure region congestion
**Solution**: Switch to different Azure region (requires new resource)

---

### 12. Docker Compose Not Found

**Symptom**:
```
docker-compose: command not found
```

**Cause**: Using older Docker CLI without compose plugin

**Solution**:

Try new syntax:
```bash
docker compose up -d  # No hyphen
```

Or install docker-compose:
```bash
# Ubuntu/Debian
sudo apt install docker-compose

# macOS
brew install docker-compose
```

---

## Advanced Debugging

### Enable Verbose Logging

Edit `docker-compose.yml`:

```yaml
services:
  litellm:
    environment:
      - AZURE_API_KEY=${AZURE_API_KEY}
      - AZURE_API_BASE=${AZURE_API_BASE}
      - LOG_LEVEL=DEBUG  # ← Add this
```

Restart and check logs:
```bash
docker compose restart litellm
docker compose logs -f litellm
```

### Inspect Container

```bash
# Enter container shell
docker exec -it litellm sh

# Check environment variables
env | grep AZURE

# Check config file
cat /app/config.yaml
```

### Test Azure API Directly

```bash
# Test authentication
curl -X POST "https://your-resource.openai.azure.com/openai/deployments/gpt-4-turbo/chat/completions?api-version=2024-02-01" \
  -H "Content-Type: application/json" \
  -H "api-key: your-api-key-here" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

Expected response: JSON with `choices` array

---

## Getting Help

If issue persists:

1. **Collect information**:
   ```bash
   # System info
   docker --version
   docker compose version

   # Container status
   docker compose ps

   # Recent logs
   docker compose logs --tail=100 > logs.txt
   ```

2. **Check documentation**:
   - [Open WebUI docs](https://docs.openwebui.com)
   - [LiteLLM docs](https://docs.litellm.ai)
   - [Azure OpenAI docs](https://learn.microsoft.com/azure/ai-services/openai/)

3. **GitHub Issues**:
   - [Open WebUI Issues](https://github.com/open-webui/open-webui/issues)
   - [LiteLLM Issues](https://github.com/BerriAI/litellm/issues)

---

## Issue Summary Table

| Issue | Symptom | Quick Fix |
|-------|---------|-----------|
| Port conflict | `port is already allocated` | Change port in docker-compose.yml |
| Invalid credentials | `Authentication failed` | Verify AZURE_API_KEY in .env |
| Model not found | `Model 'gpt-4' not found` | Check deployment names in litellm_config.yaml |
| No response | Request hangs | Check Azure quota, internet connection |
| Rate limit | `429 error` | Wait 1 minute, increase quota in Azure |
| Data loss | Conversations gone | Don't use `docker compose down -v` |
| Container crash | `Exited (1)` | Check logs: `docker compose logs litellm` |
| Cannot connect | `Connection refused` | Verify container running: `docker compose ps` |
| Content policy | Image generation error | Modify prompt to be more neutral |
| Slow performance | >30 sec responses | Check network latency, start new conversation |

---

**Still stuck?** Review [SETUP.md](SETUP.md) to ensure all prerequisites are met.
