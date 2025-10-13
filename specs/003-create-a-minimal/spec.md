# Feature Specification: Minimal Single-File Bicep for OpenAI Provisioning

**Feature Branch**: `003-create-a-minimal`
**Created**: 2025-10-12
**Status**: Draft
**Input**: User description: "Create a minimal single-file Bicep replacement (just OpenAI provisioning)"

## Execution Flow (main)
```
1. Parse user description from Input
   → Feature is clear: Simplify over-engineered infrastructure
2. Extract key concepts from description
   → Actors: DevOps engineers, developers
   → Actions: Deploy Azure OpenAI, configure endpoints
   → Data: OpenAI configuration parameters
   → Constraints: Simplicity-first, Docker-based deployment
3. For each unclear aspect:
   → Minimal clarifications needed (see Requirements)
4. Fill User Scenarios & Testing section
   → Primary: Replace complex multi-module Bicep with single file
5. Generate Functional Requirements
   → Each requirement testable via deployment and validation
6. Identify Key Entities
   → Azure OpenAI Service configuration
7. Run Review Checklist
   → Mark remaining clarifications
8. Return: SUCCESS (spec ready for planning)
```

---

## Context & Motivation

### Current Problem
The existing infrastructure (`infra/` directory) contains **over-engineered Bicep templates** designed for a full Azure-hosted web application:
- Virtual Network with subnet integration
- App Service Plan + App Service (backend API)
- Static Web App (frontend)
- Log Analytics Workspace + Application Insights
- Multiple modules, parameters, and environments
- **~15 files total** for infrastructure that isn't being used

### Actual Setup
The project currently runs:
- **Docker Compose** locally with LiteLLM + Open WebUI
- **Azure AI Foundry Project** (manually created in portal)
- **Azure OpenAI Service** accessed via API key
- Configuration in `docker/litellm/config.yaml` pointing to Azure endpoints

### Why This Feature
Follows the **Simplicity-First** constitutional principle by eliminating unused complexity and replacing it with infrastructure that matches actual deployment needs.

---

## Clarifications

### Session 2025-10-12
- Q: Should the Bicep template reference existing AI Foundry resources or create new separate OpenAI resources? → A: Create new Azure OpenAI and link it to existing AI Foundry project
- Q: For the new Bicep-deployed OpenAI resources, which authentication method should be supported? → A: API key only (simplest, current approach)
- Q: How many deployment environments need to be supported? → A: Single environment only (dev or personal workspace)
- Q: Should the old over-engineered infrastructure resources be deleted or preserved during migration? → A: Archive old Bicep files and delete Azure resources
- Q: What should happen if model deployment fails due to quota limits during provisioning? → A: Deployment fails immediately with clear error message

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a **DevOps engineer** managing this project, I want to **provision only the Azure OpenAI resources needed** for my Docker-based deployment, so that I can **maintain infrastructure-as-code without unnecessary complexity**.

### Acceptance Scenarios

1. **Given** the current over-engineered Bicep infrastructure exists, **When** I replace it with the minimal single-file Bicep, **Then** I can deploy only Azure OpenAI Service resources
2. **Given** the minimal Bicep is deployed, **When** I retrieve deployment outputs, **Then** I receive the OpenAI endpoint URL and API key needed for `.env` configuration
3. **Given** the minimal Bicep is deployed, **When** my Docker containers start, **Then** LiteLLM successfully connects to the deployed Azure OpenAI endpoint
4. **Given** I need to update OpenAI model deployments, **When** I modify the Bicep parameters, **Then** I can redeploy without affecting unrelated resources
5. **Given** the old infrastructure exists, **When** I transition to minimal Bicep, **Then** existing Azure OpenAI resources remain functional without downtime

### Edge Cases
- When deploying to a resource group with existing AI Foundry resources, the Bicep template creates new Azure OpenAI Service resources and links them to the existing AI Foundry project
- The system targets a single development/personal workspace environment (no multi-environment orchestration needed)
- During migration, old Bicep files are archived (not deleted) for historical reference, while old Azure resources (App Service, VNet, etc.) are deleted to reduce costs
- If model deployment fails due to TPM quota limits, the deployment fails immediately with a clear error message indicating the quota exceeded and required action (no automatic retry or fallback)
- If deployment fails partway through, Azure's resource manager handles automatic rollback of resources created within that deployment transaction

---

## Requirements *(mandatory)*

### Functional Requirements

**Infrastructure Provisioning**
- **FR-001**: System MUST provision new Azure OpenAI Service resources via a single Bicep file and link them to existing AI Foundry project
- **FR-002**: System MUST deploy at minimum one GPT model (e.g., GPT-4.1)
- **FR-003**: System MUST deploy at minimum one image generation model (e.g., FLUX-1.1-pro)
- **FR-004**: System MUST output the Azure OpenAI endpoint URL upon successful deployment
- **FR-005**: System MUST output the API key for authentication (using key-based access, not managed identity)

**Configuration & Parameterization**
- **FR-006**: Users MUST be able to specify the deployment location (Azure region)
- **FR-007**: Users MUST be able to configure model names and capacity (TPM quotas)
- **FR-008**: System MUST support a single parameter file for deployment configuration (targeting one dev/personal environment)
- **FR-009**: System MUST use Azure naming conventions for deployed resources

**Deployment Process**
- **FR-010**: Users MUST be able to deploy via Azure CLI using `az deployment group create`
- **FR-011**: System MUST validate Bicep syntax before deployment
- **FR-012**: System MUST be idempotent (redeployment updates, doesn't recreate unnecessarily)
- **FR-013**: System MUST complete deployment within 10 minutes for initial provisioning
- **FR-013a**: System MUST fail immediately with a clear error message if model deployment exceeds TPM quota limits (no automatic retry)

**Migration & Cleanup**
- **FR-014**: System MUST provide clear instructions for archiving old Bicep files (to `infra-archive/` or similar) and deleting corresponding Azure resources (App Service, VNet, Static Web App, etc.)
- **FR-015**: Users MUST be able to delete all newly deployed OpenAI resources via resource group deletion
- **FR-016**: System MUST document that existing Azure AI Foundry resources remain unchanged and are linked to new OpenAI resources

**Documentation**
- **FR-017**: System MUST provide a simplified README with deployment steps
- **FR-018**: System MUST document how to retrieve outputs and configure `.env` file
- **FR-019**: System MUST explain the relationship between Bicep-deployed resources and Docker configuration

### Non-Functional Requirements

**Simplicity**
- **NFR-001**: Infrastructure MUST consist of a single Bicep file (no modules)
- **NFR-002**: Deployment process MUST require fewer than 5 commands
- **NFR-003**: Documentation MUST be readable by developers unfamiliar with Azure

**Maintainability**
- **NFR-004**: Bicep file MUST be under 300 lines of code
- **NFR-005**: Parameters MUST have clear descriptions and default values
- **NFR-006**: Changes to model deployments MUST not require changes to main Bicep structure

**Compatibility**
- **NFR-007**: Deployed resources MUST work with existing Docker Compose setup
- **NFR-008**: Configuration outputs MUST align with current `docker/litellm/config.yaml` format

### Key Entities

- **Azure OpenAI Service**: Cognitive Services resource providing GPT and image generation models. Attributes: endpoint URL, resource ID, location, SKU tier, API version support, linked AI Foundry project reference.
- **Azure AI Foundry Project**: Existing manually-created project that organizes AI resources. Attributes: project ID, resource group, subscription. Relationship: Parent container for OpenAI resources.
- **Model Deployment**: Specific model version deployed within OpenAI Service. Attributes: model name, model version, capacity (TPM), deployment name.
- **Deployment Parameters**: Configuration values for provisioning. Attributes: location, resource name prefix, model configurations, SKU tier, AI Foundry project reference.
- **Deployment Outputs**: Values returned after successful provisioning. Attributes: endpoint URL, API key, deployment names, API version.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs) - *Bicep is the required tool per user request*
- [x] Focused on user value and business needs - *Simplicity-first motivation*
- [x] Written for non-technical stakeholders - *DevOps persona clearly defined*
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain - **All 5 clarifications resolved**
- [x] Requirements are testable and unambiguous - *Verified via deployment validation*
- [x] Success criteria are measurable - *Deployment time, file count, command count*
- [x] Scope is clearly bounded - *Only OpenAI Service, no App Service/VNet/SWA*
- [x] Dependencies and assumptions identified - *Docker Compose, existing AI Foundry*

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (5 clarifications identified)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Clarifications resolved (5/5 answered via /clarify)
- [x] Review checklist passed

---

## Next Steps

1. ✓ ~~Run `/clarify` to resolve clarifications~~ - **Completed**
2. Run `/plan` to generate technical implementation approach (research, data model, contracts, quickstart)
3. Run `/tasks` to create dependency-ordered work items
4. Run `/implement` to execute migration from old infrastructure to minimal Bicep
