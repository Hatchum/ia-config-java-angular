# Spec template (workflow-dev, step-2-specify)

Copy into `docs/specs/<YYYY-MM-DD>-<slug>.md` of the target project and fill
**in the team's language**. Keep it short — a spec the human won't read is a
spec that won't be validated. Every acceptance criterion must be observable
and testable; the reviewer receives them verbatim at step-4.

```markdown
# Spec — <feature title>

- **Status:** draft | approved | implemented
- **Date / requester:** <YYYY-MM-DD> / <who asked>
- **Workflow:** workflow-dev (archetype `feature`)

## Goal (why)
<One or two sentences: the problem this feature solves, for whom.>

## Expected behavior (what)
<Concrete description of the behavior once implemented — user-visible flow,
API contract, or both. State what happens in the nominal case AND the main
error/edge cases.>

## Scope
- **In:** <what this run will change>
- **Out:** <explicitly excluded — prevents scope creep during implementation>

## Integration points (from exploration)
<Files/classes/components the change plugs into, with paths — from step-1.>

## Technical decisions
<Layering, patterns, data shapes… agreed or deduced from repo conventions.
One line each, with the reason.>

## Acceptance criteria
<Each observable & testable — these are the review contract.>
- [ ] AC1 — <criterion>
- [ ] AC2 — <criterion>

## Resolved questions
<Q → A log of the AskUserQuestion loop, so decisions are traceable.>
- Q: <question> → A: <the human's answer>

## Verification plan
<The exact commands that must be green: scripts\test.cmd / mvn -q test /
ng test / ng build — plus any manual/Playwright check for UI surfaces.>
```
