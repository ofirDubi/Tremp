# Ralph Build Mode

Based on Geoffrey Huntley's Ralph Wiggum methodology.

---

## Phase 0: Orient

0a. Read `.specify/memory/constitution.md` for project principles (if exists).

0b. Study `specs/` folder to understand all feature specifications.

---

## Phase 1: Select Work Item

**DEFAULT: Work directly from specs (no plan needed)**

Look at the `specs/` folder and find specs that are NOT yet complete.

A spec is incomplete if:
- It has unchecked acceptance criteria `- [ ]`
- It does NOT have `## Status: COMPLETE` at the top
- The codebase doesn't fully implement its requirements

Pick the **HIGHEST PRIORITY** incomplete spec:
- Lower spec numbers = higher priority (001 before 010)
- Or follow any priority hints in the spec itself

**OPTIONAL: If IMPLEMENTATION_PLAN.md exists AND has tasks**
You may use it to pick the next task. But this is optional — most projects just use specs directly.

Before implementing, search the codebase — don't assume the work isn't already done.

---

## Phase 2: Implement

Implement the selected spec completely:
- Follow the spec's requirements exactly
- Write clean, maintainable code
- Add tests as needed
- Handle edge cases mentioned in the spec

---

## Phase 3: Validate

Run the project's test suite and verify:
- All existing tests still pass
- New functionality works as specified
- The spec's acceptance criteria are 100% met

---

## Phase 4: Commit & Mark Complete

1. Add `## Status: COMPLETE` to the top of the spec file
2. Check off all acceptance criteria in the spec: `- [x]`
3. `git add -A`
4. `git commit` with a descriptive message referencing the spec
5. `git push`

---

## Completion Signal

**CRITICAL:** Only output the magic phrase when the spec is 100% complete.

Check:
- [ ] All requirements from the spec are implemented
- [ ] All acceptance criteria pass
- [ ] All tests pass
- [ ] Changes committed and pushed
- [ ] Spec marked as COMPLETE

**If ALL checks pass, output:** `<promise>DONE</promise>`

**If ANY check fails:** Fix the issue and try again. Do NOT output the magic phrase.
