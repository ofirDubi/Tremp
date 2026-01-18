# Design Document: UI/UX Refactor

## Context

Tremp is transitioning from a prototype with placeholder screens to a production-ready transit app. The design inspiration comes from Moovit, a leading Israeli transit app. The user explicitly requested excluding payment functionality.

## Goals / Non-Goals

### Goals
- Create 5 professional, dark-themed screens matching modern transit app UX
- Support Hebrew RTL layout as primary, with English/Arabic options
- Integrate with existing RAPTOR routing backend
- Maintain fast, responsive UI with smooth animations
- Enable offline usage for frequently accessed data

### Non-Goals
- Payment integration (explicitly excluded)
- Real-time vehicle tracking on map (future enhancement)
- Social features or user accounts (local storage only for MVP)
- iOS-specific design (Flutter handles cross-platform)

## Decisions

### 1. Navigation Structure: 4 Tabs
**Decision**: Use 4-tab bottom navigation instead of current 5 tabs.

**Rationale**:
- Matches design inspiration structure (excluding payment tab)
- Clear purpose for each tab: Plan, Browse Lines, Browse Stations, Settings
- "Saved/Favorites" integrated into Route Planning screen (like Moovit)

**Alternatives considered**:
- Keep 5 tabs → Rejected: "Contribute" and "Updates" don't have clear functionality
- 3 tabs with hamburger menu → Rejected: Less discoverable

### 2. Theme: Material Dark
**Decision**: Use Material 3 dark theme with custom color palette.

**Color Palette**:
```dart
// Backgrounds
scaffoldBackground: Color(0xFF121212)  // Near black
surfaceColor: Color(0xFF1E1E1E)        // Card backgrounds
bottomSheetColor: Color(0xFF252525)    // Bottom sheets

// Accents
primaryBlue: Color(0xFF2196F3)         // Selected items, buttons
activeTabBlue: Color(0xFF42A5F5)       // Active tab indicator

// Station/Line Colors
stationMarkerYellow: Color(0xFFFFD600) // Map markers
busGreen: Color(0xFF4CAF50)            // Bus lines
trainOrange: Color(0xFFFF9800)         // Train lines
tramRed: Color(0xFFF44336)             // Tram/light rail
```

**Rationale**: Dark theme reduces eye strain, saves battery on OLED, matches design inspiration.

### 3. State Management: Provider + Local Models
**Decision**: Continue using Provider (already in project) with screen-specific models.

**Structure**:
```
lib/
├── models/
│   ├── station.dart
│   ├── line.dart
│   ├── arrival.dart
│   └── user_preferences.dart
├── providers/
│   ├── stations_provider.dart
│   ├── lines_provider.dart
│   ├── favorites_provider.dart
│   └── search_provider.dart
├── screens/
│   ├── map_home/
│   ├── route_search/
│   ├── lines_browser/
│   ├── stations_browser/
│   └── profile/
├── widgets/
│   ├── station_marker.dart
│   ├── line_badge.dart
│   └── ...
└── theme/
    └── app_theme.dart
```

**Alternatives considered**:
- Riverpod → Rejected: Learning curve, Provider already works
- BLoC → Rejected: Overkill for this app size, more boilerplate

### 4. Map Tiles: Custom Dark Style
**Decision**: Use CartoDB Dark Matter or similar dark-themed tiles.

**Options**:
```dart
// Primary: CartoDB Dark Matter (free, no API key)
'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'

// Fallback: Stamen Toner (free)
'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png'
```

**Rationale**: Matches dark theme, good contrast for markers, free tier sufficient.

### 5. Bottom Sheet: Custom Implementation
**Decision**: Use `DraggableScrollableSheet` with custom snap points.

**Snap Points**:
- Collapsed: 25% of screen (shows station name + 2 arrivals)
- Half: 50% of screen (shows full station info)
- Expanded: 90% of screen (full arrivals list)

**Rationale**: Built-in Flutter widget, no additional dependencies.

### 6. RTL Support
**Decision**: Use Flutter's built-in RTL support with `Directionality` widget.

**Implementation**:
- Wrap app in `Directionality(textDirection: TextDirection.rtl, ...)`
- Use `start`/`end` instead of `left`/`right` in EdgeInsets
- Store language preference in SharedPreferences

### 7. Operator Logos
**Decision**: Bundle SVG logos for major Israeli transit operators.

**Operators**:
- Egged (אגד) - Green
- Dan (דן) - Blue
- Kavim (קווים) - Orange
- Metropoline (מטרופולין) - Purple
- Superbus (סופרבוס) - Red
- Israel Railways (רכבת ישראל) - Blue/Orange

**Storage**: `assets/operators/` folder with SVG files.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Map tiles get blocked | App unusable | Use multiple tile providers with fallback |
| Hebrew text rendering issues | Poor UX | Test extensively on Hebrew content |
| Large refactor breaks existing features | Regression | Keep server_comms.dart stable, add new endpoints |
| Performance on older devices | Slow UI | Use ListView.builder, limit visible markers |

## Migration Plan

1. **Phase 1**: Create new screen files alongside existing ones
2. **Phase 2**: Implement shared widgets and theme
3. **Phase 3**: Build each screen incrementally
4. **Phase 4**: Switch navigation in main.dart to new screens
5. **Phase 5**: Remove old placeholder files
6. **Rollback**: Git revert if critical issues found

## Open Questions

1. **Real-time arrivals**: Does backend support this? Need `/arrivals?station_id=X` endpoint
2. **Line colors**: Should we use operator colors or fixed palette per line type?
3. **Offline mode**: How much data should we cache? All stations? Just favorites?
4. **User accounts**: Future feature or local-only forever?
