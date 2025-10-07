# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an **az-llm** project using the **Specify Framework** - a structured software development workflow that guides features from specification through implementation using slash commands and constitutional principles.

The framework enforces:
- **Test-Driven Development (TDD)** as a non-negotiable requirement
- **Azure-native integration** for all infrastructure
- **Simplicity-first** approach to architecture
- **Clear contracts** with versioned APIs
- **Observability** through structured logging and monitoring

## Development Workflow

### Feature Development Lifecycle

All features follow a strict phase-based workflow:

1. **`/specify <description>`** - Create feature specification from natural language
   - Generates `specs/###-feature-name/spec.md`
   - Creates and checks out feature branch `###-feature-name`
   - Focus on WHAT and WHY, not HOW

2. **`/clarify`** - Resolve ambiguities (MUST run before `/plan`)
   - Interactive Q&A to reduce underspecified areas
   - Max 5 targeted questions per session
   - Updates spec.md with clarifications

3. **`/plan`** - Generate technical implementation plan
   - Produces research.md, data-model.md, contracts/, quickstart.md
   - Validates against constitution principles
   - Stops before task generation

4. **`/tasks`** - Generate dependency-ordered task list
   - Creates tasks.md from design artifacts
   - Marks parallel tasks with [P]
   - Follows TDD ordering (tests before implementation)

5. **`/analyze`** - Verify cross-artifact consistency (optional)
   - Non-destructive analysis of spec, plan, tasks
   - Identifies gaps, duplications, constitutional violations
   - Run after `/tasks`, before `/implement`

6. **`/implement`** - Execute the implementation
   - Follows tasks.md in dependency order
   - Tests written before code (Phase 3.2 before 3.3)
   - Marks tasks as [X] when complete

### Constitution (v1.0.0)

Located at `.specify/memory/constitution.md`. Five core principles:

1. **Simplicity-First** - Start simple, complexity requires justification
2. **Test-First Development** - TDD is mandatory (Red-Green-Refactor)
3. **Azure-Native Integration** - Use Azure SDK, managed services, managed identity
4. **Clear Contracts** - OpenAPI 3.0+ specs, versioned, with examples
5. **Observability** - Structured JSON logging, correlation IDs, health checks

## Project Structure

### Specification Framework
```
.specify/
├── memory/
│   └── constitution.md           # Project principles and governance
├── templates/                     # Templates for spec, plan, tasks
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   └── agent-file-template.md
└── scripts/bash/                  # Workflow automation
    ├── create-new-feature.sh     # /specify command
    ├── setup-plan.sh             # /plan command
    ├── check-prerequisites.sh    # Validates feature state
    └── update-agent-context.sh   # Updates this file

.claude/commands/                  # Slash command definitions
├── specify.md
├── clarify.md
├── plan.md
├── tasks.md
├── analyze.md
└── implement.md
```

### Feature Artifacts
```
specs/###-feature-name/
├── spec.md              # What to build (from /specify)
├── research.md          # Technical research (from /plan Phase 0)
├── data-model.md        # Entities & relationships (from /plan Phase 1)
├── quickstart.md        # Integration scenarios (from /plan Phase 1)
├── contracts/           # OpenAPI specs (from /plan Phase 1)
│   └── *.yaml
├── plan.md              # How to build (from /plan)
└── tasks.md             # Ordered work items (from /tasks)
```

## Key Workflow Rules

### Script Execution
- **Always use absolute paths** - Scripts require repo root context
- **Run from repo root** - All `.specify/scripts/bash/*` commands execute from repository root
- **Parse JSON output** - Scripts use `--json` flag for structured output
- **Check prerequisites** - Use `check-prerequisites.sh --json` to validate state

### File Updates
- **Constitution changes** - Update version, document impact, update templates
- **Agent context updates** - Run `.specify/scripts/bash/update-agent-context.sh claude` (no other args)
- **Preserve manual edits** - Scripts maintain user customizations between markers

### Command Dependencies
```
/specify → /clarify → /plan → /tasks → [/analyze] → /implement
   ↓          ↓          ↓        ↓         ↓            ↓
 spec.md  + Clarif.  research   tasks    analysis    execution
                     data-model   .md      report
                     contracts/
                     quickstart
                     plan.md
```

### Phase Ordering
- **Setup** → **Tests** → **Core** → **Integration** → **Polish**
- Tests MUST be written before implementation (constitutional requirement)
- Parallel tasks [P] run concurrently if independent files
- Sequential tasks run in order if shared files

## Common Patterns

### Creating New Features
```bash
# User runs: /specify "Add user authentication with Azure AD B2C"
# This executes: .specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS"
# Output: { "BRANCH_NAME": "001-user-authentication", "SPEC_FILE": "/path/to/specs/001-user-authentication/spec.md" }
```

### Planning Implementation
```bash
# User runs: /plan
# This executes: .specify/scripts/bash/setup-plan.sh --json
# Produces: research.md, data-model.md, contracts/, quickstart.md, plan.md
```

### Task Generation
- One contract file → one contract test task [P]
- One entity → one model creation task [P]
- One endpoint → one implementation task
- One user story → one integration test [P]
- Different files = parallel [P], same file = sequential

### Constitution Violations
- Document in plan.md "Complexity Tracking" section
- Justify why simpler alternative rejected
- Simpler approach must be proven insufficient

## Important Notes

- **Never skip TDD** - Tests failing before implementation is enforced
- **NEEDS CLARIFICATION markers** - Must be resolved in spec.md before planning
- **Template compliance** - All artifacts reference constitution version
- **Atomic updates** - Agent context updated incrementally (O(1) operation)
- **Error handling** - Scripts use ERROR/WARN prefixes for diagnostics

## Technology Stack

### Current Setup
- **Framework**: Specify (constitutional development workflow)
- **Version Control**: Git (feature branches: ###-feature-name)
- **Primary Language**: Bash (automation scripts)
- **Documentation**: Markdown (all specs and plans)

### Azure Integration (from Constitution)
- Azure SDK for JavaScript/TypeScript
- Azure CLI and Bicep for IaC
- Managed Identity (no keys in code)
- Application Insights for observability
