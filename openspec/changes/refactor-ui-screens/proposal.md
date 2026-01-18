# Change: Complete UI/UX Refactor - 5 Core Screens

## Why

The current Tremp app has placeholder screens and an outdated light theme. To become a state-of-the-art public transportation app, we need a professional dark-themed UI with proper functionality matching modern transit apps like Moovit.

## What Changes

### New Navigation Structure (4 tabs instead of 5)
- **Route Planning** (תכנון מסלול) - Main map + search functionality
- **Lines** (קווים) - Browse and search bus/train lines
- **Stations** (תחנות) - Browse and search stations
- **Profile** (אזור אישי) - User settings and preferences

*Note: Removing "Commute", "Saved", "Contribute", "Updates" tabs. Favorites/saved locations will be integrated into Route Planning screen.*

### Screen Implementations

1. **Map Home Screen** (replaces Explore)
   - Dark theme map with custom station markers
   - "Where are you going?" search bar at top
   - Bottom sheet with nearby routes and favorites tabs
   - Real-time arrival information for selected station
   - Station selection shows serving lines with arrival times

2. **Route Search Screen** (accessed from search bar)
   - Three sub-tabs: Directions, Lines, Stations
   - Origin/destination input fields
   - "Leave now" time selector
   - Recent directions history
   - Favorites section (home, work, custom locations)
   - Recent stations/stops

3. **Lines Browser Screen**
   - Search by line number or destination
   - List of lines with operator logos
   - Line details: number, direction, serving station
   - Recent lines history

4. **Stations Browser Screen**
   - Search by station ID, name, or address
   - Station cards showing:
     - Station name and ID
     - Address and heading direction
     - All serving lines as color-coded badges
   - Recent stations history

5. **Profile/Settings Screen**
   - User greeting header with profile info
   - Settings menu:
     - Trip history (without payment)
     - Profile settings
     - Language selection (Hebrew/English/Arabic)
     - Customer service/support
     - About/more info

### Theme Changes
- **BREAKING**: Switch from light theme to dark theme
- Primary colors: Dark gray background (#1a1a1a), blue accents (#2196F3)
- Station markers: Yellow/gold badges
- Operator-specific colors for line badges

## Impact

- **Affected specs**: New `mobile-ui` capability
- **Affected code**:
  - `tremp_app/lib/main.dart` - Complete rewrite
  - `tremp_app/lib/other_screens.dart` - Remove, replace with new screens
  - New files for each screen component
- **Breaking changes**: Complete UI overhaul, navigation structure change
