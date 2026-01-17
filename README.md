/* Copyright (C) Ofir Dubi - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Ofir Dubi, 2023
 */

# Tremp

A multimodal transportation routing application that combines public transit (buses, trains) with carpooling/ride-sharing.

## The Problem

Given a driver going from A to B, find the best drop-off location within an X-minute detour such that continuing via public transportation provides the shortest total trip time.

## Technology Stack

**Backend:**
- Python 3.7+
- Falcon (REST API framework)
- Valhalla (routing engine)
- Shapely (geometry)
- Matplotlib (visualization)

**Frontend:**
- Flutter 3.3.4+ (Dart)
- flutter_map
- provider state management

**Data:**
- Israel GTFS feed (bus/train schedules)
- OpenStreetMap via Valhalla

## Project Structure

```
src/
  dubi_gtfs_parser/          # Core Python backend
    parse_gtfs.py            # GTFS parser for public transit data
    connection_builder.py    # Timetable construction, SearchableStations spatial index
    raptor_routing.py        # ULTRA-RAPTOR implementation with walking
    car_routing.py           # Car route integration with isochrones
    valhalla_interface.py    # Valhalla routing engine wrapper (singleton)
    display.py               # Matplotlib visualization
    artifacts/               # Cached parsed data (pickled timetables)
  server/
    tremp_server_wsgi.py     # Falcon WSGI server entry point
    tremp_server_rest.py     # REST API endpoints
  is_gtfs/                   # Israel GTFS data files (not in repo)
tremp_app/                   # Flutter mobile/web app
  lib/
    main.dart                # App entry point
    myMap.dart               # Map UI with flutter_map
    server_comms.dart        # Server API client
```

## Running the Application

### Python Server

```bash
python src/server/tremp_server_wsgi.py
```

Server will start on `127.0.0.1:8000`.

### Flutter App

```bash
cd tremp_app
flutter pub get
flutter run
```

### Generate Valhalla Tiles (rarely needed)

1. Put `israel-and-palestine-latest.osm.pbf` in `custom_files`
2. Run:
```bash
docker run --rm -dt --name valhalla_gis-ops -p 8002:8002 -v %cd%/custom_files:/custom_files ghcr.io/gis-ops/docker-valhalla/valhalla:latest
```

See: https://github.com/gis-ops/docker-valhalla

## Core Architecture

### RAPTOR Routing Algorithm

The routing engine uses ULTRA-RAPTOR (Round-based Algorithm for Public Transit Optimization and Routing):

1. One-to-many walking queries from start location to all reachable stations
2. Round-based exploration of transit connections
3. Footpath relaxation between nearby stations (1km radius)
4. Many-to-one walking queries from stations to destination

### Car Route Integration Algorithm

1. Find fastest car route A->B (time X)
2. Generate isochrones from A and B within X minutes
3. One-to-many and many-to-one queries to prune stations outside deviation threshold
4. Insert car route as "virtual bus line" into timetable
5. Run RAPTOR with car route as an option

### Key Constants

- `FOOTPATH_ID = "footpath"` - Walking connections
- `CAR_ROUTE_ID = "car_route"` - Car route connections

## Known Limitations

- Only works on TLV (Tel Aviv) network currently
- Walk time calculation for all stations is inefficient
- Memory error on full reparse at `build_station_footpaths`
- Ugly wrap-around fix for 24H clock handling
- One-to-many car routing queries are slow (known optimization opportunity)

## External Data (not in repo)

- Israel GTFS data files in `src/is_gtfs/`
- Valhalla routing tiles

## References

- [ULTRA-RAPTOR lecture](https://www.youtube.com/watch?v=AdArDN4E6Hg&t=1s&ab_channel=DFG-FOR2083)
- [ULTRA RAPTOR implementation](https://github.com/kit-algo/ULTRA)

## Development Log

See [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) for the full development journal.
