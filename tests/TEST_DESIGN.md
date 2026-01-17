# Tremp Test Design Document

## Overview

This document describes the test architecture for the Tremp multi-modal transit routing application. The test suite is designed to allow full testing of the routing algorithms without requiring external services (Valhalla) or real GTFS data.

## Architecture

### Test Structure

```
tests/
├── __init__.py                    # Test package init
├── conftest.py                    # Pytest configuration and shared fixtures
├── TEST_DESIGN.md                 # This document
├── mocks/
│   ├── __init__.py
│   └── valhalla_mock.py           # Mock Valhalla routing service
├── fixtures/
│   ├── __init__.py
│   └── gtfs_fixtures.py           # Mock GTFS data and Timetable fixtures
├── test_valhalla_mock.py          # Tests for the mock itself
├── test_connection_builder.py     # Tests for connection_builder module
├── test_car_routing.py            # Tests for car_routing module
└── test_raptor_routing.py         # Tests for raptor_routing module
```

## Server Mock Design

### MockValhallaActor

The `MockValhallaActor` class in `mocks/valhalla_mock.py` provides a complete mock implementation of the Valhalla routing service API. It simulates three main API methods:

#### 1. `matrix(query)` - Distance Matrix API
- Calculates one-to-many and many-to-many routing distances
- Uses Haversine formula for distance calculation
- Estimates travel time based on transport mode (auto/pedestrian)
- Returns realistic response format with `sources_to_targets` structure

**Mock Response Format:**
```python
{
    "sources_to_targets": [
        [
            {"time": 345, "distance": 2500, "to_index": 0, "from_index": 0},
            {"time": 567, "distance": 4200, "to_index": 1, "from_index": 0}
        ]
    ]
}
```

#### 2. `isochrone(query)` - Travel Time Polygon API
- Generates simplified circular polygons based on travel time
- Supports multiple time contours
- Returns GeoJSON-compatible polygon features

**Mock Response Format:**
```python
{
    "features": [
        {
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [[lon, lat], ...]
            },
            "properties": {"contour": 5, "color": "ff0000"}
        }
    ]
}
```

#### 3. `optimized_route(query)` - Point-to-Point Routing API
- Generates routes between waypoints
- Includes encoded polyline shapes
- Calculates leg summaries with time and distance

**Mock Response Format:**
```python
{
    "trip": {
        "legs": [
            {
                "shape": "encoded_polyline_string",
                "summary": {"time": 300, "length": 2.5}
            }
        ]
    }
}
```

### Key Features

1. **Deterministic Results**: Uses mathematical calculations (Haversine) for predictable test results
2. **Call History Tracking**: Records all API calls for test assertions
3. **Custom Response Injection**: Allows tests to inject specific responses for edge cases
4. **Singleton Pattern**: Matches the real `get_actor()` pattern for easy patching

## GTFS Fixtures

### MockGTFS Class

Located in `fixtures/gtfs_fixtures.py`, provides a complete mock transit network:

#### Mock Network Topology

```
Central Station (1) ──[Route 5]──> Dizengoff (2) ──> Rabin Sq (3) ──> Reading (4)
                                        │
Carmel Market (5) ──[Route 18]──> Rothschild (6) ──> Habima (7) ──> Museum (8)
                                        │
                              [Route 25] │
                                        V
                                   Sarona (9) ──────────> Azrieli (10)
```

#### Mock Data Contents

| Data Type | Count | Description |
|-----------|-------|-------------|
| Stations | 10 | Transit stations in Tel Aviv area |
| Routes | 3 | Bus routes (5, 18, 25) |
| Trips | 8 | Scheduled trip instances |
| Stop Times | ~20 | Departure/arrival times per trip |
| Shapes | 1 | Route polyline coordinates |

### Mock Timetable

The `create_mock_timetable()` function creates a Timetable-like object with:
- Pre-built station connections from stop times
- Trip connections for route following
- Station footpaths (walking connections between nearby stations)
- Helper methods for walking station creation

## Test Categories

### Unit Tests

1. **test_valhalla_mock.py**
   - Matrix API response format
   - Isochrone polygon generation
   - Route shape encoding
   - Distance/time calculations
   - Call history tracking

2. **test_connection_builder.py**
   - Connection class creation and validation
   - SearchableStations spatial indexing
   - Timetable construction
   - Station footpath building

3. **test_car_routing.py**
   - Fast car route calculation
   - Station filtering by deviation
   - Isochrone-based pruning
   - Car route connection building

4. **test_raptor_routing.py**
   - RAPTOR algorithm execution
   - Walking station creation
   - Footpath relaxation
   - Route result construction

### Integration Tests

Tests marked with `@pytest.mark.integration` verify end-to-end workflows:
- Complete routing from start to end location
- Combined car + transit routing
- Multi-modal journey planning

## Running Tests

### Basic Usage

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_valhalla_mock.py

# Run specific test class
pytest tests/test_connection_builder.py::TestSearchableStations

# Run tests matching pattern
pytest -k "matrix"

# Skip slow tests
pytest -m "not slow"
```

### Test Markers

- `@pytest.mark.unit` - Fast unit tests
- `@pytest.mark.integration` - Integration tests
- `@pytest.mark.slow` - Tests that may take longer

## Mocking Strategy

### Patching Valhalla

```python
from unittest.mock import patch
from mocks.valhalla_mock import MockValhallaActor

def test_something(mock_timetable):
    mock_actor = MockValhallaActor()

    with patch('module.get_actor', return_value=mock_actor):
        # Test code that uses Valhalla
        result = function_under_test(mock_timetable)

    # Verify API was called correctly
    assert mock_actor.get_call_count('matrix') == 1
```

### Using Fixtures

```python
def test_with_timetable(mock_timetable, mock_gtfs):
    # mock_timetable has pre-built connections
    assert "station_1" in mock_timetable.stations

    # mock_gtfs has raw GTFS data
    assert len(mock_gtfs.routes) == 3
```

### Custom Responses

```python
def test_edge_case(mock_valhalla_actor_with_custom_responses):
    actor = mock_valhalla_actor_with_custom_responses({
        'matrix': {
            'sources_to_targets': [[{'time': 99999, 'distance': 100000}]]
        }
    })

    # Test with custom response
```

## Test Data Locations

The mock data represents the Tel Aviv area:

| Location | Lat | Lon | Description |
|----------|-----|-----|-------------|
| home | 32.0600 | 34.7700 | Near Carmel Market |
| work | 32.0740 | 34.7920 | Azrieli Center |
| downtown | 32.0750 | 34.7750 | Dizengoff area |
| north | 32.0950 | 34.7900 | Reading Terminal |
| south | 32.0556 | 34.7818 | Central Station |

## Adding New Tests

### For New Features

1. Add mock data to `fixtures/gtfs_fixtures.py` if needed
2. Extend mock methods in `mocks/valhalla_mock.py` if needed
3. Create test file `tests/test_<feature>.py`
4. Use existing fixtures from `conftest.py`

### Test Template

```python
import pytest
import sys
import os
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'dubi_gtfs_parser'))

from mocks.valhalla_mock import MockValhallaActor, reset_mock_actor
from fixtures.gtfs_fixtures import create_mock_timetable

class TestNewFeature:
    @pytest.fixture(autouse=True)
    def setup(self):
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_feature_basic(self, mock_timetable):
        with patch('module.get_actor', return_value=self.mock_actor):
            # Test implementation
            pass
```

## Coverage Goals

- Aim for >80% code coverage on core routing modules
- 100% coverage on critical path calculations
- Edge cases: empty results, time wrapping, invalid inputs

## Notes

- Tests do not require real Valhalla installation
- Tests do not require GTFS data files
- All tests should complete in under 30 seconds total
- Use `pytest --tb=short` for cleaner error output
