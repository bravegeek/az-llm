# Tasks: Azure Infrastructure as Code

**Input**: Design documents from `/home/greg/dev/az-llm/specs/002-azure-infrastructure-as/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/bicep-deployment.yaml

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Bicep, Azure CLI, Bash
   → Structure: Modular Bicep templates with main orchestrator
2. Load design documents:
   → data-model.md: 10 entities (VNet, OpenAI, App Service, Static Web App, etc.)
   → contracts/bicep-deployment.yaml: Deployment contract schema
   → research.md: Hybrid networking, managed identity, testing strategy
   → quickstart.md: 5 deployment scenarios
3. Generate tasks by category:
   → Setup: Project structure, dependencies, validation
   → Tests: Contract tests, deployment tests, policy tests
   → Core: Bicep modules for each resource type
   → Integration: Main orchestrator, role assignments
   → Polish: Parameter files, documentation, cleanup scripts
4. Apply TDD ordering:
   → Validation tests before Bicep templates
   → Linter tests before module creation
   → Contract tests before deployment scripts
5. Number tasks sequentially (T001-T034)
6. Mark parallel tasks [P] (different files, no dependencies)
7. SUCCESS: 34 tasks ready for execution
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Infrastructure project at repository root:
- `infra/` - Bicep templates and modules
- `tests/bicep/` - Infrastructure tests
- `tests/integration/` - End-to-end tests
- `.github/workflows/` - CI/CD pipelines (future)

---

## Phase 3.1: Setup

- [x] **T001** Create infrastructure project structure
  - Create directories: `infra/`, `infra/modules/`, `infra/parameters/`, `infra/scripts/`, `tests/bicep/`, `tests/integration/`
  - **Files affected**: Repository root
  - **Dependencies**: None

- [x] **T002** Install and verify Azure CLI and Bicep CLI
  - Verify Azure CLI version (≥2.50.0)
  - Verify Bicep CLI version (≥0.20.0)
  - Create version check script in `infra/scripts/check-prerequisites.sh`
  - **Files affected**: `infra/scripts/check-prerequisites.sh`
  - **Dependencies**: T001

- [x] **T003** [P] Create .gitignore for infrastructure artifacts
  - Ignore: `.azure/`, `*.bicepparam.json`, deployment logs
  - **Files affected**: `infra/.gitignore`
  - **Dependencies**: T001

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [x] **T004** [P] Bicep linter test in tests/bicep/linter.test.sh
  - Test validates all `.bicep` files in `infra/` pass `az bicep lint`
  - Exit code 1 if linting fails
  - Expected result: FAIL (no Bicep files exist yet)
  - **Files affected**: `tests/bicep/linter.test.sh`
  - **Dependencies**: T002

- [x] **T005** [P] Bicep build test in tests/bicep/build.test.sh
  - Test validates `infra/main.bicep` compiles without errors
  - Exit code 1 if build fails
  - Expected result: FAIL (main.bicep doesn't exist yet)
  - **Files affected**: `tests/bicep/build.test.sh`
  - **Dependencies**: T002

- [x] **T006** [P] Deployment parameter validation test in tests/bicep/parameter-validation.test.sh
  - Test validates parameter files against OpenAPI schema in `contracts/bicep-deployment.yaml`
  - Checks: required fields, enum values, format patterns
  - Expected result: FAIL (parameter files don't exist yet)
  - **Files affected**: `tests/bicep/parameter-validation.test.sh`
  - **Dependencies**: T002

- [x] **T007** [P] Azure Policy compliance test in tests/bicep/policy.test.sh
  - Test validates deployment meets security requirements (TLS 1.2, managed identity, encryption)
  - Uses `az deployment group validate` with policy checks
  - Expected result: FAIL (no templates exist yet)
  - **Files affected**: `tests/bicep/policy.test.sh`
  - **Dependencies**: T002

- [x] **T008** [P] Deployment validation test in tests/bicep/deployment.test.sh
  - Test validates `infra/main.bicep` can deploy successfully (what-if mode)
  - Validates all 3 environment parameter files (dev, staging, prod)
  - Expected result: FAIL (templates don't exist yet)
  - **Files affected**: `tests/bicep/deployment.test.sh`
  - **Dependencies**: T002

- [x] **T009** [P] Integration test for fresh deployment in tests/integration/fresh-deployment.test.sh
  - Test scenario: Deploy to empty resource group
  - Validates: All resources created, outputs present, managed identity configured
  - Uses quickstart.md Scenario 1 as reference
  - Expected result: FAIL (no deployment scripts exist yet)
  - **Files affected**: `tests/integration/fresh-deployment.test.sh`
  - **Dependencies**: T002

- [x] **T010** [P] Integration test for update deployment in tests/integration/update-deployment.test.sh
  - Test scenario: Update existing infrastructure (change OpenAI capacity)
  - Validates: Incremental update, no resource recreation, outputs updated
  - Uses quickstart.md Scenario 2 as reference
  - Expected result: FAIL (no deployment scripts exist yet)
  - **Files affected**: `tests/integration/update-deployment.test.sh`
  - **Dependencies**: T002

- [x] **T011** [P] Integration test for multi-environment deployment in tests/integration/multi-environment.test.sh
  - Test scenario: Deploy dev, staging, prod with same SKUs
  - Validates: Environment isolation, consistent configuration, correct tags
  - Uses quickstart.md Scenario 3 as reference
  - Expected result: FAIL (no deployment scripts exist yet)
  - **Files affected**: `tests/integration/multi-environment.test.sh`
  - **Dependencies**: T002

- [x] **T012** [P] Integration test for security validation in tests/integration/security-validation.test.sh
  - Test scenario: Verify managed identity, role assignments, no secrets
  - Validates: Hybrid networking (public OpenAI, VNet integration), no API keys in config
  - Uses quickstart.md Scenario 4 as reference
  - Expected result: FAIL (no infrastructure exists yet)
  - **Files affected**: `tests/integration/security-validation.test.sh`
  - **Dependencies**: T002

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Bicep Modules (Parallel - Different Files)

- [x] **T013** [P] Virtual Network module in infra/modules/vnet.bicep
  - Parameters: `vnetName`, `location`, `addressPrefix`, `tags`
  - Resources: Virtual Network, App Service integration subnet (delegated to Microsoft.Web/serverFarms)
  - Outputs: `vnetId`, `appServiceSubnetId`
  - Validates: Address space is valid CIDR, subnet delegation configured
  - **Files affected**: `infra/modules/vnet.bicep`
  - **Dependencies**: T004, T005 (tests failing)

- [x] **T014** [P] Azure OpenAI Service module in infra/modules/openai.bicep
  - Parameters: `openAiName`, `location`, `sku`, `modelDeployments`, `tags`
  - Resources: Cognitive Services account (kind: OpenAI), 3 model deployments (GPT-4o, GPT-3.5-turbo, DALL-E 3)
  - Properties: `publicNetworkAccess: 'Enabled'` (hybrid networking)
  - Outputs: `openAiEndpoint`, `openAiResourceId`, `openAiName`
  - Validates: Exactly 3 model deployments, public access enabled
  - **Files affected**: `infra/modules/openai.bicep`
  - **Dependencies**: T004, T005 (tests failing)

- [x] **T015** [P] App Service module in infra/modules/appservice.bicep
  - Parameters: `appServiceName`, `location`, `sku`, `vnetSubnetId`, `tags`
  - Resources: App Service Plan, App Service with system-assigned managed identity
  - Properties: VNet integration, HTTPS only, TLS 1.2 minimum
  - Outputs: `appServiceName`, `appServicePrincipalId`, `appServiceId`
  - Validates: Managed identity enabled, VNet integration configured
  - **Files affected**: `infra/modules/appservice.bicep`
  - **Dependencies**: T004, T005 (tests failing)

- [x] **T016** [P] Static Web App module in infra/modules/staticwebapp.bicep
  - Parameters: `swaName`, `location`, `sku`, `tags`
  - Resources: Static Web App (public, no VNet integration)
  - Outputs: `swaUrl`, `swaName`
  - Validates: SKU is Standard (Free not suitable for production)
  - **Files affected**: `infra/modules/staticwebapp.bicep`
  - **Dependencies**: T004, T005 (tests failing)

- [x] **T017** [P] Application Insights module in infra/modules/monitoring.bicep
  - Parameters: `appInsightsName`, `location`, `retentionInDays`, `tags`
  - Resources: Log Analytics Workspace, Application Insights (workspace-based)
  - Outputs: `appInsightsConnectionString`, `appInsightsInstrumentationKey`, `workspaceId`
  - Validates: Workspace-based mode, retention period is valid Azure value
  - **Files affected**: `infra/modules/monitoring.bicep`
  - **Dependencies**: T004, T005 (tests failing)

### Main Orchestrator (Sequential - Depends on Modules)

- [x] **T018** Main orchestration template in infra/main.bicep
  - Parameters: `environment`, `location`, `projectName`, `appServiceSku`, `openAiModels`, `tags`
  - Modules: vnet, openai, appservice, staticwebapp, monitoring (with dependencies)
  - Resource: Role assignment (App Service managed identity → OpenAI "Cognitive Services OpenAI User")
  - Outputs: All outputs from modules (7 required outputs per contract)
  - Validates: Dependency ordering (VNet before App Service, OpenAI before role assignment)
  - **Files affected**: `infra/main.bicep`
  - **Dependencies**: T013, T014, T015, T016, T017

### Deployment Scripts

- [x] **T019** Deployment orchestration script in infra/scripts/deploy.sh
  - Accepts: `--environment <dev|staging|prod>` flag
  - Steps: Validate parameters, run linter, create resource group, deploy template
  - Error handling: Check deployment status, display errors, exit with code 1 on failure
  - **Files affected**: `infra/scripts/deploy.sh`
  - **Dependencies**: T018

- [x] **T020** Deployment validation script in infra/scripts/validate.sh
  - Accepts: `--environment <dev|staging|prod>` flag
  - Steps: Run linter, validate parameters, run what-if deployment
  - Output: Display changes (create/modify/delete resources)
  - **Files affected**: `infra/scripts/validate.sh`
  - **Dependencies**: T018

---

## Phase 3.4: Integration (Configuration Files)

### Environment Parameter Files (Parallel - Different Files)

- [x] **T021** [P] Development environment parameters in infra/parameters/dev.bicepparam
  - Using syntax: `using '../main.bicep'`
  - Parameters: `environment: 'dev'`, `location: 'eastus'`, `projectName: 'az-llm'`, `appServiceSku: { name: 'B1', tier: 'Basic' }`
  - OpenAI models: GPT-4o (10 TPM), GPT-3.5-turbo (10 TPM), DALL-E 3 (1 TPM)
  - Tags: `{ Environment: 'dev', Project: 'az-llm' }`
  - **Files affected**: `infra/parameters/dev.bicepparam`
  - **Dependencies**: T018

- [x] **T022** [P] Staging environment parameters in infra/parameters/staging.bicepparam
  - Same structure as dev.bicepparam with `environment: 'staging'`
  - Same SKUs (per clarification: consistent across environments)
  - **Files affected**: `infra/parameters/staging.bicepparam`
  - **Dependencies**: T018

- [x] **T023** [P] Production environment parameters in infra/parameters/prod.bicepparam
  - Same structure as dev.bicepparam with `environment: 'prod'`
  - Same SKUs (per clarification: consistent across environments)
  - **Files affected**: `infra/parameters/prod.bicepparam`
  - **Dependencies**: T018

### Test Runner

- [x] **T024** Test runner script in tests/run-all-tests.sh
  - Runs all tests in sequence: linter → build → parameter validation → policy → deployment
  - Displays pass/fail for each test
  - Exit code: 0 if all pass, 1 if any fail
  - **Files affected**: `tests/run-all-tests.sh`
  - **Dependencies**: T004, T005, T006, T007, T008

---

## Phase 3.5: Polish

### Verification Scripts

- [ ] **T025** [P] Post-deployment verification script in infra/scripts/verify-deployment.sh
  - Accepts: `--environment <dev|staging|prod>` flag
  - Checks: All resources exist, outputs are populated, managed identity configured, role assignment present
  - Output: Checklist of validation results (✅/❌)
  - **Files affected**: `infra/scripts/verify-deployment.sh`
  - **Dependencies**: T019

- [ ] **T026** [P] Security validation script in infra/scripts/verify-security.sh
  - Accepts: `--environment <dev|staging|prod>` flag
  - Checks: Managed identity, role assignments, hybrid networking (public OpenAI, VNet integration), TLS settings, no secrets in config
  - Output: Security compliance report
  - **Files affected**: `infra/scripts/verify-security.sh`
  - **Dependencies**: T019

- [ ] **T027** [P] Cleanup script in infra/scripts/cleanup.sh
  - Accepts: `--environment <dev|staging|prod>` flag
  - Steps: Confirm deletion, delete resource group, verify deletion
  - Safety: Requires confirmation prompt (prevent accidental deletion)
  - **Files affected**: `infra/scripts/cleanup.sh`
  - **Dependencies**: T001

### Documentation

- [ ] **T028** [P] Update README with infrastructure setup instructions
  - Sections: Prerequisites, Quick Start, Deployment, Verification
  - Reference quickstart.md for detailed scenarios
  - Include: Azure CLI installation, Bicep installation, authentication
  - **Files affected**: `infra/README.md` (create new)
  - **Dependencies**: T019, T020

- [ ] **T029** [P] Create deployment troubleshooting guide
  - Common errors: Quota exceeded, name conflicts, subnet conflicts, permissions
  - Reference quickstart.md Scenario 5 (failure handling)
  - Include debugging steps and solutions
  - **Files affected**: `infra/TROUBLESHOOTING.md` (create new)
  - **Dependencies**: T019

### Final Validation

- [ ] **T030** Run all tests and verify they pass
  - Execute: `tests/run-all-tests.sh`
  - Expected: All tests pass (linter, build, parameter validation, policy, deployment validation)
  - Fix any failures before proceeding
  - **Files affected**: None (validation only)
  - **Dependencies**: T013-T023, T024

- [ ] **T031** Perform fresh deployment to dev environment
  - Execute: `infra/scripts/deploy.sh --environment dev`
  - Verify: All resources created, outputs populated, no errors
  - Run: `infra/scripts/verify-deployment.sh --environment dev`
  - **Files affected**: None (deployment only)
  - **Dependencies**: T019, T021, T030

- [ ] **T032** Perform security validation on dev deployment
  - Execute: `infra/scripts/verify-security.sh --environment dev`
  - Verify: All security checks pass (managed identity, role assignment, hybrid networking, no secrets)
  - **Files affected**: None (validation only)
  - **Dependencies**: T031, T026

- [ ] **T033** Test update deployment scenario
  - Modify: `infra/parameters/dev.bicepparam` (change GPT-4o capacity from 10 to 20)
  - Execute: `infra/scripts/validate.sh --environment dev` (what-if preview)
  - Execute: `infra/scripts/deploy.sh --environment dev` (apply update)
  - Verify: Only OpenAI resource updated, no recreation
  - Revert: Change capacity back to 10
  - **Files affected**: None (test scenario only)
  - **Dependencies**: T031

- [ ] **T034** Execute quickstart.md scenarios and verify all pass
  - Run all 5 scenarios: Fresh deployment, Update, Multi-environment, Security, Failure handling
  - Verify: All success criteria met
  - Document: Any deviations or improvements needed
  - **Files affected**: None (validation only)
  - **Dependencies**: T031, T032, T033

---

## Dependencies

### Setup Dependencies
- T002 depends on T001 (project structure)
- T003 depends on T001 (project structure)

### Test Dependencies (TDD Gate)
- T004-T012 depend on T002 (Azure CLI/Bicep installed)
- All tests must FAIL before proceeding to T013

### Implementation Dependencies
- T013-T017 depend on T004, T005 (linter and build tests failing)
- T018 depends on T013, T014, T015, T016, T017 (all modules complete)
- T019, T020 depend on T018 (main template)

### Integration Dependencies
- T021-T023 depend on T018 (main template defines parameters)
- T024 depends on T004-T008 (all tests exist)

### Polish Dependencies
- T025, T026 depend on T019 (deployment script)
- T027 depends on T001 (project structure)
- T028, T029 depend on T019, T020 (deployment scripts)
- T030 depends on T013-T023, T024 (all code and test runner)
- T031 depends on T019, T021, T030 (deployment script, dev params, passing tests)
- T032 depends on T031, T026 (deployment complete, security script)
- T033 depends on T031 (initial deployment)
- T034 depends on T031, T032, T033 (all validation complete)

---

## Parallel Execution Examples

### Phase 3.1 Setup (After T002)
```bash
# T003 can run independently
./create-gitignore.sh
```

### Phase 3.2 Test Creation (After T002)
```bash
# Launch T004-T012 together (all write to different files):
# T004: tests/bicep/linter.test.sh
# T005: tests/bicep/build.test.sh
# T006: tests/bicep/parameter-validation.test.sh
# T007: tests/bicep/policy.test.sh
# T008: tests/bicep/deployment.test.sh
# T009: tests/integration/fresh-deployment.test.sh
# T010: tests/integration/update-deployment.test.sh
# T011: tests/integration/multi-environment.test.sh
# T012: tests/integration/security-validation.test.sh
```

### Phase 3.3 Module Creation (After T004, T005 failing)
```bash
# Launch T013-T017 together (all different modules):
# T013: infra/modules/vnet.bicep
# T014: infra/modules/openai.bicep
# T015: infra/modules/appservice.bicep
# T016: infra/modules/staticwebapp.bicep
# T017: infra/modules/monitoring.bicep
```

### Phase 3.4 Parameter Files (After T018)
```bash
# Launch T021-T023 together (all different parameter files):
# T021: infra/parameters/dev.bicepparam
# T022: infra/parameters/staging.bicepparam
# T023: infra/parameters/prod.bicepparam
```

### Phase 3.5 Documentation (After T019, T020)
```bash
# Launch T025-T029 together (all different files):
# T025: infra/scripts/verify-deployment.sh
# T026: infra/scripts/verify-security.sh
# T027: infra/scripts/cleanup.sh
# T028: infra/README.md
# T029: infra/TROUBLESHOOTING.md
```

---

## Notes

- **[P] tasks** = Different files, no dependencies, can run in parallel
- **TDD enforcement**: All tests (T004-T012) must fail before writing implementation (T013+)
- **Constitutional compliance**: Follows Test-First Development (tests before code)
- **Hybrid networking**: Public OpenAI with managed identity auth, App Service with VNet integration
- **No secrets**: All authentication via managed identity (no keys in config)
- **Commit frequency**: Commit after completing each task
- **Avoid**: Vague tasks, same file conflicts in parallel tasks

---

## Validation Checklist
*GATE: Verify before marking Phase 3 complete*

- [x] All contracts have corresponding tests (T006: parameter validation, T008: deployment validation)
- [x] All entities have module tasks (T013-T017: VNet, OpenAI, App Service, Static Web App, Monitoring)
- [x] All tests come before implementation (Phase 3.2 before Phase 3.3)
- [x] Parallel tasks are independent (verified: different files, no shared state)
- [x] Each task specifies exact file path (all tasks include `Files affected` field)
- [x] No [P] task modifies same file as another [P] task (verified: unique file paths)
- [x] Quickstart scenarios mapped to integration tests (T009-T012 cover all 5 scenarios)
- [x] TDD ordering enforced (Tests Phase 3.2 must complete before Core Phase 3.3)

---

*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
