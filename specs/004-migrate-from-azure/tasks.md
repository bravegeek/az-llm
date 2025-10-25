# Tasks: Azure AI Foundry Hub-less Migration

**Feature**: 004-migrate-from-azure
**Input**: Design documents from `/home/greg/dev/az-llm/specs/004-migrate-from-azure/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅
**Branch**: `004-migrate-from-azure`
**Constitution**: v1.0.0

## Execution Summary

This task list implements migration from Azure OpenAI to Azure AI Foundry **hub-less** architecture with **3 standard model deployments** (gpt-4, gpt-4o-mini, gpt-4o) via Bicep. **FLUX-1.1-pro and DeepSeek-V3.1** are serverless models requiring manual deployment via AI Foundry portal (documented, not automated). Total: **200K TPM** via Bicep (not 260K), single-file infrastructure (<300 lines), comprehensive test suite with TDD approach.

## Critical Design Changes from Initial Spec
- **Hub-less architecture**: AIServices account (kind=AIServices) + Project (not Hub + Project)
- **3 models in Bicep** (not 5): gpt-4, gpt-4o-mini, gpt-4o
- **2 serverless models manual**: FLUX-1.1-pro, DeepSeek-V3.1 (documented in README, not deployed via Bicep)
- **Total TPM**: 200K (50+100+50), not 260K
- **Parameters**: 13 parameters (not 19)

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- Tests MUST be written before implementation (TDD)

## Phase 3.1: Setup
- [X] T001 Archive existing Azure OpenAI infrastructure to infra-archive/2025-10-20-azure-openai/
- [X] T002 Create contracts directory structure at specs/004-migrate-from-azure/contracts/
- [X] T003 [P] Install ajv-cli for JSON Schema validation (npm install -g ajv-cli)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests (Different schemas = parallel)
- [X] T004 [P] Contract input test: tests/bicep/contract-input.test.sh validates infra/main.parameters.json against specs/004-migrate-from-azure/contracts/input-schema.json
- [X] T005 [P] Contract output test: tests/bicep/contract-output.test.sh validates deployment outputs against specs/004-migrate-from-azure/contracts/output-schema.json

### Infrastructure Tests (Different validation aspects = parallel)
- [X] T006 [P] Bicep linter test: tests/bicep/linter.test.sh runs az bicep build --file infra/main.bicep for syntax validation
- [X] T007 [P] Bicep build test: tests/bicep/build.test.sh compiles infra/main.bicep to ARM template and validates JSON structure
- [X] T008 [P] Parameter validation test: tests/bicep/parameter-validation.test.sh validates all required parameters exist in main.parameters.json

### Integration Tests (Different quickstart scenarios = parallel stubs)
- [X] T009 [P] Quickstart scenario 1 stub: tests/bicep/quickstart-scenario-1.test.sh (deploy fresh AI Foundry project)
- [X] T010 [P] Quickstart scenario 2 stub: tests/bicep/quickstart-scenario-2.test.sh (validate 3 models with correct TPM)
- [X] T011 [P] Quickstart scenario 3 stub: tests/bicep/quickstart-scenario-3.test.sh (extract outputs to .env format)
- [X] T012 [P] Quickstart scenario 4 stub: tests/bicep/quickstart-scenario-4.test.sh (test model endpoint connectivity)
- [X] T013 [P] Quickstart scenario 5 stub: tests/bicep/quickstart-scenario-5.test.sh (validate model availability in region)
- [X] T014 [P] Quickstart scenario 6 stub: tests/bicep/quickstart-scenario-6.test.sh (fail with non-empty resource group)

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Bicep Infrastructure (Single file, sequential)
- [X] T015 Create AI Foundry AIServices account resource in infra/main.bicep (Microsoft.CognitiveServices/accounts@2025-06-01, kind: AIServices, allowProjectManagement: true)
- [X] T016 Add AI Foundry Project child resource in infra/main.bicep (Microsoft.CognitiveServices/accounts/projects@2025-06-01)
- [X] T017 Add GPT-4 deployment resource in infra/main.bicep (50K TPM, version 1106-preview)
- [X] T018 Add GPT-4o-mini deployment resource in infra/main.bicep (100K TPM, version 2025-04-14, DataZoneStandard SKU)
- [X] T019 Add GPT-4o deployment resource in infra/main.bicep (50K TPM, version 2024-08-06)
- [X] T020 Add output definitions in infra/main.bicep (aiServicesResourceId, projectResourceId, endpoints, deployment details for 3 models + serverless placeholders)

### Parameters File
- [X] T021 Create infra/main.parameters.json with 13 parameters (location, aiServicesName, customSubDomain, projectName, 3× model configs)

### Deployment Scripts (Different scripts = parallel)
- [X] T022 [P] Validation script: scripts/validate.sh (region check, 3 model availability check, quota validation for 200K TPM, clean RG check)
- [X] T023 [P] Deployment script: scripts/deploy.sh (validate → deploy → verify provisioningState)
- [X] T024 [P] Outputs extraction script: scripts/outputs.sh (extract deployment outputs → .env.azure-foundry format with serverless placeholders)

## Phase 3.4: Integration (Implement test scenarios sequentially)

### Quickstart Scenario Implementation
- [X] T025 Implement quickstart scenario 1: tests/bicep/quickstart-scenario-1.test.sh (full deployment validation - AIServices + Project + 3 models)
- [X] T026 Implement quickstart scenario 2: tests/bicep/quickstart-scenario-2.test.sh (validate 3 models deployed, verify TPM=200K total)
- [X] T027 Implement quickstart scenario 3: tests/bicep/quickstart-scenario-3.test.sh (validate .env.azure-foundry schema compliance)
- [X] T028 Implement quickstart scenario 4: tests/bicep/quickstart-scenario-4.test.sh (curl test 3 standard model endpoints)
- [X] T029 Implement quickstart scenario 5: tests/bicep/quickstart-scenario-5.test.sh (az cognitiveservices model list validation for 3 models)
- [X] T030 Implement quickstart scenario 6: tests/bicep/quickstart-scenario-6.test.sh (negative test: non-empty RG fails validation)

### Test Runner
- [X] T031 Create tests/bicep/run-all-tests.sh orchestrator (runs T004-T014, T025-T030 in sequence with reporting)

## Phase 3.5: Polish

### Documentation (Different files = parallel)
- [X] T032 [P] Create infra/README.md deployment guide (prerequisites, usage, troubleshooting, **serverless model manual deployment instructions for FLUX and DeepSeek**)
- [X] T033 [P] Create MIGRATION.md guide (Azure OpenAI → AI Foundry hub-less migration steps, breaking changes, serverless model manual deployment)
- [X] T034 [P] Update root README.md with AI Foundry hub-less architecture section and deployment links

### Validation & Cleanup
- [X] T035 Verify all tests pass: bash tests/bicep/run-all-tests.sh
- [X] T036 Verify Bicep file <300 lines: wc -l infra/main.bicep
- [X] T037 Run constitutional compliance check against .specify/memory/constitution.md (verify Simplicity-First, TDD, Azure-native, Clear Contracts, Observability)
- [X] T038 [P] Update CLAUDE.md agent context: .specify/scripts/bash/update-agent-context.sh claude

## Dependencies

### Hard Dependencies (Sequential)
```
T001 → T002 → T003 → [All Tests T004-T014]
[All Tests T004-T014] → T015
T015 → T016 → T017 → T018 → T019 → T020
T020 → T021
T021 + T020 → T022, T023, T024
T022, T023, T024 → T025 → T026 → T027 → T028 → T029 → T030
T030 → T031
T031 → T032, T033, T034
T032, T033, T034 → T035 → T036 → T037 → T038
```

### Parallel Blocks
```
Block 1 (Contract Tests): T004, T005
Block 2 (Infrastructure Tests): T006, T007, T008
Block 3 (Test Stubs): T009, T010, T011, T012, T013, T014
Block 4 (Scripts): T022, T023, T024
Block 5 (Docs): T032, T033, T034
```

## Parallel Execution Example

### Test Stub Creation (Block 3)
```bash
# Launch T009-T014 together (6 parallel tasks):
Task: "Create quickstart-scenario-1.test.sh stub"
Task: "Create quickstart-scenario-2.test.sh stub"
Task: "Create quickstart-scenario-3.test.sh stub"
Task: "Create quickstart-scenario-4.test.sh stub"
Task: "Create quickstart-scenario-5.test.sh stub"
Task: "Create quickstart-scenario-6.test.sh stub"
```

### Deployment Scripts (Block 4)
```bash
# Launch T022-T024 together (3 parallel tasks):
Task: "Create scripts/validate.sh with region/model/quota checks for 3 models"
Task: "Create scripts/deploy.sh with deployment automation"
Task: "Create scripts/outputs.sh with .env extraction including serverless placeholders"
```

### Documentation (Block 5)
```bash
# Launch T032-T034 together (3 parallel tasks):
Task: "Create infra/README.md deployment guide with serverless instructions"
Task: "Create MIGRATION.md migration guide"
Task: "Update root README.md with AI Foundry hub-less section"
```

## File Change Matrix

| File Path | Tasks | Parallel? |
|-----------|-------|-----------|
| infra/main.bicep | T015-T020 | No (sequential edits to same file) |
| infra/main.parameters.json | T021 | No (single task) |
| scripts/validate.sh | T022 | Yes [P] with T023, T024 |
| scripts/deploy.sh | T023 | Yes [P] with T022, T024 |
| scripts/outputs.sh | T024 | Yes [P] with T022, T023 |
| tests/bicep/contract-input.test.sh | T004 | Yes [P] with T005 |
| tests/bicep/contract-output.test.sh | T005 | Yes [P] with T004 |
| tests/bicep/linter.test.sh | T006 | Yes [P] with T007, T008 |
| tests/bicep/build.test.sh | T007 | Yes [P] with T006, T008 |
| tests/bicep/parameter-validation.test.sh | T008 | Yes [P] with T006, T007 |
| tests/bicep/quickstart-scenario-1.test.sh | T009 (stub), T025 (impl) | T009 [P], T025 sequential |
| tests/bicep/quickstart-scenario-2.test.sh | T010 (stub), T026 (impl) | T010 [P], T026 sequential |
| tests/bicep/quickstart-scenario-3.test.sh | T011 (stub), T027 (impl) | T011 [P], T027 sequential |
| tests/bicep/quickstart-scenario-4.test.sh | T012 (stub), T028 (impl) | T012 [P], T028 sequential |
| tests/bicep/quickstart-scenario-5.test.sh | T013 (stub), T029 (impl) | T013 [P], T029 sequential |
| tests/bicep/quickstart-scenario-6.test.sh | T014 (stub), T030 (impl) | T014 [P], T030 sequential |
| tests/bicep/run-all-tests.sh | T031 | No (single task) |
| infra/README.md | T032 | Yes [P] with T033, T034 |
| MIGRATION.md | T033 | Yes [P] with T032, T034 |
| README.md | T034 | Yes [P] with T032, T033 |

## TDD Validation Gates

### Gate 1: Tests Must Fail (After T004-T014)
```bash
# Run all tests - expect failures
bash tests/bicep/run-all-tests.sh
# Expected: All tests fail (no Bicep infrastructure exists yet)
```

### Gate 2: Contract Tests Pass (After T020-T021)
```bash
# Run contract tests only
bash tests/bicep/contract-input.test.sh
bash tests/bicep/contract-output.test.sh
# Expected: Input test passes, output test may fail (deployment needed)
```

### Gate 3: All Tests Pass (After T030)
```bash
# Run full test suite
bash tests/bicep/run-all-tests.sh
# Expected: All 14 tests pass (2 contract + 3 infra + 6 integration + test runner)
```

## Constitutional Compliance Tracking

| Principle | Tasks | Validation |
|-----------|-------|------------|
| **Simplicity-First** | T015-T020 (single Bicep, hub-less), T036 (<300 lines) | wc -l infra/main.bicep |
| **Test-First Development** | T004-T014 before T015 (TDD gate) | Verify tests fail at T014, pass at T030 |
| **Azure-Native Integration** | T015-T020 (Bicep resources), T022-T024 (az cli) | No external dependencies |
| **Clear Contracts** | T004-T005 (JSON Schema validation) | ajv validate passes |
| **Observability** | T023 (deployment logs), T031 (test reporting) | Structured output in scripts |

## Notes

### Hub-less Architecture (Critical Change)
- **NO Hub resource**: Uses AIServices account (Microsoft.CognitiveServices/accounts) with `kind: 'AIServices'`
- **AIServices properties**: `allowProjectManagement: true`, `customSubDomainName` required
- **Project**: Child resource of AIServices (not Hub)
- **Simpler than hub-based**: 2 resources instead of 3 (Hub + Project + AIServices → AIServices + Project)

### Serverless Model Handling
- **FLUX-1.1-pro** and **DeepSeek-V3.1** **NOT** deployed via Bicep (serverless models)
- T032 (infra/README.md) documents manual deployment via AI Foundry portal
- Output schema includes placeholders with `deploymentStatus: manual-required`
- T033 (MIGRATION.md) provides step-by-step manual deployment instructions

### Bicep Development Strategy
- T015-T020 are sequential (same file edits)
- Develop incrementally: AIServices → Project → Deployments → Outputs
- Test after each resource addition using T006-T007

### Test Stub vs Implementation
- T009-T014: Create test stubs that fail gracefully (exit 1 with "NOT IMPLEMENTED")
- T025-T030: Implement actual test logic using quickstart.md scenarios
- Allows TDD gate validation without blocking subsequent tasks

### Quota Requirements
- **Total TPM**: 200K (50K gpt-4 + 100K gpt-4o-mini + 50K gpt-4o)
- **NOT 260K**: Serverless models don't use TPM
- Region: eastus2 (default, configurable)
- Validate quota in T022 (scripts/validate.sh)

### Model Versions (from data-model.md)
- **gpt-4**: version `1106-preview`, 50K TPM, Standard SKU
- **gpt-4o-mini**: version `2025-04-14`, 100K TPM, DataZoneStandard SKU
- **gpt-4o**: version `2024-08-06`, 50K TPM, Standard SKU

## Estimated Completion Time

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| 3.1 Setup | T001-T003 | 15 minutes |
| 3.2 Tests First | T004-T014 | 1.5 hours (14 test files) |
| 3.3 Core Implementation | T015-T024 | 2 hours (Bicep + scripts) |
| 3.4 Integration | T025-T031 | 1.5 hours (6 scenarios + runner) |
| 3.5 Polish | T032-T038 | 1 hour (docs + validation) |
| **Total** | **38 tasks** | **~6.5 hours** |

## Success Criteria

- [ ] All 38 tasks completed
- [ ] All tests pass (bash tests/bicep/run-all-tests.sh)
- [ ] Bicep file <300 lines
- [ ] **3 models deployed via Bicep** (200K TPM total, not 5 models/260K TPM)
- [ ] **Serverless models documented** (FLUX, DeepSeek) in README with manual deployment instructions
- [ ] Contract validation passes (input + output schemas v2.0.0)
- [ ] 6 quickstart scenarios validated
- [ ] Constitutional compliance confirmed (all 5 principles)
- [ ] CLAUDE.md updated with hub-less AI Foundry infrastructure

## Validation Checklist
*GATE: Checked before task execution begins*

- [x] All contracts have corresponding tests (T004 input, T005 output)
- [x] All entities have implementation tasks (AIServices=T015, Project=T016, 3 Deployments=T017-T019, Outputs=T020)
- [x] All tests come before implementation (T004-T014 before T015-T024)
- [x] Parallel tasks truly independent (different files, verified in File Change Matrix)
- [x] Each task specifies exact file path (all tasks include file paths)
- [x] No task modifies same file as another [P] task (verified - only infra/main.bicep is sequential)
- [x] TDD ordering enforced (Phase 3.2 before 3.3)
- [x] Constitutional compliance maintained (hub-less = simpler, single file <300 lines, tests first, Azure-native)

---

**Status**: Ready for implementation
**Next**: Execute tasks in order, starting with T001
**Constitutional Compliance**: ✅ Simplicity-First (hub-less), ✅ Test-First Development, ✅ Azure-Native Integration, ✅ Clear Contracts, ✅ Observability

**Generated**: 2025-10-20 via `/tasks` command
**Based on Constitution v1.0.0** - See `.specify/memory/constitution.md`
