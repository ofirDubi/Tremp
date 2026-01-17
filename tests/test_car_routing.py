"""
Tests for the car_routing module.

These tests verify car route calculations and station filtering
using the mocked Valhalla service.
"""

import pytest
import sys
import os
from unittest.mock import patch, MagicMock

# Add source path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'dubi_gtfs_parser'))

from mocks.valhalla_mock import MockValhallaActor, get_mock_actor, reset_mock_actor
from fixtures.gtfs_fixtures import (
    create_mock_timetable,
    create_mock_gtfs,
    MOCK_STATIONS,
    TEST_LOCATIONS
)


class TestGetFasterCarRoute:
    """Tests for the get_faster_car_route function."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment before each test."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_get_faster_car_route_returns_time_and_distance(self, mock_timetable):
        """Test that car route returns time and distance."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_faster_car_route

            start = {"lat": 32.0556, "lon": 34.7818}
            end = {"lat": 32.0750, "lon": 34.7750}

            time, distance = get_faster_car_route(mock_timetable, start, end)

            assert time > 0
            assert distance > 0

    def test_get_faster_car_route_reasonable_values(self, mock_timetable):
        """Test that car route returns reasonable time/distance values."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_faster_car_route

            # About 2.5km distance between these points
            start = {"lat": 32.0556, "lon": 34.7818}  # Central Station
            end = {"lat": 32.0750, "lon": 34.7750}    # Dizengoff

            time, distance = get_faster_car_route(mock_timetable, start, end)

            # Distance should be around 2-3 km
            assert 1000 < distance < 5000, f"Distance {distance}m seems unreasonable"

            # At 40 km/h average, ~2.5km should take about 3-4 minutes
            assert 60 < time < 600, f"Time {time}s seems unreasonable"

    def test_get_faster_car_route_same_location(self, mock_timetable):
        """Test car route for same start and end location."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_faster_car_route

            location = {"lat": 32.0556, "lon": 34.7818}

            time, distance = get_faster_car_route(mock_timetable, location, location)

            assert time < 10
            assert distance < 10

    def test_get_faster_car_route_uses_auto_costing(self, mock_timetable):
        """Test that car routing uses 'auto' costing mode."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_faster_car_route

            start = {"lat": 32.0556, "lon": 34.7818}
            end = {"lat": 32.0750, "lon": 34.7750}

            get_faster_car_route(mock_timetable, start, end)

            # Check the last call used auto costing
            assert self.mock_actor.get_call_count('matrix') == 1
            last_call = self.mock_actor.call_history[-1]
            assert last_call[1]['costing'] == 'auto'


class TestGetPassableStationsWithOneToMany:
    """Tests for the get_passable_stations_with_one_to_many function."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_returns_list_of_valid_stations(self, mock_timetable):
        """Test that function returns list of passable stations."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_passable_stations_with_one_to_many

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            # Use a generous deviation to find stations
            results = get_passable_stations_with_one_to_many(
                mock_timetable,
                start,
                end,
                deviation=60*10,  # 10 minutes
                possible_stations=list(mock_timetable.stations.values())[:5]
            )

            # Should return a list
            assert isinstance(results, list)

    def test_returns_tuple_with_station_and_times(self, mock_timetable):
        """Test that results contain station and time information."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_passable_stations_with_one_to_many

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            results = get_passable_stations_with_one_to_many(
                mock_timetable,
                start,
                end,
                deviation=60*30,  # 30 minutes - very generous
                possible_stations=list(mock_timetable.stations.values())[:3]
            )

            if len(results) > 0:
                # Each result should be (station, time_from_start, time_to_end)
                station, time_from_start, time_to_end = results[0]

                assert "station_id" in station
                assert isinstance(time_from_start, (int, float))
                assert isinstance(time_to_end, (int, float))
                assert time_from_start > 0
                assert time_to_end > 0

    def test_filters_stations_by_deviation(self, mock_timetable):
        """Test that stations are filtered by deviation time."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_passable_stations_with_one_to_many

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            # Very small deviation should return fewer stations
            results_small = get_passable_stations_with_one_to_many(
                mock_timetable,
                start,
                end,
                deviation=60,  # 1 minute
                min_time=300,  # 5 minute direct route
                possible_stations=list(mock_timetable.stations.values())
            )

            # Larger deviation should return same or more stations
            results_large = get_passable_stations_with_one_to_many(
                mock_timetable,
                start,
                end,
                deviation=60*30,  # 30 minutes
                min_time=300,
                possible_stations=list(mock_timetable.stations.values())
            )

            assert len(results_large) >= len(results_small)


class TestGetPassableStations:
    """Tests for the get_passable_stations function (with isochrone filtering)."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_uses_isochrone_for_initial_filtering(self, mock_timetable):
        """Test that isochrone is used for initial station filtering."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_passable_stations

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            get_passable_stations(mock_timetable, start, end, deviation=60*5)

            # Should have called isochrone at least twice (from start and end)
            isochrone_calls = self.mock_actor.get_call_count('isochrone')
            assert isochrone_calls >= 2

    def test_returns_stations_with_time_info(self, mock_timetable):
        """Test that passable stations include time information."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import get_passable_stations

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            results = get_passable_stations(
                mock_timetable,
                start,
                end,
                deviation=60*10  # 10 minutes
            )

            # Results may be empty depending on geometry, but if not empty...
            if len(results) > 0:
                assert len(results[0]) == 3  # (station, time_from_start, time_to_end)


class TestBuildConnectionsForCarRoute:
    """Tests for the build_connections_for_car_route function."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_creates_walking_stations(self, mock_timetable):
        """Test that car route creates start/end walking stations."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import build_connections_for_car_route

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]
            start_time = "08:00:00"

            initial_station_count = len(mock_timetable.stations)

            build_connections_for_car_route(
                mock_timetable,
                start,
                end,
                start_time,
                deviation=60*5
            )

            # Should have added at least 2 new stations (start and end)
            assert len(mock_timetable.stations) >= initial_station_count + 2

    def test_creates_car_route_trips(self, mock_timetable):
        """Test that car route creates trip entries."""
        with patch('car_routing.get_actor', return_value=self.mock_actor):
            from car_routing import build_connections_for_car_route

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]
            start_time = "08:00:00"

            build_connections_for_car_route(
                mock_timetable,
                start,
                end,
                start_time,
                deviation=60*10
            )

            # Should have created car_route trips
            car_trips = [t for t in mock_timetable.trips.keys()
                        if t.startswith("car_route")]
            assert len(car_trips) > 0


class TestCarRoutingWithCustomResponses:
    """Tests using custom mock responses for edge cases."""

    def test_handles_no_valid_stations(self, mock_timetable):
        """Test behavior when no stations are within deviation."""
        # Create actor that returns very long travel times
        custom_responses = {
            "matrix": {
                "sources_to_targets": [
                    [{"time": 100000, "distance": 1000000, "to_index": i, "from_index": 0}
                     for i in range(10)]
                ]
            }
        }
        mock_actor = MockValhallaActor(custom_responses)

        with patch('car_routing.get_actor', return_value=mock_actor):
            from car_routing import get_passable_stations_with_one_to_many

            start = TEST_LOCATIONS["home"]
            end = TEST_LOCATIONS["work"]

            results = get_passable_stations_with_one_to_many(
                mock_timetable,
                start,
                end,
                deviation=60,  # 1 minute - impossible given mock times
                min_time=300,
                possible_stations=list(mock_timetable.stations.values())[:3]
            )

            # Should return empty list when no stations meet criteria
            assert len(results) == 0

    def test_handles_fast_direct_route(self, mock_timetable):
        """Test behavior when direct route is very fast."""
        # Create actor that returns very short direct time
        mock_actor = MockValhallaActor()

        with patch('car_routing.get_actor', return_value=mock_actor):
            from car_routing import get_faster_car_route

            # Same location - should be very fast
            location = TEST_LOCATIONS["home"]

            time, distance = get_faster_car_route(mock_timetable, location, location)

            assert time < 10
            assert distance < 10
