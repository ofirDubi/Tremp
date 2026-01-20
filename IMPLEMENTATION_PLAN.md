# Tremp UI Refactor - Implementation Plan

This is the working checklist for implementing the UI refactor. Tasks must be completed in order.
**Rule: Do not proceed to the next phase until all tests for the current phase pass.**

---

## Phase 1: OpenAPI Specification
**Goal:** Define the complete client-server API contract

- [x] 1.1 Create `openspec/api/tremp-api.yaml` with OpenAPI 3.0 header
- [x] 1.2 Define `Station` schema (id, name, location, lines, direction)
- [x] 1.3 Define `Line` schema (id, number, operator, direction, stops)
- [x] 1.4 Define `Arrival` schema (line, destination, arrival_time, is_realtime)
- [x] 1.5 Define `Route` schema (legs, total_time, transfers)
- [x] 1.6 Define `Place` schema (name, address, coordinates)
- [x] 1.7 Define `GET /stations` endpoint (bounding box query params)
- [x] 1.8 Define `GET /station/{id}` endpoint (station details with arrivals)
- [x] 1.9 Define `GET /lines` endpoint (optional search filter)
- [x] 1.10 Define `GET /line/{id}` endpoint (line details with stops)
- [x] 1.11 Define `GET /arrivals` endpoint (real-time arrivals for station)
- [x] 1.12 Define `POST /route` endpoint (route calculation)
- [x] 1.13 Define `GET /search` endpoint (place autocomplete)
- [x] 1.14 Add example requests/responses for each endpoint
- [x] 1.15 Validate OpenAPI spec with `openapi-generator validate`

**Acceptance Criteria:**
- [x] OpenAPI spec passes validation
- [x] All endpoints documented with request/response examples
- [x] Schemas match Flutter app data requirements

---

## Phase 2: Server Mocks
**Goal:** Create mock server that implements OpenAPI spec for testing

- [x] 2.1 Create `tremp_app/test/mocks/` directory structure
- [x] 2.2 Create `mock_data/stations.json` with 20+ realistic Israeli stations
- [x] 2.3 Create `mock_data/lines.json` with 30+ lines (Egged, Dan, etc.)
- [x] 2.4 Create `mock_data/arrivals.json` with arrival times per station
- [x] 2.5 Create `mock_server.dart` with HTTP server implementation
- [x] 2.6 Implement `/stations` endpoint handler
- [x] 2.7 Implement `/station/{id}` endpoint handler
- [x] 2.8 Implement `/lines` endpoint handler
- [x] 2.9 Implement `/line/{id}` endpoint handler
- [x] 2.10 Implement `/arrivals` endpoint handler
- [x] 2.11 Implement `/route` endpoint handler (static response)
- [x] 2.12 Implement `/search` endpoint handler
- [x] 2.13 Add configurable delay for simulating network latency
- [x] 2.14 Add error simulation mode (500, timeout, empty)
- [x] 2.15 Create test verifying mock server matches OpenAPI spec

**Acceptance Criteria:**
- [x] Mock server starts and responds on all endpoints
- [x] Responses match OpenAPI schema exactly
- [x] Mock data includes Hebrew and English text
- [x] Error modes can be triggered for testing

---

## Phase 3: Foundation & Theme
**Goal:** Set up dark theme and app structure

- [x] 3.1 Create `lib/theme/app_theme.dart` with dark color palette
- [x] 3.2 Create `lib/theme/colors.dart` with color constants
- [x] 3.3 Create `lib/theme/text_styles.dart` with typography
- [x] 3.4 Update `main.dart` with dark theme configuration
- [x] 3.5 Set up RTL support for Hebrew
- [x] 3.6 Create 4-tab bottom navigation structure
- [x] 3.7 Create placeholder screens for each tab

**Test:** Visual verification on emulator - dark theme displays correctly ✅

---

## Phase 4: Map Home Screen
**Goal:** Implement main map screen with station discovery

### 4A: Basic Map
- [x] 4A.1 Create `lib/screens/map_home/map_home_screen.dart`
- [x] 4A.2 Configure flutter_map with dark tiles (CartoDB Dark Matter)
- [x] 4A.3 Add user location marker
- [x] 4A.4 Add zoom controls

### 4B: Station Markers
- [x] 4B.1 Create `lib/widgets/station_marker.dart` (yellow badge style)
- [x] 4B.2 Connect to `/stations` endpoint via mock server
- [x] 4B.3 Display station markers on map
- [x] 4B.4 Implement marker tap handling

### 4C: Bottom Sheet
- [x] 4C.1 Create `lib/widgets/bottom_sheet_container.dart`
- [x] 4C.2 Implement "Nearby Routes" tab
- [x] 4C.3 Implement "Favorites" tab
- [x] 4C.4 Create station info view with arrivals

### 4D: Tests
- [x] 4D.1 MCP Test: Map loads with station markers visible
- [x] 4D.2 MCP Test: Tap marker → bottom sheet shows station name
- [x] 4D.3 MCP Test: Bottom sheet shows arrival times from mock
- [x] 4D.4 MCP Test: Nearby/Favorites tabs switch correctly

**Acceptance Criteria:** All 4D tests pass before proceeding ✅

---

## Phase 5: Route Search Screen
**Goal:** Implement search and route planning

### 5A: Screen Structure
- [x] 5A.1 Create `lib/screens/route_search/route_search_screen.dart`
- [x] 5A.2 Implement Directions/Lines/Stations tab bar
- [x] 5A.3 Create origin/destination input fields

### 5B: Search Functionality
- [x] 5B.1 Connect to `/search` endpoint for autocomplete
- [x] 5B.2 Implement recent directions storage (SharedPreferences)
- [x] 5B.3 Implement favorites section (home, work, custom)
- [x] 5B.4 Implement "Leave now" time selector

### 5C: Route Results
- [x] 5C.1 Connect to `/route` endpoint
- [x] 5C.2 Display route options with timing
- [x] 5C.3 Show route details on tap

### 5D: Tests
- [x] 5D.1 MCP Test: Search screen opens from map search bar
- [x] 5D.2 MCP Test: Typing in destination shows autocomplete
- [x] 5D.3 MCP Test: Favorites section displays saved locations
- [x] 5D.4 MCP Test: Route calculation returns results

**Acceptance Criteria:** All 5D tests pass before proceeding ✅

---

## Phase 6: Lines Browser Screen
**Goal:** Implement lines browsing and search

### 6A: Screen Structure
- [ ] 6A.1 Create `lib/screens/lines_browser/lines_browser_screen.dart`
- [ ] 6A.2 Create search input field
- [ ] 6A.3 Create `lib/widgets/line_card.dart`

### 6B: Data & Search
- [ ] 6B.1 Connect to `/lines` endpoint
- [ ] 6B.2 Implement search by line number
- [ ] 6B.3 Implement search by destination
- [ ] 6B.4 Display operator logos (Egged, Dan, etc.)

### 6C: Line Details
- [ ] 6C.1 Create line detail screen
- [ ] 6C.2 Show all stops on the line
- [ ] 6C.3 Implement recent lines storage

### 6D: Tests
- [ ] 6D.1 MCP Test: Lines tab shows list of lines
- [ ] 6D.2 MCP Test: Search by number "273" finds correct line
- [ ] 6D.3 MCP Test: Line card shows operator logo
- [ ] 6D.4 MCP Test: Tap line → shows stops

**Acceptance Criteria:** All 6D tests pass before proceeding

---

## Phase 7: Stations Browser Screen
**Goal:** Implement stations browsing with line badges

### 7A: Screen Structure
- [ ] 7A.1 Create `lib/screens/stations_browser/stations_browser_screen.dart`
- [ ] 7A.2 Create search input field
- [ ] 7A.3 Create `lib/widgets/station_card.dart`

### 7B: Data & Search
- [ ] 7B.1 Connect to `/stations` endpoint (full list mode)
- [ ] 7B.2 Implement search by station ID
- [ ] 7B.3 Implement search by station name
- [ ] 7B.4 Create `lib/widgets/line_badge.dart` (colored badges)

### 7C: Station Details
- [ ] 7C.1 Station card shows all serving lines as badges
- [ ] 7C.2 Implement recent stations storage
- [ ] 7C.3 Tap station → show arrivals

### 7D: Tests
- [ ] 7D.1 MCP Test: Stations tab shows list of stations
- [ ] 7D.2 MCP Test: Search by ID "25786" finds correct station
- [ ] 7D.3 MCP Test: Station card shows colored line badges
- [ ] 7D.4 MCP Test: Tap station → shows real-time arrivals

**Acceptance Criteria:** All 7D tests pass before proceeding

---

## Phase 8: Profile/Settings Screen
**Goal:** Implement user settings (no payment)

### 8A: Screen Structure
- [ ] 8A.1 Create `lib/screens/profile/profile_screen.dart`
- [ ] 8A.2 Create blue header with user greeting
- [ ] 8A.3 Create profile card widget

### 8B: Settings Menu
- [ ] 8B.1 Implement trip history view
- [ ] 8B.2 Implement profile settings
- [ ] 8B.3 Implement language selector (Hebrew/English/Arabic)
- [ ] 8B.4 Implement customer service link
- [ ] 8B.5 Implement about/info screen

### 8C: Persistence
- [ ] 8C.1 Store language preference
- [ ] 8C.2 Store user profile data locally

### 8D: Tests
- [ ] 8D.1 MCP Test: Profile tab shows user greeting
- [ ] 8D.2 MCP Test: Settings menu items are visible
- [ ] 8D.3 MCP Test: Language change updates UI
- [ ] 8D.4 MCP Test: No payment options visible

**Acceptance Criteria:** All 8D tests pass before proceeding

---

## Phase 9: Integration & Polish
**Goal:** Connect to real backend, final testing

- [ ] 9.1 Update `server_comms.dart` to match OpenAPI spec
- [ ] 9.2 Implement endpoint switching (mock ↔ real)
- [ ] 9.3 Test with real Python backend
- [ ] 9.4 Add loading states and shimmer effects
- [ ] 9.5 Add error handling UI
- [ ] 9.6 Add empty state illustrations
- [ ] 9.7 Performance optimization

### Final Tests
- [ ] 9.8 Full integration test with real backend
- [ ] 9.9 RTL Hebrew layout verification
- [ ] 9.10 Multiple screen size testing

---

## How to Use This Plan

1. **Pick the first unchecked task** in the current phase
2. **Implement it completely** with all edge cases
3. **Run the phase tests** (if applicable)
4. **Mark task as done** by changing `[ ]` to `[x]`
5. **Proceed to next task** only if current task is complete
6. **Do not skip phases** - each builds on the previous

## Status

- **Current Phase:** 6 (Lines Browser Screen)
- **Started:** 2026-01-18
- **Last Updated:** 2026-01-20
- **Phase 1 Completed:** 2026-01-18
- **Phase 2 Completed:** 2026-01-19
- **Phase 3 Completed:** 2026-01-19
- **Phase 4 Completed:** 2026-01-20
- **Phase 5 Completed:** 2026-01-20
