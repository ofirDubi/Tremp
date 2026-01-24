# Tremp Constitution

> Tremp is a multimodal transportation routing application that combines public transit (buses, trains) with carpooling/ride-sharing for Israel. The core mission: given a driver going from A to B, find the best drop-off location within an X-minute detour such that continuing via public transportation provides the shortest total trip time. We're transforming this from a 20% prototype into a state-of-the-art transit app.

**Version:** 1.0.0

---

## Ralph Wiggum

**Source:** https://github.com/fstandhartinger/ralph-wiggum
**Commit:** main
**Installed:** 2026-01-18

### Auto-Update

At session start, check for updates:
1. Run: `git ls-remote https://github.com/fstandhartinger/ralph-wiggum.git HEAD`
2. If hash differs: fetch latest scripts, update this file, inform user

---

## Context Detection

**Ralph Loop Mode** (you're in this if started by ralph-loop.sh):
- Focus on implementation — no unnecessary questions
- Pick highest priority incomplete spec from `specs/`
- Reference `IMPLEMENTATION_PLAN.md` for task order
- Complete ALL acceptance criteria
- Test using mock server and MCP tools
- Commit and push
- Output `<promise>DONE</promise>` ONLY when 100% complete

**Interactive Mode** (normal conversation):
- Be helpful and conversational
- Guide decisions, create specs
- Explain Ralph loop when ready

---

## Core Principles

### I. Test-Driven Development
Every feature must have testable acceptance criteria. Use the mock server and Android MCP to verify before marking complete.

### II. One Page at a Time
Complete each screen fully (including tests) before moving to the next. The order is defined in `IMPLEMENTATION_PLAN.md`.

### III. API-First
The OpenAPI specification is the contract. Client and server must both conform to it exactly.

### IV. Simplicity
Build exactly what's needed, nothing more. Dark theme, Hebrew-first RTL support.

---

## Technical Stack

**Backend:**
- Python 3.7+ with Falcon REST framework
- Valhalla routing engine (Docker)
- ULTRA-RAPTOR algorithm for transit routing
- Israel GTFS feed for schedules

**Frontend:**
- Flutter 3.3.4+ (Dart)
- flutter_map for mapping
- Provider for state management
- Dark theme UI

**Testing:**
- Mock server implementing OpenAPI spec
- Android MCP for UI automation
- Emulator: Pixel_3a_API_34

---

## Autonomy

**YOLO Mode:** ENABLED
Full permission to read/write files, execute commands, run tests, make HTTP requests.

**Git Autonomy:** ENABLED
Commit and push without asking, using meaningful commit messages with Co-Authored-By.

---

## Work Items

**Primary Source:** `IMPLEMENTATION_PLAN.md`
**Spec Source:** `specs/` folder

### Implementation Order

1. **Phase 1:** OpenAPI Specification (`openspec/api/tremp-api.yaml`)
2. **Phase 2:** Mock Server (`tremp_app/test/mocks/`)
3. **Phase 3:** Foundation & Theme
4. **Phases 4-8:** Screens (one at a time, with tests)
5. **Phase 9:** Integration

### Creating Specs

For detailed tasks, create `specs/NNN-feature-name.md`:

```markdown
# Feature: [Name]

## Requirements
- [What it does]

## Acceptance Criteria
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
- [ ] MCP test passes

**Output when complete:** `<promise>DONE</promise>`
```

---

## Running Ralph

```bash
# Claude Code (recommended)
./scripts/ralph-loop.sh

# With iteration limit
./scripts/ralph-loop.sh 20

# OpenAI Codex
./scripts/ralph-loop-codex.sh
```

---

## Completion Signal

When a spec/task is 100% complete:
1. All acceptance criteria verified
2. Tests pass (including MCP UI tests)
3. Changes committed and pushed
4. Output: `<promise>DONE</promise>`

**Never output this until truly complete.**

---

## Project Files Reference

| File | Purpose |
|------|---------|
| `IMPLEMENTATION_PLAN.md` | Checklist of all tasks in order |
| `openspec/changes/refactor-ui-screens/` | The UI refactor proposal |
| `openspec/api/tremp-api.yaml` | OpenAPI specification (to create) |
| `tremp_app/lib/` | Flutter app source |
| `src/server/` | Python backend |
| `design_images/` | UI design inspiration |

---

## Testing Commands

```bash
# Start mock server (once implemented)
cd tremp_app && dart test/mocks/mock_server.dart

# Start real server
python src/server/tremp_server_wsgi.py

# Run Flutter app on emulator
cd tremp_app && flutter run

# MCP tools available:
# - mobile_take_screenshot
# - mobile_list_elements_on_screen
# - mobile_click_on_screen_at_coordinates
```
