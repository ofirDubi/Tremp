## ADDED Requirements

### Requirement: Dark Theme Design System
The app SHALL use a consistent dark theme across all screens with Material 3 design principles.

#### Scenario: App launches with dark theme
- **WHEN** user opens the app
- **THEN** all screens display with dark background (#121212)
- **AND** text is light-colored for readability
- **AND** accent colors are blue (#2196F3) for interactive elements

#### Scenario: Theme consistency across navigation
- **WHEN** user navigates between tabs
- **THEN** dark theme remains consistent
- **AND** no flash of light content occurs

---

### Requirement: Four-Tab Bottom Navigation
The app SHALL provide a 4-tab bottom navigation bar for primary navigation.

#### Scenario: Navigation tabs displayed
- **WHEN** user views any screen
- **THEN** bottom navigation shows 4 tabs: Route Planning, Lines, Stations, Profile
- **AND** current tab is highlighted with blue accent
- **AND** tab labels support Hebrew (תכנון מסלול, קווים, תחנות, אזור אישי)

#### Scenario: Tab switching
- **WHEN** user taps a navigation tab
- **THEN** corresponding screen is displayed immediately
- **AND** tab highlight updates to selected tab

---

### Requirement: Map Home Screen with Station Discovery
The app SHALL display an interactive dark-themed map showing nearby transit stations.

#### Scenario: Map displays with user location
- **WHEN** user opens the app on Route Planning tab
- **THEN** dark-themed map is displayed
- **AND** user's current location is shown (if permission granted)
- **AND** nearby stations appear as yellow markers

#### Scenario: Station marker interaction
- **WHEN** user taps a station marker on the map
- **THEN** bottom sheet expands showing station name and ID
- **AND** upcoming arrivals for that station are listed
- **AND** each arrival shows line number, destination, and time

#### Scenario: Search bar interaction
- **WHEN** user taps "Where are you going?" search bar
- **THEN** Route Search screen opens
- **AND** keyboard appears for destination input

---

### Requirement: Draggable Bottom Sheet for Station Info
The app SHALL display station information in a draggable bottom sheet with multiple snap points.

#### Scenario: Bottom sheet collapsed state
- **WHEN** no station is selected
- **THEN** bottom sheet shows "Nearby Routes" and "Favorites" tabs
- **AND** sheet is collapsed to 25% of screen height

#### Scenario: Bottom sheet expanded state
- **WHEN** user drags bottom sheet upward
- **THEN** sheet expands to show full station details
- **AND** complete list of arrivals is visible

#### Scenario: Nearby routes tab
- **WHEN** user views "Nearby Routes" tab
- **THEN** stations within 500m are listed
- **AND** each station shows name and upcoming arrivals

#### Scenario: Favorites tab
- **WHEN** user views "Favorites" tab
- **THEN** saved locations are displayed (home, work, custom)
- **AND** user can tap to navigate to saved location

---

### Requirement: Route Search Screen with Multi-Mode Search
The app SHALL provide a route search screen with tabs for Directions, Lines, and Stations.

#### Scenario: Directions tab default view
- **WHEN** user opens Route Search screen
- **THEN** Directions tab is active by default
- **AND** origin field shows "Leave from your current location"
- **AND** destination field is empty with placeholder text

#### Scenario: Route search with origin and destination
- **WHEN** user enters origin and destination
- **AND** taps search or presses enter
- **THEN** routing request is sent to backend
- **AND** results show available routes with times

#### Scenario: Time selector
- **WHEN** user taps "Leave now" dropdown
- **THEN** options appear: "Leave now", "Depart at", "Arrive by"
- **AND** date/time picker appears for custom times

#### Scenario: Recent directions displayed
- **WHEN** user has previous route searches
- **THEN** "Recent Directions" section shows last 5 routes
- **AND** each entry shows origin → destination with time

#### Scenario: Favorites section
- **WHEN** user has saved locations
- **THEN** "Favorites" section shows saved places
- **AND** home icon for home address
- **AND** briefcase icon for work address
- **AND** star icon for custom favorites

---

### Requirement: Lines Browser Screen
The app SHALL provide a searchable list of all transit lines.

#### Scenario: Lines list display
- **WHEN** user opens Lines tab
- **THEN** search field appears at top
- **AND** recent lines are displayed below
- **AND** lines can be searched by number or destination

#### Scenario: Line search by number
- **WHEN** user types "273" in search field
- **THEN** line 273 appears in results
- **AND** result shows operator logo, line number, direction

#### Scenario: Line search by destination
- **WHEN** user types "Reading Terminal" in search field
- **THEN** lines going to Reading Terminal appear
- **AND** results show all matching lines

#### Scenario: Line card information
- **WHEN** viewing a line in the list
- **THEN** card displays: operator logo, line number
- **AND** direction (e.g., "Toward Reading Terminal, Tel Aviv")
- **AND** current station (e.g., "Station: Ben Gurion/Cemetery")

#### Scenario: Line detail view
- **WHEN** user taps a line card
- **THEN** line detail screen opens
- **AND** all stops on the line are listed in order
- **AND** current vehicle positions shown (if available)

---

### Requirement: Stations Browser Screen
The app SHALL provide a searchable list of all transit stations.

#### Scenario: Stations list display
- **WHEN** user opens Stations tab
- **THEN** search field appears at top
- **AND** recent stations are displayed below

#### Scenario: Station search by ID
- **WHEN** user types "25786" in search field
- **THEN** station with ID 25786 appears in results

#### Scenario: Station search by name
- **WHEN** user types "Ben Gurion" in search field
- **THEN** stations matching "Ben Gurion" appear
- **AND** results sorted by relevance

#### Scenario: Station card information
- **WHEN** viewing a station in the list
- **THEN** card displays: station name, stop ID
- **AND** address and heading direction
- **AND** all serving lines as color-coded badges

#### Scenario: Line badges on station card
- **WHEN** station serves multiple lines
- **THEN** line badges show all line numbers
- **AND** badges are color-coded by operator or type
- **AND** badges wrap to multiple rows if needed

#### Scenario: Station detail view
- **WHEN** user taps a station card
- **THEN** station detail screen opens
- **AND** real-time arrivals are displayed
- **AND** station shown on map

---

### Requirement: Profile and Settings Screen
The app SHALL provide a profile screen with user settings and preferences.

#### Scenario: Profile header display
- **WHEN** user opens Profile tab
- **THEN** blue header shows greeting (e.g., "שלום אופיר")
- **AND** profile card shows user name and type

#### Scenario: Settings menu items
- **WHEN** viewing profile screen
- **THEN** menu shows: Trip History, Profile Settings, Language, Support, About
- **AND** payment-related options are NOT displayed

#### Scenario: Language selection
- **WHEN** user taps Language option
- **THEN** language picker shows: Hebrew, English, Arabic
- **AND** selecting language updates app immediately
- **AND** RTL/LTR direction updates accordingly

#### Scenario: Trip history view
- **WHEN** user taps Trip History
- **THEN** past route searches are displayed
- **AND** each entry shows date, origin, destination
- **AND** no payment information is shown

---

### Requirement: Real-Time Arrival Information
The app SHALL display real-time arrival predictions for stations.

#### Scenario: Live arrival indicator
- **WHEN** arrival time is based on real-time data
- **THEN** time shows with live indicator (e.g., "9min" with signal icon)
- **AND** indicator distinguishes from scheduled times

#### Scenario: Scheduled arrival display
- **WHEN** only scheduled data is available
- **THEN** time shows in HH:MM format (e.g., "18:34")
- **AND** next scheduled time shown below (e.g., "18:56")

#### Scenario: Multiple arrivals per line
- **WHEN** same line has multiple upcoming arrivals
- **THEN** next 2-3 arrival times are shown
- **AND** times separated by comma or shown vertically

---

### Requirement: Hebrew RTL Support
The app SHALL support right-to-left layout for Hebrew language.

#### Scenario: RTL text alignment
- **WHEN** app language is Hebrew
- **THEN** text aligns to the right
- **AND** lists start from right side
- **AND** navigation icons flip appropriately

#### Scenario: RTL navigation
- **WHEN** in RTL mode
- **THEN** back button appears on right side
- **AND** swipe gestures reverse direction
- **AND** horizontal scrolling reverses

---

### Requirement: Offline Favorites Access
The app SHALL allow access to saved favorites without network connection.

#### Scenario: Favorites available offline
- **WHEN** device has no network connection
- **THEN** favorites list is still accessible
- **AND** saved station/line details viewable
- **AND** cached arrival times shown with "offline" indicator

#### Scenario: Favorites sync when online
- **WHEN** network connection restored
- **THEN** favorites sync with fresh data
- **AND** arrival times update automatically

---

### Requirement: OpenAPI Specification for Client-Server API
The project SHALL maintain an OpenAPI 3.0 specification defining all client-server API contracts.

#### Scenario: API spec exists and is valid
- **WHEN** developer opens `openspec/api/tremp-api.yaml`
- **THEN** valid OpenAPI 3.0 specification is present
- **AND** all endpoints used by client are documented
- **AND** request/response schemas are fully defined

#### Scenario: Stations endpoint documented
- **WHEN** reviewing `/stations` endpoint in spec
- **THEN** GET method with bounding box query params is defined
- **AND** response schema includes array of Station objects
- **AND** Station schema includes: id, name, location, lines

#### Scenario: Lines endpoint documented
- **WHEN** reviewing `/lines` endpoint in spec
- **THEN** GET method with optional search filter is defined
- **AND** response schema includes array of Line objects
- **AND** Line schema includes: id, number, operator, direction, stops

#### Scenario: Arrivals endpoint documented
- **WHEN** reviewing `/arrivals` endpoint in spec
- **THEN** GET method with station_id param is defined
- **AND** response schema includes array of Arrival objects
- **AND** Arrival schema includes: line, destination, arrival_time, is_realtime

#### Scenario: Route endpoint documented
- **WHEN** reviewing `/route` endpoint in spec
- **THEN** POST method with origin/destination body is defined
- **AND** response schema includes Route with legs and timing
- **AND** supports departure_time parameter

---

### Requirement: Mock Server for GUI Testing
The project SHALL provide a mock server that implements the OpenAPI spec for testing.

#### Scenario: Mock server starts successfully
- **WHEN** test harness initializes mock server
- **THEN** server starts on configurable port
- **AND** all API endpoints return valid mock data
- **AND** responses match OpenAPI schema

#### Scenario: Mock data is realistic
- **WHEN** client requests stations from mock server
- **THEN** response contains realistic Israeli station data
- **AND** station names are in Hebrew and English
- **AND** line numbers match real transit operators

#### Scenario: Mock server supports test scenarios
- **WHEN** test configures mock for specific scenario
- **THEN** mock can return empty results (no stations nearby)
- **AND** mock can return error responses (server error, timeout)
- **AND** mock can simulate slow responses (loading states)

---

### Requirement: Automated GUI Tests with Android MCP
The project SHALL include automated UI tests using mobile-mcp for Android emulator testing.

#### Scenario: Test verifies Map Home screen
- **WHEN** automated test runs against mock server
- **THEN** test launches app on Android emulator
- **AND** verifies map displays with station markers
- **AND** verifies bottom sheet shows nearby routes

#### Scenario: Test verifies station selection flow
- **WHEN** test taps on station marker
- **THEN** bottom sheet expands
- **AND** station name and arrivals are visible
- **AND** arrival times match mock server data

#### Scenario: Test verifies navigation tabs
- **WHEN** test clicks each navigation tab
- **THEN** correct screen is displayed for each tab
- **AND** screen content matches expected layout
- **AND** back navigation works correctly

#### Scenario: Test verifies Lines browser
- **WHEN** test opens Lines tab
- **THEN** search field is visible
- **AND** line cards display operator logos
- **AND** tapping line shows line details

#### Scenario: Test verifies Stations browser
- **WHEN** test opens Stations tab
- **THEN** station cards show line badges
- **AND** search by station ID works
- **AND** search by name works

#### Scenario: Test verifies error handling
- **WHEN** mock server returns error
- **THEN** app displays user-friendly error message
- **AND** retry option is available
- **AND** app does not crash

#### Scenario: Tests run in CI pipeline
- **WHEN** code is pushed to repository
- **THEN** CI pipeline starts Android emulator
- **AND** runs all MCP GUI tests
- **AND** reports pass/fail status
