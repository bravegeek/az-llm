# Usage Guide: Private AI Chatbot and Image Generator

Complete guide to using Open WebUI features with Azure OpenAI models.

---

## Getting Started

### Accessing Open WebUI

1. Ensure containers are running:
   ```bash
   docker compose ps
   ```

2. Open browser to `http://localhost:3000`

3. Log in with your credentials (created during setup)

---

## Chat Interface Overview

### Main Components

```
┌─────────────────────────────────────────────────────────┐
│  [☰] Open WebUI                    [@admin] [Settings]  │ ← Top bar
├─────────────┬───────────────────────────────────────────┤
│             │  [Model: gpt-4 ▼]                         │ ← Model selector
│             ├───────────────────────────────────────────┤
│ + New Chat  │                                           │
│             │  User: What is quantum computing?         │
│ Recent:     │                                           │
│ □ Quantum   │  Assistant: Quantum computing is...      │ ← Chat area
│ □ Travel    │  [streaming response]                     │
│ □ Recipes   │                                           │
│             │                                           │
│             ├───────────────────────────────────────────┤
│             │  [Type a message...            ] [Send →] │ ← Input area
└─────────────┴───────────────────────────────────────────┘
  ↑ Sidebar
```

---

## Core Features

### 1. Model Selection

**Available Models** (configured in litellm_config.yaml):
- **gpt-4**: Most capable, best reasoning, higher cost (~$0.01-0.03 per 1K tokens)
- **gpt-35-turbo**: Fast, cost-effective, good for simple tasks (~$0.0005-0.0015 per 1K tokens)
- **dall-e-3**: Image generation (~$0.04 per image)

**How to Switch Models**:

1. Click model dropdown at top of chat
2. Select desired model
3. Next message will use selected model

**Tips**:
- Use GPT-3.5 Turbo for quick questions, simple tasks, brainstorming
- Use GPT-4 for complex reasoning, code review, detailed analysis
- Switch models mid-conversation to balance cost and capability

---

### 2. Creating Conversations

**New Conversation**:

1. Click **+ New Chat** in sidebar
2. Select model
3. Start typing

**Conversation Auto-Naming**:
- Title auto-generated from first message
- Example: "What is quantum computing?" → "Quantum Computing"

**Rename Conversation**:
1. Hover over conversation in sidebar
2. Click **⋮** (three dots)
3. Select **Rename**
4. Enter new title

---

### 3. Chat Features

#### Streaming Responses

Messages appear word-by-word as they're generated. Expected latency:
- **First token**: 1-3 seconds
- **Full response**: 5-15 seconds

#### Markdown Support

Open WebUI renders markdown in responses:

- **Bold**: `**text**` → **text**
- **Italic**: `*text*` → *text*
- **Code**: \`code\` → `code`
- **Code blocks**: Syntax highlighted
- **Lists**: Bulleted and numbered
- **Tables**: Formatted nicely

#### Code Syntax Highlighting

```python
def hello():
    print("Hello from GPT-4!")
```

Click **Copy** button to copy code to clipboard.

#### Regenerate Response

If unsatisfied with response:
1. Click **Regenerate** button
2. New response generated (different each time)

#### Edit Messages

To retry with modified prompt:
1. Hover over your message
2. Click **Edit** icon
3. Modify text
4. Press Enter to resubmit

---

### 4. Image Generation with DALL-E 3

**How to Generate Images**:

1. Select **dall-e-3** from model dropdown
2. Type descriptive prompt:
   - ✅ "A serene mountain lake at sunrise with mist"
   - ✅ "Futuristic cityscape with flying cars"
   - ✅ "Abstract art with vibrant colors and geometric shapes"
3. Press Enter
4. Wait 60-120 seconds for generation
5. Image appears in chat

**Download Images**:
- Right-click image → **Save image as...**
- Or click download icon (if shown)

**Tips for Better Images**:
- Be specific (colors, style, mood, composition)
- Mention art style: "photorealistic", "watercolor", "digital art", "oil painting"
- Include lighting: "golden hour", "dramatic lighting", "soft shadows"
- Avoid content policy violations (violence, inappropriate content)

**Image Sizes** (DALL-E 3):
- Square: 1024x1024
- Landscape: 1792x1024
- Portrait: 1024x1792

(Specify in prompt: "landscape orientation" or "portrait orientation")

---

### 5. Conversation Management

#### Search Conversations

1. Click search icon in sidebar
2. Type keyword
3. Matching conversations highlighted

#### Archive Conversations

1. Hover over conversation in sidebar
2. Click **⋮** (three dots)
3. Select **Archive**

Archived conversations hidden from main list but preserved in database.

#### Delete Conversations

1. Hover over conversation
2. Click **⋮** → **Delete**
3. Confirm deletion

**Warning**: Deleted conversations are permanently removed.

#### Export Conversations

1. Open conversation
2. Click **⋮** at top-right
3. Select **Export**
4. Choose format (Markdown, JSON, Text)

Useful for:
- Backing up important conversations
- Sharing with others
- Importing into other tools

---

### 6. Model Switching Mid-Conversation

**Use Case**: Start with GPT-3.5 Turbo for quick exploration, switch to GPT-4 for detailed analysis.

**How**:
1. Start conversation with gpt-35-turbo
2. Ask initial questions
3. Switch to gpt-4 in dropdown
4. Continue conversation

**Context Preservation**:
- Full conversation history sent to new model
- Previous messages used for context
- New model can reference earlier messages

**Example**:

```
[gpt-35-turbo]
User: What are the main features of Python?
Assistant: Lists 10 features quickly

[Switch to gpt-4]
User: Explain feature #3 in detail with code examples
Assistant: Provides detailed explanation with examples
```

---

### 7. Usage Monitoring

#### View Usage Dashboard

Navigate to `http://localhost:4000/ui` to access LiteLLM dashboard.

**Metrics Available**:
- **Request count**: Total API calls
- **Token usage**: Input/output tokens per model
- **Cost estimates**: Based on Azure OpenAI pricing
- **Latency**: Average response time
- **Error rates**: Failed requests

**Cost Estimation**:

| Model | Input Cost (per 1K tokens) | Output Cost (per 1K tokens) |
|-------|----------------------------|------------------------------|
| GPT-4 | ~$0.01 | ~$0.03 |
| GPT-3.5 Turbo | ~$0.0005 | ~$0.0015 |
| DALL-E 3 | N/A | ~$0.04 per image |

**Monthly Budget Planning**:

Estimate daily usage:
- 50 GPT-4 messages (avg 1K tokens each): ~$2/day
- 100 GPT-3.5 messages: ~$0.15/day
- 5 DALL-E images: ~$0.20/day

**Monthly**: ~$70-$80 for moderate usage

---

## Advanced Features

### 8. System Prompts (Personas)

Create custom personas for specialized tasks:

1. Click **Settings** (top-right)
2. Navigate to **Personalization**
3. Create new persona:
   - **Name**: "Code Reviewer"
   - **Description**: "Expert code reviewer focused on best practices"
   - **System Prompt**: "You are an expert code reviewer. Review code for bugs, security issues, and best practices. Provide constructive feedback."

4. Select persona before starting conversation

**Example Personas**:
- **Technical Writer**: Converts technical jargon to clear documentation
- **Data Analyst**: Interprets data and provides insights
- **Creative Writer**: Generates stories, poems, scripts
- **Tutor**: Explains concepts step-by-step

---

### 9. Conversation Templates

Save common prompts as templates:

1. Create conversation with effective prompt
2. Export as template
3. Reuse for similar tasks

**Example Templates**:
- Code review checklist
- Meeting notes summarization
- Email drafting
- Report generation

---

### 10. Keyboard Shortcuts

Speed up workflow with shortcuts:

- **Ctrl/Cmd + Enter**: Send message
- **Ctrl/Cmd + K**: Search conversations
- **Ctrl/Cmd + N**: New conversation
- **Escape**: Close modals
- **↑ / ↓**: Navigate message history

---

## Best Practices

### Effective Prompting

#### Be Specific
- ❌ "Write code"
- ✅ "Write a Python function that validates email addresses using regex"

#### Provide Context
- ❌ "Fix this bug"
- ✅ "This Python function should return True for valid emails, but it returns False for 'test@example.com'. Here's the code: [code]"

#### Break Down Complex Tasks
- ❌ "Build a web app for task management"
- ✅ "Step 1: Design database schema for task management app with users, projects, and tasks"

#### Use Examples
- ✅ "Translate this to French. Example: 'Hello' → 'Bonjour'. Text: 'Good morning'"

### Cost Optimization

1. **Start with GPT-3.5 Turbo**: Use for initial exploration
2. **Switch to GPT-4 when needed**: For complex reasoning
3. **Keep prompts concise**: Reduce input tokens
4. **Start new conversations**: Avoid sending long history each time
5. **Monitor usage**: Check LiteLLM dashboard regularly

### Conversation Organization

1. **Use descriptive titles**: "Python Email Validator Bug" vs "Conversation 1"
2. **Archive old conversations**: Keep sidebar clean
3. **Export important results**: Save to files for reference
4. **Delete test conversations**: Reduce clutter

---

## Troubleshooting Tips

### Slow Responses

- Check network connection
- Try GPT-3.5 Turbo (faster)
- Start new conversation (shorter context)

### Unexpected Responses

- Regenerate response
- Rephrase prompt with more context
- Check if correct model selected

### Content Policy Errors (Images)

- Modify prompt to be more neutral
- Avoid violence, inappropriate content
- Try different phrasing

---

## Next Steps

- **Explore Open WebUI docs**: https://docs.openwebui.com
- **Monitor costs**: Azure Portal → Cost Management
- **Customize models**: Edit litellm_config.yaml
- **Backup data**: See [SETUP.md](SETUP.md) Part 5
- **Report issues**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Enjoy your private AI chatbot!** 🚀
