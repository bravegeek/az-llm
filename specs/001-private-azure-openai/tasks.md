# Tasks: Private AI Chatbot and Image Generator

**Feature**: 001-private-azure-openai
**Input**: Design documents from `/home/greg/dev/az-llm/specs/001-private-azure-openai/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

---

## Summary

Deploy Open WebUI and LiteLLM in Docker containers, connecting to Azure OpenAI Service for chat and image generation. This is a configuration-as-code project with no custom application code - all functionality comes from pre-built Docker images.

**Key Technologies**:
- Docker Compose for orchestration
- Open WebUI (chat interface)
- LiteLLM (Azure OpenAI proxy)
- YAML configuration files

**Modified TDD Approach**: No unit tests (no code to test). Integration tests validate deployment correctness via quickstart scenarios.

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

---

## Phase 3.1: Setup

- [X] **T001** Create `.gitignore` file in repository root
  **Path**: `/home/greg/dev/az-llm/.gitignore`
  **Description**: Exclude `.env`, Docker volumes, IDE files, and OS-specific files from version control
  **Dependencies**: None

- [X] **T002** Create `.env.example` template in repository root
  **Path**: `/home/greg/dev/az-llm/.env.example`
  **Description**: Provide template with placeholder values for `AZURE_API_KEY` and `AZURE_API_BASE`
  **Dependencies**: None

- [X] **T003** Create `docker-compose.yml` in repository root
  **Path**: `/home/greg/dev/az-llm/docker-compose.yml`
  **Description**: Define services for LiteLLM and Open WebUI containers, named volumes, port mappings, and environment variables per contract schema
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/contracts/docker-compose.schema.yaml`
  **Dependencies**: None

- [X] **T004** Create `litellm_config.yaml` in repository root
  **Path**: `/home/greg/dev/az-llm/litellm_config.yaml`
  **Description**: Define model configurations for GPT-4, GPT-3.5-turbo, and DALL-E 3 per contract schema
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/contracts/litellm-config.schema.yaml`
  **Dependencies**: None

---

## Phase 3.2: Configuration Validation (MUST COMPLETE BEFORE 3.3)

**CRITICAL**: These validation tasks ensure configuration files are correct before deployment

- [X] **T005** [P] Validate `docker-compose.yml` structure
  **Path**: `/home/greg/dev/az-llm/docker-compose.yml`
  **Description**: Verify file matches schema - check services (litellm, openwebui), volumes (open-webui), port mappings, environment variables
  **Validation**: Run `docker-compose config` to check syntax, verify output matches expected structure
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/contracts/docker-compose.schema.yaml`
  **Dependencies**: T003

- [X] **T006** [P] Validate `litellm_config.yaml` structure
  **Path**: `/home/greg/dev/az-llm/litellm_config.yaml`
  **Description**: Verify file matches schema - check model_list has 3+ models, all use `azure/` prefix, api_version is `2024-02-01`, api_key uses env var reference
  **Validation**: Parse YAML and check all required fields present
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/contracts/litellm-config.schema.yaml`
  **Dependencies**: T004

- [X] **T007** [P] Validate `.env.example` template
  **Path**: `/home/greg/dev/az-llm/.env.example`
  **Description**: Verify template includes AZURE_API_KEY and AZURE_API_BASE with placeholder values (not real credentials)
  **Validation**: Check file contains required variables with example values
  **Dependencies**: T002

---

## Phase 3.3: Integration Testing (Deployment Validation)

**NOTE**: These are manual validation scenarios from quickstart.md

- [ ] **T008** Integration test: Container health check
  **Scenario**: quickstart.md Scenario 1
  **Description**: Run `docker-compose up -d`, verify both containers start, check logs show no errors
  **Success Criteria**: Both containers show "Up" status, LiteLLM logs show "Uvicorn running", Open WebUI logs show "Application startup complete"
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 103-124
  **Dependencies**: T003, T004, T005, T006

- [ ] **T009** Integration test: Admin account creation
  **Scenario**: quickstart.md Scenario 2
  **Description**: Navigate to localhost:3000, create admin account, verify login works
  **Success Criteria**: Account created, automatically logged in, chat interface visible
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 126-148
  **Dependencies**: T008

- [ ] **T010** Integration test: Chat with GPT-4 streaming
  **Scenario**: quickstart.md Scenario 3
  **Description**: Select GPT-4 model, send message, verify streaming response appears word-by-word
  **Success Criteria**: Response streams within 2-3 seconds, tokens appear incrementally, message persists in history
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 150-177
  **Dependencies**: T009

- [ ] **T011** Integration test: Image generation with DALL-E 3
  **Scenario**: quickstart.md Scenario 4
  **Description**: Select DALL-E 3, enter prompt, wait for image generation, verify image displays and is downloadable
  **Success Criteria**: Image appears after 60-120 seconds, downloadable, conversation shows prompt and result
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 179-202
  **Dependencies**: T009

- [ ] **T012** Integration test: Model switching preserves context
  **Scenario**: quickstart.md Scenario 5
  **Description**: Start conversation with GPT-3.5, switch to GPT-4 mid-conversation, verify context preserved
  **Success Criteria**: Model switches without clearing conversation, previous messages remain visible
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 204-229
  **Dependencies**: T009

- [ ] **T013** Integration test: Usage tracking validation
  **Scenario**: quickstart.md Scenario 6
  **Description**: Send 3 chat messages, generate 1 image, check LiteLLM dashboard shows usage
  **Success Criteria**: Dashboard shows 3 chat requests, 1 image request, token counts, cost estimates
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 231-252
  **Dependencies**: T010, T011

- [ ] **T014** Integration test: Conversation persistence across restarts
  **Scenario**: quickstart.md Scenario 7
  **Description**: Create conversation, run `docker-compose down`, restart with `docker-compose up -d`, verify conversation preserved
  **Success Criteria**: All messages present after restart, conversation title unchanged
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 254-278
  **Dependencies**: T009

- [ ] **T015** Integration test: Error handling for invalid credentials
  **Scenario**: quickstart.md Scenario 8
  **Description**: Set invalid AZURE_API_KEY in .env, restart containers, verify error message displayed
  **Success Criteria**: Open WebUI shows authentication error, container doesn't crash
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 280-302
  **Dependencies**: T008

- [ ] **T016** Integration test: Error handling for rate limits
  **Scenario**: quickstart.md Scenario 9
  **Description**: Send rapid-fire messages, observe 429 error handling
  **Success Criteria**: 429 error displayed in UI, LiteLLM logs show rate limit, subsequent requests succeed after quota resets
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 304-321
  **Dependencies**: T009

---

## Phase 3.4: Documentation

- [X] **T017** [P] Create `README.md` in repository root
  **Path**: `/home/greg/dev/az-llm/README.md`
  **Description**: Main project documentation with overview, quick start (5-minute setup), architecture diagram, prerequisites, and links to detailed docs
  **Content**: Project summary, technology stack, quick start commands, link to docs/SETUP.md
  **Dependencies**: None

- [X] **T018** [P] Create `docs/` directory and `SETUP.md`
  **Path**: `/home/greg/dev/az-llm/docs/SETUP.md`
  **Description**: Detailed setup guide with step-by-step instructions, Azure OpenAI provisioning, credential configuration, first-time deployment
  **Content**: Prerequisites checklist, Azure setup, .env configuration, container deployment, verification steps
  **Dependencies**: None

- [X] **T019** [P] Create `docs/TROUBLESHOOTING.md`
  **Path**: `/home/greg/dev/az-llm/docs/TROUBLESHOOTING.md`
  **Description**: Common issues and solutions - port conflicts, invalid credentials, model not found, quota errors, data loss
  **Content**: Issue table from quickstart.md lines 333-340, with symptoms and solutions
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 333-340
  **Dependencies**: None

- [X] **T020** [P] Create `docs/USAGE.md`
  **Path**: `/home/greg/dev/az-llm/docs/USAGE.md`
  **Description**: User guide for Open WebUI features - chat interface, model selection, conversation management, image generation, usage dashboard
  **Content**: Feature walkthroughs, screenshots (placeholders), tips for effective prompts, cost monitoring
  **Dependencies**: None

---

## Phase 3.5: Cleanup and Validation

- [ ] **T021** Run complete testing checklist
  **Description**: Execute all 10 quickstart scenarios (T008-T016) in sequence to validate end-to-end deployment
  **Success Criteria**: All scenarios pass without errors
  **Reference**: `/home/greg/dev/az-llm/specs/001-private-azure-openai/quickstart.md` lines 368-379
  **Dependencies**: T008-T016

- [ ] **T022** Verify all artifacts created
  **Description**: Check all required files exist - docker-compose.yml, litellm_config.yaml, .env.example, .gitignore, README.md, docs/*.md
  **Success Criteria**: All 8 configuration and documentation files present
  **Dependencies**: T001-T004, T017-T020

- [ ] **T023** Update project documentation with actual deployment results
  **Description**: Add screenshots to USAGE.md, update performance metrics in README.md if different from estimates, document any deployment-specific notes
  **Dependencies**: T021

---

## Dependencies Graph

```
Setup (T001-T004)
  ↓
Validation (T005-T007) [PARALLEL]
  ↓
T008 (Container health)
  ↓
T009 (Admin account)
  ↓
T010-T012 [Can run after T009]
  ↓
T013 (Depends on T010 + T011)
  ↓
T014-T016 [Can run after T009]

Documentation (T017-T020) [PARALLEL - can start anytime]

Cleanup (T021-T023)
  ↓
COMPLETE
```

---

## Parallel Execution Examples

### Setup Phase (Sequential)
```bash
# Run setup tasks one by one (different files)
# T001: Create .gitignore
# T002: Create .env.example
# T003: Create docker-compose.yml
# T004: Create litellm_config.yaml
```

### Validation Phase (Parallel - T005-T007)
```bash
# All validation tasks check different files - can run in parallel
Task: "Validate docker-compose.yml matches schema"
Task: "Validate litellm_config.yaml matches schema"
Task: "Validate .env.example has required variables"
```

### Documentation Phase (Parallel - T017-T020)
```bash
# All documentation tasks write to different files - can run in parallel
Task: "Create README.md with project overview and quick start"
Task: "Create docs/SETUP.md with detailed setup instructions"
Task: "Create docs/TROUBLESHOOTING.md with common issues"
Task: "Create docs/USAGE.md with Open WebUI user guide"
```

---

## Task Execution Notes

### Modified TDD Approach
This is a **configuration-as-code** project:
- ✅ No unit tests (no application code to test)
- ✅ Configuration validation replaces contract tests (T005-T007)
- ✅ Integration tests validate deployment (T008-T016)
- ✅ Quickstart scenarios serve as acceptance tests

### Testing Strategy
1. **Configuration Validation** (T005-T007): Ensure YAML files are syntactically correct and match schemas
2. **Deployment Testing** (T008): Verify containers start successfully
3. **Functional Testing** (T009-T016): Validate features work end-to-end
4. **Documentation**: Capture setup and usage instructions

### Manual vs Automated
- **Manual tests**: T008-T016 are manual validation scenarios (no test framework)
- **Automated validation**: T005-T007 can use `docker-compose config` and YAML parsing
- **Future enhancement**: Add automated integration tests using Playwright or Selenium

---

## Validation Checklist

- [x] All contracts have corresponding validation tasks (T005-T007)
- [x] All entities documented in data-model.md (no code to implement - using pre-built images)
- [x] All validation tasks before deployment (T005-T007 before T008)
- [x] Parallel tasks are independent (T005-T007, T017-T020)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] All quickstart scenarios covered (T008-T016)

---

## Expected Outcomes

**After T001-T004**: Configuration files ready for deployment
**After T005-T007**: Configuration validated, ready to deploy containers
**After T008**: Containers running, system accessible
**After T009-T016**: All features tested and working
**After T017-T020**: Complete documentation for users
**After T021-T023**: Production-ready deployment validated

---

## Constitutional Compliance

**Simplicity-First**: ✅ Using pre-built Docker images, no custom code
**Test-First Development**: ⚠️ Modified - validation before deployment, integration tests validate correctness
**Azure-Native Integration**: ✅ Connects to Azure OpenAI Service
**Clear Contracts**: ✅ All contracts defined (docker-compose, litellm-config, OpenAI API)
**Observability**: ✅ LiteLLM logging, Docker logs, usage dashboard

---

**Total Tasks**: 23
**Estimated Duration**: 4-6 hours (including Azure provisioning and testing)
**Ready for Implementation**: ✅

---

**Next Step**: Run `/implement` to execute tasks.md in order, or manually execute tasks T001-T023 sequentially
