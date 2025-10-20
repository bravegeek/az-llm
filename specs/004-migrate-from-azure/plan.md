# Implementation Plan: Migrate to Azure AI Foundry

**Branch**: `004-migrate-from-azure` | **Date**: 2025-10-19 | **Spec**: [spec.md](spec.md)
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

**IMPORTANT**: The /plan command STOPS at step 8. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

This feature migrates the existing Azure OpenAI Service infrastructure to Azure AI Foundry (hub and project model). The migration maintains all 5 model deployments (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) with identical TPM allocations (260 total) using a cut-over migration strategy. The infrastructure remains single-file Bicep (<300 lines) with the same deployment automation scripts and test suite structure, requiring client applications to update connection strings to AI Foundry-specific endpoints.

## Technical Context

**Language/Version**: Bicep (latest), Bash 4.0+, Azure CLI 2.50+
**Primary Dependencies**: Azure Bicep, Azure CLI, jq (JSON parsing), Azure AI Foundry SDK
**Storage**: N/A (infrastructure only)
**Testing**: Bash-based integration tests, JSON Schema validation (ajv), Bicep build/lint tests
**Target Platform**: Azure Cloud (eastus2 region by default)
**Project Type**: Single (infrastructure as code)
**Performance Goals**: Deployment completion <10 minutes, validation <2 minutes
**Constraints**: <300 lines Bicep (simplicity-first), region-specific model availability validation required, identical TPM quotas (260 total)
**Scale/Scope**: 5 model deployments, 1 hub, 1 project, 8 test scenarios, 3 deployment scripts

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Simplicity-First ✅
- Single-file Bicep template (<300 lines) maintained
- Reuses existing deployment scripts (deploy.sh, validate.sh, outputs.sh) with minimal changes
- No new abstractions or frameworks introduced
- Azure-native Bicep resources only

### II. Test-First Development ✅
- Existing test suite structure preserved in tests/bicep/
- Contract tests validate input/output schemas
- Integration tests validate 6 quickstart scenarios
- All tests updated to validate AI Foundry resources instead of OpenAI
- Tests will fail until implementation complete (Red-Green-Refactor)

### III. Azure-Native Integration ✅
- Uses Azure Bicep for infrastructure as code
- Leverages Azure CLI for deployment automation
- Managed identity for authentication (no keys in deployment)
- Azure AI Foundry native resources (hub, project, deployments)

### IV. Clear Contracts ✅
- Input contract: JSON parameters file with 17+ parameters
- Output contract: JSON outputs file compatible with .env.azure-openai format
- JSON Schema validation for both input and output
- Versioned contract specifications in contracts/

### V. Observability ✅
- Deployment logs with structured output (JSON where applicable)
- Correlation tracking through deployment scripts
- Health check validation in quickstart scenarios
- Error messages with clear diagnostics

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
├── main.bicep                    # Single-file AI Foundry infrastructure (to be updated)
├── main.parameters.json          # 17+ parameters for 5 models + hub/project
└── README.md                     # Updated deployment documentation

scripts/
├── deploy.sh                     # Minimal updates for AI Foundry resource types
├── validate.sh                   # Add region/model availability validation
└── outputs.sh                    # Update for AI Foundry output structure

tests/bicep/
├── linter.test.sh               # Bicep syntax validation (update resource types)
├── build.test.sh                # ARM compilation test (update expectations)
├── parameter-validation.test.sh # Schema validation (update for new params)
├── contract-input.test.sh       # Input contract test (update schema)
├── contract-output.test.sh      # Output contract test (update schema)
└── quickstart-scenario-*.test.sh # 6 integration tests (update for AI Foundry)

.specify/
└── memory/
    └── constitution.md           # Project principles (no changes)
```

**Structure Decision**: Single project structure maintained. Infrastructure code in `/infra`, deployment automation in `/scripts`, tests in `/tests/bicep`. This aligns with existing Feature 003 structure and maintains simplicity-first principle.

## Phase 0: Outline & Research

**Research Topics**:

1. **Azure AI Foundry Resource Hierarchy**
   - Decision: Understand Hub → Project → Deployment resource relationships
   - Questions: What are the required properties? What SKUs are available? What are naming constraints?

2. **Model Availability in AI Foundry**
   - Decision: Identify which models are available in which regions
   - Questions: Are all 5 models (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) available in eastus2? How to validate programmatically?

3. **AI Foundry vs OpenAI Output Differences**
   - Decision: Understand endpoint URL format, authentication mechanism, output structure
   - Questions: What fields change in outputs? What format are AI Foundry endpoints? How does managed identity work?

4. **Bicep Resource Type Naming**
   - Decision: Determine correct Bicep resource types for AI Foundry
   - Questions: Is it `Microsoft.MachineLearningServices/workspaces`? What API version? What child resources?

5. **Migration Path Validation**
   - Decision: Determine validation steps before deleting old resources
   - Questions: What constitutes a successful deployment? How to verify model endpoints respond? What rollback strategy?

**Output**: research.md with all decisions documented

## Phase 1: Design & Contracts

### Data Model

**Entities**:

1. **AI Foundry Hub**
   - Properties: name, location, sku, identity
   - Relationships: Parent of Project(s)
   - Validation: Name uniqueness, valid location, valid SKU

2. **AI Foundry Project**
   - Properties: name, hubResourceId, location
   - Relationships: Child of Hub, parent of Deployments
   - Validation: Valid hub reference, location match

3. **Model Deployment** (5 instances)
   - Properties: modelName, modelVersion, capacityTPM, deploymentName
   - Relationships: Child of Project
   - Validation: Model availability in region, TPM within quotas

4. **Deployment Parameters**
   - Properties: 17+ parameters (location, hubName, projectName, 5×3 model params)
   - Validation: JSON Schema v7, required fields, value ranges

5. **Deployment Outputs**
   - Properties: hubId, projectId, 5× model endpoints, keys
   - Format: Compatible with .env.azure-openai structure
   - Validation: JSON Schema v7, all fields present

### Contracts

**Input Contract**: `contracts/input-schema.json`
- JSON Schema for main.parameters.json
- Required: location, hubName, projectName, 5 model configurations
- Validation rules: name formats, TPM ranges, version formats

**Output Contract**: `contracts/output-schema.json`
- JSON Schema for deployment outputs
- Required: hubResourceId, projectResourceId, 5 model endpoint objects
- Format: Each model has { endpoint, key, deploymentName, model, version }

### Quickstart Scenarios

1. **Scenario 1**: Deploy fresh AI Foundry infrastructure
2. **Scenario 2**: Validate all 5 models deployed with correct TPM
3. **Scenario 3**: Extract outputs to .env format
4. **Scenario 4**: Test model endpoint connectivity
5. **Scenario 5**: Validate region-specific model availability
6. **Scenario 6**: Deploy with invalid region (expect failure)

### Agent Context Update

Run: `.specify/scripts/bash/update-agent-context.sh claude`

**Output**: data-model.md, contracts/input-schema.json, contracts/output-schema.json, quickstart.md, CLAUDE.md updated

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Extract tasks from Phase 1 artifacts:
  - 2 contract schema files → 2 contract test tasks [P]
  - 1 Bicep file update → 1 implementation task
  - 3 deployment scripts → 3 update tasks [P]
  - 6 test files → 6 test update tasks [P]
  - 6 quickstart scenarios → 6 integration test tasks
  - 1 README update → 1 documentation task

**Ordering Strategy**:
- Phase 3.1 Setup: Archive old infra (sequential)
- Phase 3.2 Tests: Contract tests [P] + test suite updates [P]
- Phase 3.3 Core: Bicep implementation (sequential, depends on tests)
- Phase 3.4 Integration: Script updates [P] + quickstart validation
- Phase 3.5 Polish: Documentation, validation

**Estimated Output**: 22-25 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following constitutional principles)
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

No constitutional violations. Single-file Bicep approach maintained, TDD enforced, Azure-native resources used exclusively.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - research.md created
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md, CLAUDE.md updated
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command) - tasks.md with 24 ordered tasks created
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (via /clarify phase)
- [x] Complexity deviations documented (none - no violations)

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
