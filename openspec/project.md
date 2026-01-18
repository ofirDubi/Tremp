# Project Context

## Purpose
Tremp is a multimodal transportation routing application that combines public transit (buses, trains) with carpooling/ride-sharing. The core problem: given a driver going from A to B, find the best drop-off location within an X-minute detour such that continuing via public transportation provides the shortest total trip time.

**Goals:**
- Optimize combined car + transit routes for carpooling scenarios
- Provide fast routing using ULTRA-RAPTOR algorithm
- Support the Tel Aviv metropolitan transit network
- Offer mobile-first user experience

## Tech Stack

### Backend (Python)
- **Python 3.7+** - Core language
- **Falcon** - REST API framework (WSGI)
- **Valhalla** - OpenStreetMap routing engine (via Docker)
- **Shapely** - Geometry operations for spatial queries
- **Matplotlib** - Route visualization and debugging
- **Pickle** - Timetable serialization/caching

### Frontend (Flutter)
- **Flutter 3.3.4+** - Cross-platform mobile/web framework
- **Dart** - Frontend language
- **flutter_map** - OpenStreetMap map widget
- **provider** - State management

### Data
- **Israel GTFS feed** - Public transit schedules (buses, trains)
- **OpenStreetMap** - Road network via Valhalla tiles

## Project Conventions

### Code Style
- **Python:** Standard PEP 8 conventions
- **Dart/Flutter:** Default Flutter formatting (`dart format`)
- **Naming:**
  - Python: `snake_case` for functions/variables, `PascalCase` for classes
  - Dart: `camelCase` for functions/variables, `PascalCase` for classes
- **Comments:** Minimal - prefer self-documenting code

### Architecture Patterns

**Backend:**
- Singleton pattern for Valhalla interface (`valhalla_interface.py`)
- Spatial bucketing for station lookups (`SearchableStations` in `connection_builder.py`)
- Round-based RAPTOR algorithm for transit routing
- Pickle-based artifact caching for parsed GTFS data

**Frontend:**
- Provider-based state management
- Separation of UI (`myMap.dart`) and API communication (`server_comms.dart`)
- Bottom navigation with 5 main tabs (Explore, Commute, Saved, Contribute, Updates)

### Testing Strategy
- **Manual testing:** Primary approach currently
- **Android emulator testing:** Automated UI testing via mobile-mcp
- **API testing:** Direct HTTP requests to server endpoints
- No formal unit test suite yet

### Git Workflow
- **Main branch:** `main`
- **Commit style:** Conventional commits preferred (`feat:`, `fix:`, `chore:`)
- **Co-authoring:** Include `Co-Authored-By: Claude` for AI-assisted commits

## Domain Context

### RAPTOR Algorithm
The routing engine uses ULTRA-RAPTOR (Round-based Algorithm for Public Transit Optimization and Routing):
1. One-to-many walking queries from start location to all reachable stations
2. Round-based exploration of transit connections
3. Footpath relaxation between nearby stations (1km radius)
4. Many-to-one walking queries from stations to destination

### Car Route Integration
1. Find fastest car route A→B (time X)
2. Generate isochrones from A and B within X minutes
3. One-to-many and many-to-one queries to prune stations outside deviation threshold
4. Insert car route as "virtual bus line" into timetable
5. Run RAPTOR with car route as an option

### Key Domain Terms
- **Tremp** - Hebrew slang for hitchhiking/carpooling
- **GTFS** - General Transit Feed Specification (standard format for transit data)
- **Isochrone** - Area reachable within a given time from a point
- **Footpath** - Walking connection between nearby stations

### Key Constants
- `FOOTPATH_ID = "footpath"` - Walking connections marker
- `CAR_ROUTE_ID = "car_route"` - Car route connections marker

## Important Constraints

### Technical Constraints
- **Geographic scope:** Currently only works on Tel Aviv (TLV) network
- **Memory:** Full GTFS reparse can cause memory errors at `build_station_footpaths`
- **Performance:** One-to-many car routing queries are slow (optimization opportunity)
- **Clock handling:** Workaround in place for 24H wrap-around edge cases

### Data Requirements
- Israel GTFS data files must be present in `src/is_gtfs/`
- Valhalla tiles must be generated and available (Docker container on port 8002)
- Cached artifacts in `src/dubi_gtfs_parser/artifacts/` for fast startup

### Business Constraints
- **License:** Proprietary - Copyright (C) Ofir Dubi - All Rights Reserved

## External Dependencies

### Valhalla Routing Engine
- **Purpose:** Car routing, walking queries, isochrone generation
- **Access:** Docker container (`ghcr.io/gis-ops/docker-valhalla/valhalla`)
- **Port:** 8002
- **Data:** Requires OSM PBF file (israel-and-palestine-latest.osm.pbf)

### Israel GTFS Feed
- **Purpose:** Public transit schedules and stop locations
- **Source:** Israel Ministry of Transport
- **Location:** `src/is_gtfs/` (not in repo due to size)
- **Files needed:** stops.txt, stop_times.txt, trips.txt, routes.txt, calendar.txt

### OpenStreetMap Tile Servers
- **Purpose:** Map display in Flutter app
- **Note:** Default OSM tile server may block requests; consider using a commercial provider or self-hosted tiles for production
