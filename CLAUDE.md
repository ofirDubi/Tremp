<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tremp is a multimodal transportation routing application that combines public transit (buses, trains) with carpooling/ride-sharing. The core problem: given a driver going from A to B, find the best drop-off location within an X-minute detour such that continuing via public transportation provides the shortest total trip time.

## Technology Stack

**Backend:** Python 3.7+, Falcon (REST), Valhalla (routing engine), Shapely (geometry), Matplotlib (visualization)

**Frontend:** Flutter 3.3.4+ (Dart), flutter_map, provider state management

**Data:** Israel GTFS feed (bus/train schedules), OpenStreetMap via Valhalla

## Project Structure

```
src/
├── dubi_gtfs_parser/          # Core Python backend
│   ├── parse_gtfs.py          # GTFS parser for public transit data
│   ├── connection_builder.py  # Timetable construction, SearchableStations spatial index
│   ├── raptor_routing.py      # ULTRA-RAPTOR implementation with walking
│   ├── car_routing.py         # Car route integration with isochrones
│   ├── valhalla_interface.py  # Valhalla routing engine wrapper (singleton)
│   ├── display.py             # Matplotlib visualization
│   └── artifacts/             # Cached parsed data (pickled timetables)
├── server/
│   ├── tremp_server_wsgi.py   # Falcon WSGI server entry point
│   └── tremp_server_rest.py   # REST API endpoints
└── is_gtfs/                   # Israel GTFS data files
tremp_app/                     # Flutter mobile/web app
    └── lib/
        ├── main.dart          # App entry point
        ├── myMap.dart         # Map UI with flutter_map
        └── server_comms.dart  # Server API client
```

## Running the Application

**Python server:**
```bash
python src/server/tremp_server_wsgi.py
```

**Flutter app:**
```bash
cd tremp_app
flutter pub get
flutter run
```

**Generate Valhalla tiles (rarely needed):**
```bash
# Put israel-and-palestine-latest.osm.pbf in custom_files, then:
docker run --rm -dt --name valhalla_gis-ops -p 8002:8002 -v %cd%/custom_files:/custom_files ghcr.io/gis-ops/docker-valhalla/valhalla:latest
```

## Core Architecture

### RAPTOR Routing Algorithm
The routing engine uses ULTRA-RAPTOR (Round-based Algorithm for Public Transit Optimization and Routing):
1. One-to-many walking queries from start location to all reachable stations
2. Round-based exploration of transit connections
3. Footpath relaxation between nearby stations (1km radius)
4. Many-to-one walking queries from stations to destination

### Car Route Integration Algorithm
1. Find fastest car route A→B (time X)
2. Generate isochrones from A and B within X minutes
3. One-to-many and many-to-one queries to prune stations outside deviation threshold
4. Insert car route as "virtual bus line" into timetable
5. Run RAPTOR with car route as an option

### SearchableStations Spatial Index
`connection_builder.py` implements spatial bucketing for efficient station lookups:
- X-axis: 100m buckets sorted by longitude
- Y-axis: Each bucket sorted by latitude
- Binary search for radius queries

### Key Constants
- `FOOTPATH_ID = "footpath"` - Walking connections
- `CAR_ROUTE_ID = "car_route"` - Car route connections

## Mobile Testing with MCP

The project uses mobile-mcp for Android emulator automation. Key tools:

- `mobile_list_available_devices` - Find running emulators (device ID: `emulator-5554`)
- `mobile_take_screenshot` - Capture screen state
- `mobile_list_elements_on_screen` - Get UI element coordinates and labels
- `mobile_click_on_screen_at_coordinates` - Tap specific coordinates
- `mobile_swipe_on_screen` - Perform swipe gestures

**Testing workflow:**
1. Start emulator: `"%LOCALAPPDATA%\Android\sdk\emulator\emulator" -avd <AVD_NAME>`
2. Start server: `python src/server/tremp_server_wsgi.py`
3. Run app: `cd tremp_app && flutter run`
4. Use MCP tools to interact with the app

**Navigation tabs** (bottom bar, y≈2077):
- Explore (x=108): Map view with search
- Commute (x=324): Saved routes list
- Saved (x=540): Saved locations
- Contribute (x=756): User contributions
- Updates (x=972): App updates

## Important Implementation Notes

**Hardcoded paths in `utils.py`:** Paths are now relative using `os.path.dirname(__file__)`. Previously hardcoded to `D:\Projects\Tremp\src`.

**External dependencies not in repo:**
- Israel GTFS data files in `src/is_gtfs/`
- Valhalla routing tiles

**Performance considerations:**
- Timetable objects are large; use pickle serialization in `artifacts/`
- Routing operations can take 2-3 seconds
- One-to-many car routing queries are slow (known optimization opportunity)

**Known limitations (from README):**
- Only works on TLV (Tel Aviv) network currently
- Walk time calculation for all stations is inefficient
- Memory error on full reparse at `build_station_footpaths`
- Ugly wrap-around fix for 24H clock handling

## License

Copyright (C) Ofir Dubi - All Rights Reserved. Proprietary and confidential.
