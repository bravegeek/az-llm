
# Implementation Plan: Azure Infrastructure as Code

**Branch**: `002-azure-infrastructure-as` | **Date**: 2025-10-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/home/greg/dev/az-llm/specs/002-azure-infrastructure-as/spec.md`

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

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Create Azure infrastructure as code using Bicep to provision and configure Azure OpenAI Service, App Service, Static Web App, and Application Insights. Infrastructure will support multi-environment deployments with private networking, managed identity authentication, and minimal resource tagging for cost tracking.

## Technical Context
**Language/Version**: Bicep (latest) with Azure CLI
**Primary Dependencies**: Azure CLI, Bicep CLI, Azure Resource Manager
**Storage**: N/A (infrastructure only - application data stored in Azure OpenAI Service)
**Testing**: Bicep linter, Azure Policy validation, deployment validation tests
**Target Platform**: Azure (single region deployment)
**Project Type**: Infrastructure (Bicep modules and parameter files)
**Performance Goals**: Deployment completion within 10 minutes
**Constraints**: Hybrid networking (public frontend, backend VNet integration), no secrets in configuration files, managed identity only
**Scale/Scope**: 3 environments (dev/staging/prod), 5 Azure resource types, 3 OpenAI model deployments

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Simplicity-First
- ✅ **PASS**: Single region deployment (simplest topology)
- ✅ **PASS**: Same SKU across all environments (no tiered complexity)
- ✅ **PASS**: Minimal tagging strategy (Environment, Project only)
- ✅ **PASS**: Bicep native features (no custom abstractions)

### Principle II: Test-First Development
- ✅ **PASS**: Deployment validation tests will be written before Bicep templates
- ✅ **PASS**: Bicep linter tests will validate syntax before deployment
- ✅ **PASS**: Azure Policy compliance tests will verify security before implementation

### Principle III: Azure-Native Integration
- ✅ **PASS**: Using Bicep for IaC (Azure-native)
- ✅ **PASS**: Managed identity for authentication (no keys/secrets)
- ✅ **PASS**: Application Insights for observability (Azure-native)
- ✅ **PASS**: Azure CLI and Azure Resource Manager for deployment

### Principle IV: Clear Contracts
- ✅ **PASS**: Bicep parameter files serve as deployment contracts
- ✅ **PASS**: Each environment has versioned parameter file
- ✅ **PASS**: Output values document resource identifiers for application consumption

### Principle V: Observability
- ✅ **PASS**: Application Insights configured for all compute resources
- ✅ **PASS**: Diagnostic settings enabled (deferred to implementation for specific targets)
- ✅ **PASS**: Deployment outputs provide connection information for monitoring

**Result**: No constitutional violations detected

## Project Structure

### Documentation (this feature)
```
specs/002-azure-infrastructure-as/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   └── bicep-deployment.yaml
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
infra/
├── main.bicep                    # Main orchestration template
├── modules/
│   ├── vnet.bicep               # Virtual network with subnets for VNet integration
│   ├── openai.bicep             # Azure OpenAI Service (public with managed identity auth)
│   ├── appservice.bicep         # App Service with managed identity and VNet integration
│   ├── staticwebapp.bicep       # Static Web App (public)
│   └── monitoring.bicep         # Application Insights
├── parameters/
│   ├── dev.bicepparam           # Development environment parameters
│   ├── staging.bicepparam       # Staging environment parameters
│   └── prod.bicepparam          # Production environment parameters
└── scripts/
    ├── deploy.sh                # Deployment orchestration script
    └── validate.sh              # Pre-deployment validation

tests/
├── bicep/
│   ├── linter.test.sh          # Bicep linting tests
│   ├── policy.test.sh          # Azure Policy compliance tests
│   └── deployment.test.sh      # Deployment validation tests
└── integration/
    └── infrastructure.test.sh   # End-to-end infrastructure tests
```

**Structure Decision**: Infrastructure project layout with modular Bicep templates. Each Azure resource type is isolated in its own module under `infra/modules/`. Hybrid networking approach: Static Web App (public), App Service with VNet integration, Azure OpenAI Service (public with managed identity authentication). Environment-specific configurations are managed through Bicep parameter files in `infra/parameters/`. This follows Azure best practices for Bicep project organization and supports independent module testing.

## Phase 0: Outline & Research

**Unknowns from spec (deferred items)**:
1. Compliance requirements (FR-014)
2. Template orchestration approach (FR-015)
3. Backup/DR settings (FR-017)
4. Diagnostic logging targets (FR-018)

**Research tasks**:
1. Bicep best practices for modular infrastructure
2. Hybrid networking patterns (public frontend + VNet backend)
3. Managed identity role assignments for Azure OpenAI Service
4. Static Web App integration with VNet-enabled backends
5. Environment parameter management strategies
6. Deployment validation and testing approaches
7. Default Azure compliance and security settings

**Output**: research.md with decisions on template structure, networking configuration, and deployment orchestration

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Infrastructure Environment (dev/staging/prod configurations)
   - Azure OpenAI Service Instance (model deployments, capacity)
   - App Service Instance (SKU, managed identity)
   - Static Web App Instance (build configuration)
   - Application Insights Instance (telemetry settings)
   - Virtual Network (subnets, private endpoints)
   - Resource Tags (Environment, Project metadata)

2. **Generate deployment contracts**:
   - Bicep parameter schema (OpenAPI-style for validation)
   - Environment parameter file structure
   - Deployment output schema (resource IDs, endpoints)

3. **Generate contract tests**:
   - Parameter validation tests (schema compliance)
   - Output validation tests (required fields present)
   - Resource dependency tests (correct deployment order)

4. **Extract test scenarios** from user stories:
   - Fresh deployment scenario (no existing resources)
   - Update deployment scenario (infrastructure changes)
   - Multi-environment scenario (consistent deployment)
   - Security validation scenario (managed identity, no secrets)

5. **Update agent file**: Run `.specify/scripts/bash/update-agent-context.sh claude`

**Output**: data-model.md, /contracts/bicep-deployment.yaml, validation tests, quickstart.md, CLAUDE.md

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Bicep modules and parameter files
- Each module → module creation task [P]
- Each parameter file → parameter configuration task [P]
- Each validation test → test creation task [P]
- Integration tasks for end-to-end deployment

**Ordering Strategy**:
- TDD order: Validation tests before Bicep templates
- Dependency order: Networking → Services → Configuration
- Mark [P] for parallel module development (independent files)

**Estimated Output**: 15-20 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following constitutional principles)
**Phase 5**: Validation (run tests, execute quickstart.md, deployment validation)

## Complexity Tracking
*No constitutional violations - section left empty*

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (deferred items handled via research)
- [x] Complexity deviations documented (none - no violations)

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
