
# Implementation Plan: Minimal Single-File Bicep for OpenAI Provisioning

**Branch**: `003-create-a-minimal` | **Date**: 2025-10-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/home/greg/dev/az-llm/specs/003-create-a-minimal/spec.md`

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
Replace over-engineered ~15-file Bicep infrastructure (App Service, VNet, Static Web App) with a single minimal Bicep file that provisions only Azure OpenAI Service resources linked to existing AI Foundry project. Deploys **5 models** (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) with total 260 TPM capacity. Supports Docker Compose + LiteLLM deployment with API key authentication, targeting single dev/personal workspace.

## Technical Context
**Language/Version**: Bicep (latest stable), Bash scripts for deployment automation
**Primary Dependencies**: Azure CLI, Bicep CLI, existing Azure AI Foundry project (manual creation)
**Storage**: N/A (infrastructure only, no application storage)
**Testing**: Bash-based deployment validation scripts, Bicep syntax validation (`az bicep build`)
**Target Platform**: Azure Resource Manager (ARM) / Azure Cloud
**Project Type**: Infrastructure-as-Code (IaC) single-file deployment
**Performance Goals**: Deployment completes in <10 minutes for initial provisioning
**Constraints**: Single Bicep file <300 lines, <5 commands for deployment, API key auth only
**Scale/Scope**: Single dev/personal environment, 5 model deployments (3 GPT variants + image gen + DeepSeek), 260 TPM total, links to existing AI Foundry

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Simplicity-First ✅ PASS
- **Single Bicep file** (no modules) - explicitly simplifying from 15-file structure
- **No abstractions** - direct Azure resource provisioning
- **Boring tech** - Bicep (official Azure IaC), Azure CLI (standard tooling)
- **Minimal dependencies** - Azure CLI + Bicep CLI only
- **Justification**: This feature IS the simplification - removing unnecessary complexity

### II. Test-First Development ✅ PASS
- **Deployment validation scripts** required (FR-011: syntax validation)
- **Test ordering**: Validation scripts before Bicep implementation
- **Contract tests**: Bicep build/lint tests, deployment dry-run tests
- **Integration tests**: End-to-end deployment → output validation → Docker connectivity

### III. Azure-Native Integration ✅ PASS
- **Bicep** = Azure-native IaC (first-party tool)
- **Azure OpenAI Service** = managed Azure service
- **Azure AI Foundry** = Azure-native project organization
- **API key auth** via Azure-managed keys (listKeys operation)
- **No non-Azure dependencies** for infrastructure

### IV. Clear Contracts ⚠️ PARTIAL
- **Bicep parameters** = explicit contract for inputs
- **Deployment outputs** = explicit contract for results
- **NOTE**: Infrastructure contracts differ from API contracts
  - Parameters file serves as input contract
  - Output variables serve as integration contract with Docker config
  - No OpenAPI spec needed (IaC domain, not REST API)

### V. Observability ⚠️ LIMITED
- **Deployment logs** via Azure CLI output
- **Resource state** observable via Azure Portal/CLI
- **NOTE**: Infrastructure observability differs from application observability
  - Deployment success/failure clearly reported
  - No application-level metrics (this is IaC only)
  - Post-deployment: Azure Monitor for OpenAI service usage

**Pre-Design Gate Status**: ✅ PASS (constitutional alignment, IaC-appropriate adaptations noted)

---

### Post-Design Re-Evaluation

**Phase 1 Complete**: research.md, data-model.md, contracts/, quickstart.md generated

**Constitution Check Results**:

### I. Simplicity-First ✅ PASS (Maintained)
- **Single Bicep file** confirmed in research.md (Decision 2, 3)
- **No unnecessary abstractions** - direct Bicep resources only
- **JSON Schema contracts** - simple, standard format (no custom DSL)
- **Bash scripts** - minimal, <100 lines each per research.md Decision 7

### II. Test-First Development ✅ PASS (Maintained)
- **Test layers defined** in research.md Decision 6:
  - Syntax validation (tests/bicep/linter.test.sh)
  - Build validation (tests/bicep/build.test.sh)
  - Parameter validation (tests/bicep/parameter-validation.test.sh)
  - Integration validation (tests/bicep/deployment.test.sh)
- **Quickstart scenarios** = integration tests (6 scenarios defined)
- **TDD order preserved**: Tests written before Bicep implementation

### III. Azure-Native Integration ✅ PASS (Maintained)
- **Bicep resource types** confirmed in data-model.md:
  - `Microsoft.CognitiveServices/accounts@2023-05-01`
  - `Microsoft.CognitiveServices/accounts/deployments@2023-05-01`
- **listKeys()** for API key retrieval (Azure SDK function)
- **Azure CLI** deployment mechanism (`az deployment group create`)

### IV. Clear Contracts ✅ ENHANCED
- **Input contract**: bicep-parameters.schema.json (JSON Schema draft-07)
- **Output contract**: deployment-outputs.schema.json (JSON Schema draft-07)
- **Data model**: Fully documented entities, relationships, validation rules
- **Integration contract**: Defined mapping from outputs → config.yaml
- **Constitutional requirement EXCEEDED**: IaC contracts now as rigorous as API contracts

### V. Observability ✅ ENHANCED
- **Deployment logs** via Azure CLI output (structured JSON available via `--output json`)
- **Validation scripts** provide clear pass/fail signals
- **Output extraction** script (outputs.sh) provides visibility into deployment state
- **Quickstart scenarios** include log verification steps (Scenario 6.5)
- **IaC-appropriate observability**: Deployment-time visibility sufficient for infrastructure

**Post-Design Gate Status**: ✅ PASS - All constitutional principles satisfied, some exceeded

**Complexity Violations**: None identified - all design decisions align with Simplicity-First

## Project Structure

### Documentation (this feature)
```
specs/003-create-a-minimal/
├── spec.md              # Feature specification
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── bicep-parameters.schema.json   # Input contract
│   └── deployment-outputs.schema.json # Output contract
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
infra/
├── main.bicep               # Single-file OpenAI provisioning (NEW)
├── main.parameters.json     # Deployment parameters (NEW)
└── README.md                # Deployment instructions (NEW)

infra-archive/               # Archived old infrastructure (migration)
└── [old 15-file structure moved here]

scripts/
├── deploy.sh                # Deployment automation (NEW)
├── validate.sh              # Pre-deployment validation (NEW)
└── outputs.sh               # Extract outputs to .env format (NEW)

tests/bicep/
├── linter.test.sh           # Bicep syntax validation (NEW)
├── build.test.sh            # Bicep compilation test (NEW)
├── parameter-validation.test.sh  # Parameters schema test (NEW)
└── deployment.test.sh       # Integration deployment test (NEW)

docker/
└── litellm/
    └── config.yaml          # Existing - updated to use new endpoint
```

**Structure Decision**: Infrastructure-as-Code project with single Bicep file at repository root `infra/` directory. Old complex infrastructure archived to `infra-archive/`. Deployment scripts in `scripts/`, validation tests in `tests/bicep/`. No application source code (IaC only).

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

### Input Artifacts
- **contracts/bicep-parameters.schema.json** → Parameter validation test task (5 models)
- **contracts/deployment-outputs.schema.json** → Output validation test task (5 models)
- **data-model.md** (5 entities) → Bicep resource definition tasks (5 model deployments)
- **quickstart.md** (6 scenarios) → Integration test scenario tasks (5 models tested)
- **research.md** (9 decisions) → Implementation tasks per decision

### Task Categorization
1. **Setup Phase** (1-5):
   - Archive old infrastructure
   - Create directory structure
   - Setup parameter files
   - Create README scaffolding

2. **Test Phase** (6-15) - TDD REQUIRED:
   - [P] Syntax validation test (linter.test.sh)
   - [P] Build validation test (build.test.sh)
   - [P] Parameter validation test (parameter-validation.test.sh)
   - [P] Contract schema validation tests (2 tests)
   - Integration deployment test (deployment.test.sh) - sequential
   - [P] Quickstart scenario tests (6 test case stubs)

3. **Core Implementation** (16-25):
   - Bicep main.bicep file (OpenAI account + 5 model deployments: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1)
   - Parameter file (main.parameters.json) with 5 model configurations
   - Deploy script (scripts/deploy.sh)
   - Validate script (scripts/validate.sh)
   - Outputs script (scripts/outputs.sh) extracting 5 deployment names
   - README documentation (infra/README.md)

4. **Integration** (26-30):
   - Update docker/litellm/config.yaml template
   - Create .env.example file
   - End-to-end validation (run all quickstart scenarios)
   - Documentation finalization

### Ordering Strategy
- **TDD order**: All Test Phase (6-15) BEFORE Core Implementation (16-25)
- **Parallel marker [P]**: Independent test files (linter, build, parameter, contract schemas, quickstart stubs)
- **Sequential**: Integration deployment test depends on Bicep file existence
- **Dependency chains**:
  - Setup → Tests → Implementation → Integration
  - Bicep file → Deployment scripts → README
  - All tests → Quickstart execution

### Estimated Output
- **Total tasks**: ~30 tasks
- **Parallel execution**: ~12 tasks (test stubs, independent scripts)
- **Sequential execution**: ~18 tasks (dependencies, integration)
- **Time estimate**:
  - Tests (Phase 2): ~2 hours
  - Implementation (Phase 3): ~4 hours
  - Integration (Phase 4): ~1 hour
  - **Total**: ~7 hours

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: ✅ No constitutional violations

All design decisions align with Simplicity-First principle:
- Single Bicep file (simplifying from 15 files)
- No abstractions (direct Azure resources)
- Bash scripts <100 lines each
- Standard JSON Schema for contracts
- Azure-native tooling only

No complexity tracking needed.


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - ✅ research.md generated
- [x] Phase 1: Design complete (/plan command) - ✅ data-model.md, contracts/, quickstart.md generated
- [x] Phase 2: Task planning complete (/plan command - describe approach only) - ✅ Task generation strategy documented
- [ ] Phase 3: Tasks generated (/tasks command) - **NEXT STEP**
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (pre-design evaluation complete)
- [x] Post-Design Constitution Check: PASS (all principles satisfied or exceeded)
- [x] All NEEDS CLARIFICATION resolved (all Technical Context items resolved via research)
- [x] Complexity deviations documented (none - all decisions align with Simplicity-First)

**Artifacts Generated**:
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/plan.md (this file)
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/research.md
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/data-model.md
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/quickstart.md
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/contracts/bicep-parameters.schema.json
- ✅ /home/greg/dev/az-llm/specs/003-create-a-minimal/contracts/deployment-outputs.schema.json
- ✅ /home/greg/dev/az-llm/CLAUDE.md (updated via update-agent-context.sh)

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
