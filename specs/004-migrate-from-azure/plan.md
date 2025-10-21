# Implementation Plan: Azure AI Foundry Deployment

**Branch**: `004-migrate-from-azure` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/home/greg/dev/az-llm/specs/004-migrate-from-azure/spec.md`

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
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

Deploy hub-less Azure AI Foundry project with 5 model deployments (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) in a clean resource group. Infrastructure uses single-file Bicep (<300 lines), maintains 260 TPM total allocation, includes deployment automation scripts, and follows TDD with comprehensive test suite.

## Technical Context

**Language/Version**: Bicep (latest), Bash 4.0+, Azure CLI 2.50+
**Primary Dependencies**: Azure Bicep, Azure CLI, jq (JSON parsing), Azure AI Foundry SDK
**Storage**: N/A (infrastructure as code)
**Testing**: Bash-based integration tests, JSON Schema validation (ajv), Bicep lint/build tests
**Target Platform**: Azure Cloud (eastus2 region default)
**Project Type**: Single (infrastructure as code)
**Performance Goals**: Deployment completion <10 minutes, validation <2 minutes
**Constraints**: <300 lines Bicep (simplicity-first), hub-less architecture (no separate hub resource), clean resource group required, region-specific model availability validation
**Scale/Scope**: 5 model deployments, 1 AI Foundry project, 6 quickstart scenarios, 3 deployment scripts

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Simplicity-First ✅
- Single-file Bicep template (<300 lines) maintained
- Hub-less AI Foundry project (simplest 2025 architecture - no separate hub)
- Reuses deployment script patterns from existing infrastructure
- No new frameworks or abstractions introduced
- Azure-native Bicep resources only

### II. Test-First Development ✅
- Test suite structure in tests/bicep/ (linter, build, contracts, integration)
- Contract tests validate input/output schemas
- Integration tests validate 6 quickstart scenarios
- Tests will fail before implementation (Red-Green-Refactor)
- All tests must pass before deployment considered complete

### III. Azure-Native Integration ✅
- Uses Azure Bicep for infrastructure as code
- Leverages Azure CLI for deployment automation
- Managed identity for authentication (FR-009)
- Azure AI Foundry native resources (hub-less project, model deployments)
- No external dependencies outside Azure ecosystem

### IV. Clear Contracts ✅
- Input contract: JSON parameters file with model specifications
- Output contract: JSON outputs in .env format
- JSON Schema validation for both input and output
- Versioned contract specifications in contracts/
- OpenAPI-compatible where applicable

### V. Observability ✅
- Deployment logs with structured output (JSON where applicable)
- Correlation tracking through deployment scripts
- Health check validation in quickstart scenarios
- Clear error messages with diagnostics
- Model endpoint connectivity validation

**Gate Result**: PASS - No constitutional violations

## Project Structure

### Documentation (this feature)
```
specs/004-migrate-from-azure/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── input-schema.json
│   └── output-schema.json
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
infra/
├── main.bicep                    # Single-file AI Foundry infrastructure
├── main.parameters.json          # Model configurations and resource settings
└── README.md                     # Deployment documentation

scripts/
├── deploy.sh                     # Azure deployment automation
├── validate.sh                   # Pre-deployment validation (region, quota, resource group)
└── outputs.sh                    # Extract outputs to .env format

tests/bicep/
├── linter.test.sh               # Bicep syntax validation
├── build.test.sh                # ARM compilation test
├── parameter-validation.test.sh # Input schema validation
├── contract-input.test.sh       # Input contract test
├── contract-output.test.sh      # Output contract test
└── quickstart-scenario-*.test.sh # 6 integration tests

.specify/
└── memory/
    └── constitution.md           # Project principles (no changes)
```

**Structure Decision**: Single project structure for infrastructure as code. All Bicep in `/infra`, automation in `/scripts`, tests in `/tests/bicep`. Follows existing pattern from Feature 003 for consistency and simplicity.

## Phase 0: Outline & Research

**Research Topics**:

1. **Azure AI Foundry Hub-less Architecture (2025)**
   - Decision: Understand hub-less AI Foundry project model vs hub-based
   - Questions: What Bicep resource type? What properties required? What's auto-created?

2. **Model Deployment in AI Foundry**
   - Decision: Identify correct Bicep syntax for deploying models to AI Foundry project
   - Questions: Resource type for deployments? How to specify TPM allocations? Version syntax?

3. **Model Availability Validation**
   - Decision: How to programmatically validate model availability in target region
   - Questions: Azure CLI commands? API calls? What's the model catalog structure?

4. **TPM Quota Validation**
   - Decision: How to check available TPM quota before deployment
   - Questions: Azure CLI quota commands? How to fail gracefully if insufficient?

5. **Clean Resource Group Validation**
   - Decision: How to validate resource group is empty before deployment
   - Questions: Bicep pre-deployment checks? Bash validation in deploy.sh?

**Output**: research.md with all decisions documented

## Phase 1: Design & Contracts

### Data Model

**Entities**:

1. **AI Foundry Project**
   - Properties: name, location, kind (AI Foundry hub-less)
   - Relationships: Parent of Model Deployments
   - Validation: Name uniqueness, valid location, hub-less configuration

2. **Model Deployment** (5 instances)
   - Properties: modelName, modelVersion, capacityTPM, deploymentName
   - Relationships: Child of AI Foundry Project
   - Validation: Model availability in region, TPM within quotas, valid versions

3. **Deployment Parameters**
   - Properties: location, projectName, 5× model configurations (name, version, TPM)
   - Validation: JSON Schema v7, required fields, TPM sum = 260

4. **Deployment Outputs**
   - Properties: projectId, 5× model endpoints with keys
   - Format: .env compatible (KEY=value)
   - Validation: JSON Schema v7, all models present

### Contracts

**Input Contract**: `contracts/input-schema.json`
- JSON Schema for main.parameters.json
- Required: location, projectName, 5 model configurations
- Validation rules: name formats, TPM ranges (sum=260), version formats

**Output Contract**: `contracts/output-schema.json`
- JSON Schema for deployment outputs
- Required: projectResourceId, 5 model endpoint objects
- Format: Each model has { endpoint, key, deploymentName, model, version }

### Quickstart Scenarios

1. **Scenario 1**: Deploy fresh AI Foundry project to clean resource group
2. **Scenario 2**: Validate all 5 models deployed with correct TPM allocations
3. **Scenario 3**: Extract outputs to .env format and verify structure
4. **Scenario 4**: Test model endpoint connectivity for all 5 models
5. **Scenario 5**: Validate region-specific model availability check (pre-deployment)
6. **Scenario 6**: Fail deployment with non-empty resource group (negative test)

### Agent Context Update

Run: `.specify/scripts/bash/update-agent-context.sh claude`

**Output**: data-model.md, contracts/input-schema.json, contracts/output-schema.json, quickstart.md, CLAUDE.md updated

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Extract tasks from Phase 1 artifacts:
  - 2 contract schema files → 2 contract test tasks [P]
  - 1 Bicep file creation → 1 implementation task
  - 3 deployment scripts → 3 script tasks [P]
  - 6 test files → 6 test tasks [P]
  - 6 quickstart scenarios → 6 integration test tasks
  - 1 README update → 1 documentation task

**Ordering Strategy**:
- Phase 3.1 Setup: Create contracts directory structure
- Phase 3.2 Tests: Contract tests [P] + test suite creation [P]
- Phase 3.3 Core: Bicep implementation (sequential, depends on tests)
- Phase 3.4 Integration: Script creation [P] + quickstart validation
- Phase 3.5 Polish: Documentation, final validation

**Estimated Output**: 20-24 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following constitutional principles)
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

No constitutional violations. Hub-less architecture is simpler than hub+project model. Single-file Bicep approach maintained. TDD enforced. Azure-native resources used exclusively.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - research.md created
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md created
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (via /clarify phase)
- [x] Complexity deviations documented (none - no violations)

**Research Findings**:
- ⚠️ **CRITICAL**: FLUX-1.1-pro and DeepSeek-V3.1 are serverless models, cannot be deployed via Bicep
- ✅ Hub-less architecture confirmed: `Microsoft.CognitiveServices/accounts` with `kind: 'AIServices'`
- ✅ Standard models (gpt-4, gpt-4o-mini, gpt-4o) deployable via Bicep with 200K TPM total
- ✅ All validation approaches identified (model availability, quota, clean RG)

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
