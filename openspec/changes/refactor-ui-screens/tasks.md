# Implementation Tasks

## Phase 1: Foundation & Theme Setup
- [ ] 1.1 Create dark theme configuration in `lib/theme/app_theme.dart`
- [ ] 1.2 Define color palette constants (dark backgrounds, blue accents, line colors)
- [ ] 1.3 Create reusable text styles for Hebrew/English support
- [ ] 1.4 Set up RTL (right-to-left) support for Hebrew
- [ ] 1.5 Update `main.dart` to use new theme and 4-tab navigation

## Phase 2: Shared Components
- [ ] 2.1 Create `StationMarker` widget for map markers (yellow badges)
- [ ] 2.2 Create `LineBadge` widget for colored line number badges
- [ ] 2.3 Create `StationCard` widget for station list items
- [ ] 2.4 Create `LineCard` widget for line list items
- [ ] 2.5 Create `ArrivalTimeCard` widget showing real-time arrivals
- [ ] 2.6 Create `BottomSheetContainer` reusable draggable bottom sheet
- [ ] 2.7 Create `SearchInput` widget for origin/destination fields

## Phase 3: Map Home Screen
- [ ] 3.1 Implement dark-themed map with flutter_map
- [ ] 3.2 Add station markers layer with tap handling
- [ ] 3.3 Create "Where are you going?" search bar
- [ ] 3.4 Implement draggable bottom sheet with two states (collapsed/expanded)
- [ ] 3.5 Add "Nearby Routes" tab showing stations near user location
- [ ] 3.6 Add "Favorites" tab showing saved locations
- [ ] 3.7 Implement station selection → show arriving buses with times
- [ ] 3.8 Add location button (GPS) and layers button
- [ ] 3.9 Connect to backend `/stations` endpoint for visible area

## Phase 4: Route Search Screen
- [ ] 4.1 Create screen structure with Directions/Lines/Stations tabs
- [ ] 4.2 Implement origin field ("Leave from your current location")
- [ ] 4.3 Implement destination field with place search
- [ ] 4.4 Add "Leave now" dropdown with time picker
- [ ] 4.5 Add filter/settings button for route preferences
- [ ] 4.6 Implement "Recent Directions" section with history
- [ ] 4.7 Implement "Favorites" section with home/work/custom
- [ ] 4.8 Implement "Recents" section for recently viewed stops
- [ ] 4.9 Connect to backend for route calculation

## Phase 5: Lines Browser Screen
- [ ] 5.1 Create lines list view with search
- [ ] 5.2 Implement line search by number or destination
- [ ] 5.3 Create line item cards with operator logo, number, direction
- [ ] 5.4 Add "Recents" section for recently viewed lines
- [ ] 5.5 Implement line detail view (tap → show all stops)
- [ ] 5.6 Add operator logos (Egged, Dan, Kavim, Metropoline, etc.)
- [ ] 5.7 Connect to backend for lines data

## Phase 6: Stations Browser Screen
- [ ] 6.1 Create stations list view with search
- [ ] 6.2 Implement search by station ID, name, or address
- [ ] 6.3 Create station cards with name, ID, address, direction
- [ ] 6.4 Display all serving lines as color-coded badges
- [ ] 6.5 Add "Recents" section for recently viewed stations
- [ ] 6.6 Implement station detail view (tap → show arrivals)
- [ ] 6.7 Connect to backend `/stations` endpoint

## Phase 7: Profile/Settings Screen
- [ ] 7.1 Create blue header with user greeting
- [ ] 7.2 Add profile card (name, profile type)
- [ ] 7.3 Implement trip history view (read-only, no payments)
- [ ] 7.4 Add profile settings screen
- [ ] 7.5 Implement language selector (Hebrew/English/Arabic)
- [ ] 7.6 Add customer service/contact screen
- [ ] 7.7 Add about/info screen with app version
- [ ] 7.8 Store user preferences in local storage

## Phase 8: Data & State Management
- [ ] 8.1 Create `Station` model with all fields from backend
- [ ] 8.2 Create `Line` model with operator, number, stops
- [ ] 8.3 Create `Arrival` model for real-time arrival data
- [ ] 8.4 Set up Provider state management for app-wide state
- [ ] 8.5 Implement favorites storage (SharedPreferences)
- [ ] 8.6 Implement recents storage (last 10 stations, lines, directions)
- [ ] 8.7 Add loading states and error handling UI

## Phase 9: OpenAPI Specification
- [ ] 9.1 Create `openspec/api/tremp-api.yaml` OpenAPI 3.0 specification
- [ ] 9.2 Define `/stations` endpoint (GET stations in bounding box)
- [ ] 9.3 Define `/station/{id}` endpoint (GET station details with arrivals)
- [ ] 9.4 Define `/lines` endpoint (GET all lines, with search filter)
- [ ] 9.5 Define `/line/{id}` endpoint (GET line details with stops)
- [ ] 9.6 Define `/arrivals` endpoint (GET real-time arrivals for station)
- [ ] 9.7 Define `/route` endpoint (POST route calculation request)
- [ ] 9.8 Define `/search` endpoint (GET place search autocomplete)
- [ ] 9.9 Define common schemas: Station, Line, Arrival, Route, Place
- [ ] 9.10 Add API documentation with examples

## Phase 10: Backend Integration
- [ ] 10.1 Extend `server_comms.dart` to match OpenAPI spec
- [ ] 10.2 Implement missing endpoints on Python server
- [ ] 10.3 Add error handling and retry logic
- [ ] 10.4 Implement offline caching for frequently used data
- [ ] 10.5 Validate client/server match OpenAPI contract

## Phase 11: Mock Server & GUI Testing
- [ ] 11.1 Create mock server based on OpenAPI spec (`test/mock_server.dart`)
- [ ] 11.2 Generate mock data fixtures for stations, lines, arrivals
- [ ] 11.3 Implement mock server responses with realistic delays
- [ ] 11.4 Create test harness that starts mock server for tests

## Phase 12: Android MCP UI Tests
- [ ] 12.1 Write test: Map Home loads and displays station markers
- [ ] 12.2 Write test: Tap station marker → bottom sheet shows arrivals
- [ ] 12.3 Write test: Search bar opens Route Search screen
- [ ] 12.4 Write test: Lines tab displays line list from mock data
- [ ] 12.5 Write test: Stations tab displays station cards with badges
- [ ] 12.6 Write test: Profile tab shows settings menu
- [ ] 12.7 Write test: Navigation between all 4 tabs works
- [ ] 12.8 Write test: Hebrew RTL layout displays correctly
- [ ] 12.9 Write test: Error states display appropriate messages
- [ ] 12.10 Create CI pipeline for automated MCP tests

## Phase 13: Polish & Final Testing
- [ ] 13.1 Add loading skeletons/shimmer effects
- [ ] 13.2 Implement pull-to-refresh where applicable
- [ ] 13.3 Add empty state illustrations
- [ ] 13.4 Test RTL layout in Hebrew
- [ ] 13.5 Test on multiple screen sizes
- [ ] 13.6 Performance optimization (list virtualization, etc.)
- [ ] 13.7 Final integration test with real backend
