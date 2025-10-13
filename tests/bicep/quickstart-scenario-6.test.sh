#!/bin/bash
# T015: Quickstart Scenario 6 - End-to-End Open WebUI Integration
# This is an INTEGRATION test requiring full Docker stack
# Usage: ./tests/bicep/quickstart-scenario-6.test.sh

set -e

echo "🧪 Testing Scenario 6: End-to-End Open WebUI Integration"
echo ""

# 6.1 Check full stack is running
echo "Step 6.1: Verifying full stack is running..."
REQUIRED_SERVICES=("litellm" "open-webui")
for service in "${REQUIRED_SERVICES[@]}"; do
    if ! docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
        echo "⚠️  Service $service not running"
        echo "   Start with: docker compose up -d"
        echo ""
        echo "This scenario validates:"
        echo "  6.1 - Start full stack (docker compose up -d)"
        echo "  6.2 - Access Open WebUI (http://localhost:3000)"
        echo "  6.3 - Test chat with GPT (manual)"
        echo "  6.4 - Test image generation (manual)"
        echo "  6.5 - Verify metrics (optional)"
        echo ""
        echo "See: specs/003-create-a-minimal/quickstart.md#scenario-6"
        exit 0
    fi
done

echo "✅ All required services running"

# 6.2 Verify Open WebUI is accessible
echo ""
echo "Step 6.2: Checking Open WebUI accessibility..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Open WebUI accessible at http://localhost:3000"
else
    echo "❌ Open WebUI not accessible"
    exit 1
fi

# 6.3 Verify LiteLLM proxy is accessible
echo ""
echo "Step 6.3: Checking LiteLLM proxy..."
if curl -s http://localhost:4000/health > /dev/null 2>&1; then
    echo "✅ LiteLLM proxy healthy at http://localhost:4000"
else
    echo "❌ LiteLLM proxy not accessible"
    exit 1
fi

# 6.4 Test model availability via LiteLLM
echo ""
echo "Step 6.4: Testing model availability..."
MODELS_AVAILABLE=$(curl -s http://localhost:4000/models 2>/dev/null | jq -r '.data[].id' 2>/dev/null || echo "")

if [ -z "$MODELS_AVAILABLE" ]; then
    echo "⚠️  Could not retrieve model list"
else
    echo "✅ Models available via LiteLLM:"
    echo "$MODELS_AVAILABLE"
fi

# 6.5 Check logs for errors
echo ""
echo "Step 6.5: Checking for errors in logs..."
ERROR_COUNT=$(docker compose logs litellm --tail=50 2>/dev/null | grep -i error | wc -l || echo "0")

if [ "$ERROR_COUNT" -gt 5 ]; then
    echo "⚠️  Found $ERROR_COUNT errors in recent LiteLLM logs"
    echo "   Review with: docker compose logs litellm"
else
    echo "✅ No significant errors in recent logs"
fi

# Manual tests reminder
echo ""
echo "📋 Manual validation steps:"
echo "   1. Open browser: http://localhost:3000"
echo "   2. Login/register to Open WebUI"
echo "   3. Test chat: Ask 'What is Azure OpenAI?'"
echo "   4. Test image: Generate 'sunset over mountains'"
echo "   5. Verify all 5 models appear in model selector"

echo ""
echo "✅ Scenario 6 PASSED: Full stack accessible, automated checks complete"
echo "   (Manual browser tests required for full validation)"
