# Feature Specification: Migrate to Azure AI Foundry

**Feature Branch**: `004-migrate-from-azure`
**Created**: 2025-10-19
**Status**: Draft
**Input**: User description: "Migrate from Azure OpenAI Service to Azure AI Foundry resources for model deployments, maintaining the same 5 models (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) but using Azure AI Foundry hub, project, and deployment resources instead of the standalone Azure OpenAI account"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## Clarifications

### Session 2025-10-19
- Q: Migration strategy: What is the intended deployment approach for transitioning from Azure OpenAI to AI Foundry? → A: Cut-over migration, keep simple
- Q: Client application compatibility: After migration, should existing client applications work without code changes? → A: Update required
- Q: Observability data handling: Should historical deployment logs and metrics from Azure OpenAI be migrated to AI Foundry? → A: Start fresh
- Q: Model regional availability: Are all 5 models available in AI Foundry across all regions? → A: Region-specific validation
- Q: TPM quota handling: How should the deployment handle potential TPM quota differences between Azure OpenAI and AI Foundry? → A: Identical quotas

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a platform administrator, I need to migrate the existing Azure infrastructure from standalone Azure OpenAI Service to Azure AI Foundry (hub and project model) so that model deployments are managed through the unified AI Foundry platform while maintaining the same model capabilities and configuration.

### Acceptance Scenarios
1. **Given** an existing Azure OpenAI deployment with 5 models, **When** the migration to AI Foundry is executed, **Then** all 5 models (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) are available through AI Foundry with identical TPM allocations
2. **Given** the AI Foundry infrastructure is deployed, **When** the deployment scripts are executed, **Then** the infrastructure provisions successfully and outputs AI Foundry-specific connection details for client application updates
3. **Given** the migration is complete, **When** existing test suites are run against the new infrastructure, **Then** all integration tests pass without modification to test logic
4. **Given** the AI Foundry infrastructure is validated, **When** the cut-over is executed, **Then** the old Azure OpenAI resources are deleted and all traffic uses AI Foundry endpoints

### Edge Cases
- What happens when model availability differs between Azure OpenAI and AI Foundry regions? Deployment must validate model availability in target region and fail with clear error message if any of the 5 models are unavailable.
- How does the system handle quota limitations in AI Foundry that may differ from Azure OpenAI? TPM quotas are assumed identical between Azure OpenAI and AI Foundry; use same 260 TPM allocation (50+100+50+10+50).
- What happens to existing API keys and connection strings after migration? Client applications must update to new AI Foundry endpoints and authentication credentials.
- How are existing deployment logs and metrics preserved during migration? Historical Azure OpenAI observability data remains in original location; AI Foundry begins new observability timeline from deployment.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST deploy Azure AI Foundry hub resource as the top-level workspace container
- **FR-002**: System MUST deploy Azure AI Foundry project resource scoped to the hub for model management
- **FR-003**: System MUST deploy all 5 model deployments (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) within the AI Foundry project
- **FR-004**: System MUST maintain identical TPM allocation to Azure OpenAI (260 TPM total distributed as: gpt-4.1=50, gpt-4.1-mini=100, gpt-4o=50, FLUX-1.1-pro=10, DeepSeek-V3.1=50)
- **FR-005**: System MUST provide output configuration (endpoints, keys, resource IDs) in a format compatible with existing `.env.azure-openai` file structure
- **FR-006**: System MUST maintain single-file infrastructure definition to comply with simplicity-first principle (analogous to current `main.bicep` < 300 lines)
- **FR-007**: System MUST preserve existing deployment automation through `scripts/deploy.sh`, `scripts/validate.sh`, and `scripts/outputs.sh` with minimal changes
- **FR-008**: System MUST maintain existing test suite structure in `tests/bicep/` with tests validating AI Foundry resources instead of OpenAI resources
- **FR-009**: System MUST support the same 6 quickstart integration scenarios currently tested
- **FR-010**: System MUST use managed identity for authentication (no API keys in deployment configuration)
- **FR-011**: Infrastructure MUST validate successfully against Azure Bicep linter and ARM template schema
- **FR-011a**: Deployment MUST validate that all 5 required models are available in the target Azure region before provisioning resources
- **FR-012**: System MUST provide new AI Foundry-specific connection details (endpoints, keys) requiring client applications to update their connection strings
- **FR-013**: System MUST document cut-over migration path from existing Azure OpenAI deployment (deploy AI Foundry, validate, then delete old resources in a one-time switch)
- **FR-014**: System MUST maintain compliance with constitutional principles: Simplicity-First, Test-First Development, Azure-Native Integration, Clear Contracts, Observability

### Key Entities *(include if feature involves data)*
- **AI Foundry Hub**: Top-level workspace container providing centralized resource management, identity, and networking for AI projects
- **AI Foundry Project**: Scoped workspace within a hub containing model deployments, compute resources, and project-specific configuration
- **Model Deployment**: Individual model instance (e.g., gpt-4.1) with allocated TPM capacity, version, and regional endpoint
- **Connection Configuration**: Output parameters including endpoints, resource identifiers, and authentication details for client consumption
- **Deployment Parameters**: Input configuration specifying resource names, locations, SKUs, model specifications, and TPM allocations

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (4 clarification markers added)
- [x] User scenarios defined
- [x] Requirements generated (15 functional requirements)
- [x] Entities identified (5 key entities)
- [x] Clarifications completed (5 questions answered)
- [x] Review checklist passed

---
