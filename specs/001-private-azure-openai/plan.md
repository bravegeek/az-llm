
# Implementation Plan: Private AI Chatbot and Image Generator

**Branch**: `001-private-azure-openai` | **Date**: 2025-10-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/home/greg/dev/az-llm/specs/001-private-azure-openai/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code, or `AGENTS.md` for all other agents).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Deploy a private AI chatbot and image generator using Open WebUI frontend and LiteLLM proxy gateway running in local Docker containers, connecting to Azure OpenAI Service for GPT-4, GPT-3.5-turbo, and DALL-E 3 models. The system provides a full-featured chat interface with conversation management, model selection, real-time streaming, and automatic usage tracking for cost monitoring.

## Technical Context
**Language/Version**: YAML (docker-compose.yml, litellm_config.yaml), Shell scripts for setup
**Primary Dependencies**: Open WebUI (Docker image), LiteLLM (Docker image), Docker, Docker Compose
**Storage**: Docker volumes for Open WebUI data persistence (SQLite database), .env file for credentials
**Testing**: Manual integration testing via quickstart scenarios, container health checks
**Target Platform**: Local development machine (Linux/macOS/Windows with Docker support)
**Project Type**: Configuration-as-code (Docker orchestration, no custom application code)
**Performance Goals**: Best-effort latency (depends on Azure OpenAI Service response time)
**Constraints**: Single-user deployment, localhost-only access, requires active internet connection for Azure API
**Scale/Scope**: 1 user, 2 containers (Open WebUI + LiteLLM), 3 configuration files (docker-compose.yml, litellm_config.yaml, .env)

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Simplicity-First**: ✅ PASS
- Using existing, battle-tested open-source tools (Open WebUI, LiteLLM)
- No custom code - pure configuration
- Default features sufficient (no custom abstractions needed)

**II. Test-First Development**: ⚠️ MODIFIED
- No unit tests (no application code to test)
- Integration testing via quickstart scenarios (manual validation)
- Health checks for container availability
- **Justification**: Configuration-as-code project - tests validate deployment works, not code logic

**III. Azure-Native Integration**: ✅ PASS
- Connects to Azure OpenAI Service via official API
- Uses Azure API keys (stored in .env)
- Could use Managed Identity if deployed to Azure Container Instances (future enhancement)

**IV. Clear Contracts**: ✅ PASS
- LiteLLM provides OpenAI-compatible API contract to Open WebUI
- Azure OpenAI Service has well-defined REST API contract
- Model configurations explicitly defined in litellm_config.yaml

**V. Observability**: ✅ PASS
- LiteLLM automatic logging of all requests, tokens, costs
- Docker container logs available via `docker-compose logs`
- LiteLLM usage dashboard for analytics
- Container health status via `docker-compose ps`

## Project Structure

### Documentation (this feature)
```
specs/001-private-azure-openai/
├── spec.md              # Feature specification (user requirements)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (Docker, LiteLLM, Open WebUI research)
├── data-model.md        # Phase 1 output (entity relationships)
├── quickstart.md        # Phase 1 output (deployment & validation scenarios)
├── contracts/           # Phase 1 output (API contracts, config schemas)
│   ├── docker-compose.schema.yaml
│   ├── litellm-config.schema.yaml
│   └── openai-api.yaml
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Configuration Files (repository root)
```
/home/greg/dev/az-llm/
├── docker-compose.yml           # Container orchestration (Open WebUI + LiteLLM)
├── litellm_config.yaml          # LiteLLM model configurations
├── .env                         # Azure OpenAI credentials (gitignored)
├── .env.example                 # Template for .env file
├── README.md                    # Setup instructions
└── docs/
    ├── SETUP.md                 # Detailed setup guide
    ├── TROUBLESHOOTING.md       # Common issues and solutions
    └── USAGE.md                 # User guide for Open WebUI features
```

**Structure Decision**: Configuration-as-code project with no custom source code. All functionality provided by pre-built Docker images (Open WebUI, LiteLLM). Repository contains only configuration files, documentation, and deployment scripts. No src/, tests/, or traditional application directories needed.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract schema → validation test [P]
- Configuration file → creation task
- Quickstart scenario → integration test task
- Documentation → writing task [P]

**Task Categories**:

1. **Setup Tasks** (Sequential):
   - Create docker-compose.yml
   - Create litellm_config.yaml
   - Create .env.example
   - Create .gitignore

2. **Contract Validation Tasks** (Parallel - [P]):
   - Validate docker-compose.yml against schema
   - Validate litellm_config.yaml against schema
   - Validate OpenAI API contract (LiteLLM endpoint test)

3. **Integration Test Tasks** (Sequential - depends on setup):
   - Container health check test
   - Admin account creation test
   - Chat with GPT-4 test
   - Image generation test
   - Model switching test
   - Usage tracking validation test
   - Conversation persistence test
   - Error handling tests

4. **Documentation Tasks** (Parallel - [P]):
   - Write README.md
   - Write docs/SETUP.md
   - Write docs/TROUBLESHOOTING.md
   - Write docs/USAGE.md

**Ordering Strategy**:
- Setup → Validation → Integration → Documentation
- Within categories: Mark [P] for independent tasks
- Configuration-as-code project: No TDD tests for code (constitutional modification documented)
- Integration tests validate deployment correctness (acceptance tests from quickstart.md)

**Estimated Output**: 20-25 numbered tasks in tasks.md

**Note**: Modified TDD approach - no unit tests (no application code), integration tests validate configuration correctness

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Test-First Development (modified) | Configuration-as-code project has no application code to unit test | Writing unit tests for YAML files would be artificial - integration tests from quickstart.md validate deployment correctness instead |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅
- [x] Complexity deviations documented ✅

**Artifacts Generated**:
- [x] research.md - Technology decisions and best practices
- [x] data-model.md - Entity relationships and data structures
- [x] contracts/docker-compose.schema.yaml - Docker Compose validation schema
- [x] contracts/litellm-config.schema.yaml - LiteLLM configuration schema
- [x] contracts/openai-api.yaml - OpenAI API contract (LiteLLM interface)
- [x] quickstart.md - Deployment and validation scenarios
- [x] CLAUDE.md - Updated with feature context

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
