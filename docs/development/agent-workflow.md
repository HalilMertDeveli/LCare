# Agent workflow

How Claude Code agents (and humans) work on this repository in parallel.

## Ownership

| Workstream | Owns | Must not touch |
|---|---|---|
| Engineering lead | `services/api`, `tests/backend`, `docs/`, `infra/`, `.github/`, root files, git (branches, commits, merges) | — |
| Backend agent (when used) | `services/api`, `tests/backend` | `apps/*` |
| Web agent | `apps/web`, `packages/contracts` (except `openapi.json`) | `services/`, `apps/mobile`, git |
| Mobile agent | `apps/mobile` | `services/`, `apps/web`, `packages/`, git |
| QA/integration | `tests/integration`, test reports | production code (reports defects instead) |

## Rules

1. **Contract first.** API changes are made by the lead/backend owner, exported to `packages/contracts/openapi.json`,
   documented in `docs/api/contracts.md`, and announced to the web and mobile agents before they rely on them.
2. **One migration writer at a time.** Only the backend owner adds EF migrations.
3. **No shared files across concurrent agents.** Directory ownership above prevents conflicts in a shared checkout;
   when two agents must touch overlapping files, use separate git worktrees/branches instead.
4. **Agents do not commit.** The lead reviews, runs the full test suite and commits to a feature branch.
5. **Never merge to `main` directly** and never deploy. `main` changes only through reviewed pull requests with green CI.
6. **Report honestly.** Every result is PASS / FAIL / BLOCKED / NOT TESTABLE with the command that produced it.

## Phase 0 execution

Claude Code in this environment supports background sub-agents (Agent tool) but not a dedicated "Agent Teams"
mode, so Phase 0 used: the lead built the API, contract and backend tests first; then a Web agent and a Mobile
agent worked concurrently in their own directories of the same checkout against the running API; the lead
integrated, ran cross-platform verification and committed on `feature/phase-0-foundation`.
