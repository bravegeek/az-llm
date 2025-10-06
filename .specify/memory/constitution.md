<!--
Sync Impact Report - Constitution Update
Version: 1.0.0 (Initial Creation)
Date: 2025-10-05

Changes:
- Initial constitution created for az-llm project
- Established 5 core principles: Simplicity-First, Test-First Development, Azure-Native Integration, Clear Contracts, Observability
- Defined governance structure and amendment process
- Set up template compliance framework

Template Status:
✅ plan-template.md - References constitution check (line 14)
✅ spec-template.md - No constitutional constraints needed
✅ tasks-template.md - Aligns with TDD principle
✅ agent-file-template.md - No updates needed

Follow-up Items:
- None - All placeholders resolved
-->

# az-llm Project Constitution

## Core Principles

### I. Simplicity-First

Every solution MUST start with the simplest approach that satisfies requirements. Complexity requires explicit justification documented in plan.md Complexity Tracking.

**Rules**:
- Default to built-in language features before libraries
- Avoid abstractions (repositories, factories, builders) unless handling 3+ implementations
- Choose boring, proven technologies over novel ones
- Each new dependency must justify its inclusion

**Rationale**: Simple systems are easier to understand, debug, and maintain. Most complexity is premature optimization.

### II. Test-First Development (NON-NEGOTIABLE)

Test-Driven Development is mandatory. Tests MUST be written and MUST fail before implementation begins.

**Rules**:
- Tests written → User approved → Tests fail → Then implement
- Red-Green-Refactor cycle strictly enforced
- Contract tests for all API boundaries
- Integration tests for all user scenarios
- No code merged without passing tests

**Rationale**: Tests define requirements, prevent regressions, and enable confident refactoring. Writing tests first ensures testable design.

### III. Azure-Native Integration

Azure services MUST be used for infrastructure when available. Prefer managed services over self-hosted.

**Rules**:
- Use Azure SDK for JavaScript/TypeScript for all Azure interactions
- Leverage Azure CLI and Bicep for infrastructure as code
- Use managed identity for authentication (avoid keys/secrets in code)
- Default to Azure-native logging (Application Insights) and monitoring
- Document any non-Azure dependencies with rationale

**Rationale**: Azure-native services reduce operational burden, provide better integration, and align with cloud-first best practices.

### IV. Clear Contracts

All integration points MUST have explicit, versioned contracts defined before implementation.

**Rules**:
- API contracts use OpenAPI 3.0+ specification
- Data models documented in data-model.md with validation rules
- Breaking changes require MAJOR version bump
- All contracts include examples and test fixtures
- Contract changes trigger affected integration test updates

**Rationale**: Clear contracts enable parallel development, prevent integration issues, and make breaking changes visible.

### V. Observability

All production code MUST be observable through structured logging, metrics, and tracing.

**Rules**:
- Structured JSON logging for all significant events
- Include correlation IDs for request tracing
- Log inputs/outputs at integration boundaries
- Expose health check endpoints
- Monitor and alert on error rates and latency

**Rationale**: Observable systems enable rapid debugging, performance analysis, and proactive incident response.

## Development Workflow

**Planning Phase** (`/plan` command):
- All new features start with specification in spec.md
- Technical planning produces research.md, data-model.md, contracts/, and quickstart.md
- Constitution compliance checked before and after design phase

**Task Generation** (`/tasks` command):
- Tasks generated from design artifacts following TDD ordering
- Parallel tasks marked with [P] for independent execution
- Dependencies explicitly tracked

**Implementation** (`/implement` command):
- Execute tasks.md in dependency order
- Tests before implementation (Phase 3.2 before 3.3)
- Commit after each completed task

## Quality Gates

**Pre-Design Gate**:
- [ ] Specification contains no implementation details
- [ ] All requirements are testable
- [ ] User scenarios defined with acceptance criteria

**Post-Design Gate**:
- [ ] All contracts have OpenAPI specifications
- [ ] Data model documented with validation rules
- [ ] Contract tests written (failing)
- [ ] Constitution violations documented in Complexity Tracking

**Pre-Merge Gate**:
- [ ] All tests passing
- [ ] No linting errors
- [ ] Quickstart scenarios validated
- [ ] Changes comply with constitution or violations justified

## Governance

**Amendment Process**:
1. Propose change in writing with rationale
2. Document impact on existing code and templates
3. Update constitution.md with version bump
4. Update affected templates (plan, spec, tasks)
5. Create migration plan for existing violations

**Version Semantics**:
- **MAJOR**: Backward-incompatible principle removal or redefinition
- **MINOR**: New principle added or materially expanded guidance
- **PATCH**: Clarifications, wording improvements, typo fixes

**Compliance**:
- All PRs and reviews MUST verify constitutional compliance
- Complexity deviations MUST be justified in plan.md Complexity Tracking
- Template updates MUST reference constitution version they implement
- Quarterly constitutional review to identify systemic violations

**Runtime Guidance**:
Agent-specific development guidance is maintained separately (e.g., CLAUDE.md, .github/copilot-instructions.md) and MUST align with these principles.

**Version**: 1.0.0 | **Ratified**: 2025-10-05 | **Last Amended**: 2025-10-05
