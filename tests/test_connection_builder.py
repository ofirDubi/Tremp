"""
Tests for the connection_builder module.

These tests verify the Timetable construction, Connection class,
and SearchableStations functionality.
"""

import pytest
import sys
import os

# Add source path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'dubi_gtfs_parser'))

from fixtures.gtfs_fixtures import (
    create_mock_gtfs,
    create_mock_timetable,
    MOCK_STATIONS,
    MOCK_TRIPS,
    MOCK_STOP_TIMES,
    TEST_LOCATIONS
)
from mocks.valhalla_mock import MockValhallaActor, reset_mock_actor


class TestConnection:
    """Tests for the Connection class."""

    def test_connection_creation(self):
        """Test basic Connection object creation."""
        from connection_builder import Connection

        conn = Connection(
            departure_stop="station_1",
            arrival_stop="station_2",
            departure_time="08:00:00",
            arrival_time="08:10:00",
            trip_id="trip_1"
        )

        assert conn.departure_stop == "station_1"
        assert conn.arrival_stop == "station_2"
        assert conn.departure_time == "08:00:00"
        assert conn.arrival_time == "08:10:00"
        assert conn.trip_id == "trip_1"
        assert conn.shapes is None

    def test_connection_requires_string_times(self):
        """Test that Connection raises error for non-string times."""
        from connection_builder import Connection

        with pytest.raises(AssertionError):
            Connection(
                departure_stop="station_1",
                arrival_stop="station_2",
                departure_time=800,  # Should be string
                arrival_time="08:10:00",
                trip_id="trip_1"
            )

    def test_connection_repr(self):
        """Test Connection string representation."""
        from connection_builder import Connection

        conn = Connection(
            departure_stop="station_1",
            arrival_stop="station_2",
            departure_time="08:00:00",
            arrival_time="08:10:00",
            trip_id="trip_1"
        )

        repr_str = repr(conn)
        assert "station_1" in repr_str
        assert "station_2" in repr_str
        assert "08:00:00" in repr_str


class TestSearchableStations:
    """Tests for the SearchableStations class."""

    def test_searchable_stations_creation(self):
        """Test SearchableStations initialization."""
        from connection_builder import SearchableStations

        stations = list(MOCK_STATIONS.values())
        ss = SearchableStations(stations, BUCKET_SIZE=100)

        assert ss.BUCKET_SIZE == 100
        assert ss.sorted_stations is not None
        assert len(ss.sorted_stations) > 0

    def test_search_nearby_stations_finds_close_stations(self):
        """Test that nearby station search returns expected results."""
        from connection_builder import SearchableStations

        stations = list(MOCK_STATIONS.values())
        ss = SearchableStations(stations, BUCKET_SIZE=100)

        # Search near Dizengoff Center
        center_station = MOCK_STATIONS["station_2"]
        nearby = ss.search_nearby_stations(center_station, radius=1000)

        # Should find at least a few stations within 1km
        assert len(nearby) > 0

        # Should include the center station itself
        center_ids = [s["station_id"] for s in nearby]
        assert "station_2" in center_ids

    def test_search_nearby_stations_radius_filtering(self):
        """Test that larger radius returns more stations."""
        from connection_builder import SearchableStations

        stations = list(MOCK_STATIONS.values())
        ss = SearchableStations(stations, BUCKET_SIZE=100)

        center_station = MOCK_STATIONS["station_7"]  # Habima Square

        nearby_500 = ss.search_nearby_stations(center_station, radius=500)
        nearby_2000 = ss.search_nearby_stations(center_station, radius=2000)

        # Larger radius should find at least as many stations
        assert len(nearby_2000) >= len(nearby_500)

    def test_search_returns_empty_for_distant_point(self):
        """Test that search returns empty for point far from all stations."""
        from connection_builder import SearchableStations

        stations = list(MOCK_STATIONS.values())
        ss = SearchableStations(stations, BUCKET_SIZE=100)

        # Create a station far away (somewhere in Eilat)
        distant_station = {
            "station_id": "distant",
            "stop_lat": 29.5581,
            "stop_lon": 34.9482,
            "stop_name": "Eilat"
        }

        # Search with small radius
        nearby = ss.search_nearby_stations(distant_station, radius=1000)

        assert len(nearby) == 0


class TestMockTimetable:
    """Tests for the mock Timetable object."""

    def test_mock_timetable_has_stations(self, mock_timetable):
        """Test that mock timetable contains stations."""
        assert len(mock_timetable.stations) > 0
        assert "station_1" in mock_timetable.stations

    def test_mock_timetable_has_trips(self, mock_timetable):
        """Test that mock timetable contains trips."""
        assert len(mock_timetable.trips) > 0
        assert "trip_1_morning" in mock_timetable.trips
        assert "footpath" in mock_timetable.trips

    def test_mock_timetable_has_station_connections(self, mock_timetable):
        """Test that mock timetable has station connections."""
        assert len(mock_timetable.station_connections) > 0

        # Central Station should have connections for trip_1
        assert "station_1" in mock_timetable.station_connections

    def test_mock_timetable_has_trip_connections(self, mock_timetable):
        """Test that mock timetable has trip connections."""
        assert len(mock_timetable.trip_connections) > 0
        assert "trip_1_morning" in mock_timetable.trip_connections

    def test_mock_timetable_connections_are_ordered(self, mock_timetable):
        """Test that connections for a trip are in order."""
        trip_connections = mock_timetable.trip_connections["trip_1_morning"]

        assert len(trip_connections) > 0

        # Verify connections are in sequence (each arrival = next departure)
        for i in range(len(trip_connections) - 1):
            assert trip_connections[i].arrival_stop == trip_connections[i + 1].departure_stop

    def test_mock_timetable_has_footpaths(self, mock_timetable):
        """Test that mock timetable has station footpaths."""
        assert hasattr(mock_timetable, 'stations_footpaths')
        assert len(mock_timetable.stations_footpaths) > 0

    def test_mock_timetable_create_walking_station(self, mock_timetable):
        """Test creating a walking station."""
        new_station = mock_timetable._create_walking_station(
            {"lat": 32.0800, "lon": 34.7800},
            name="Test"
        )

        assert new_station["station_id"].startswith("Test_")
        assert new_station["stop_lat"] == 32.0800
        assert new_station["stop_lon"] == 34.7800
        assert new_station["station_id"] in mock_timetable.stations


class TestMockGTFS:
    """Tests for the MockGTFS class."""

    def test_mock_gtfs_creation(self, mock_gtfs):
        """Test basic MockGTFS creation."""
        assert mock_gtfs is not None
        assert len(mock_gtfs.stations) > 0
        assert len(mock_gtfs.routes) > 0
        assert len(mock_gtfs.trips) > 0
        assert len(mock_gtfs.stop_times) > 0

    def test_mock_gtfs_stations_have_required_fields(self, mock_gtfs):
        """Test that stations have all required fields."""
        for station_id, station in mock_gtfs.stations.items():
            assert "station_id" in station
            assert "stop_name" in station
            assert "stop_lat" in station
            assert "stop_lon" in station

    def test_mock_gtfs_trips_reference_valid_routes(self, mock_gtfs):
        """Test that trips reference existing routes."""
        for trip_id, trip in mock_gtfs.trips.items():
            route_id = trip["route_id"]
            # Allow special pseudo-routes
            if route_id not in ["footpath", "car_route"]:
                assert route_id in mock_gtfs.routes

    def test_mock_gtfs_stop_times_reference_valid_stations(self, mock_gtfs):
        """Test that stop times reference existing stations."""
        for trip_id, stop_times in mock_gtfs.stop_times.items():
            for stop_time in stop_times:
                assert stop_time["station_id"] in mock_gtfs.stations

    def test_mock_gtfs_match_stops_to_shapes(self, mock_gtfs):
        """Test the match_stops_to_shapes_for_trip method."""
        result = mock_gtfs.match_stops_to_shapes_for_trip("trip_1_morning")

        assert len(result) > 0

        for stop in result:
            assert "station_id" in stop
            assert "shapes" in stop
            assert len(stop["shapes"]) > 0

    def test_mock_gtfs_custom_stations(self):
        """Test creating MockGTFS with custom stations."""
        custom_stations = {
            "custom_1": {
                "station_id": "custom_1",
                "stop_name": "Custom Station",
                "stop_lat": 32.0,
                "stop_lon": 34.0,
                "stop_code": "C001"
            }
        }

        gtfs = create_mock_gtfs(stations=custom_stations)

        assert "custom_1" in gtfs.stations
        assert gtfs.stations["custom_1"]["stop_name"] == "Custom Station"


class TestTimetableIntegration:
    """Integration tests for Timetable with mocked Valhalla."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Reset mock actor before each test."""
        reset_mock_actor()

    def test_timetable_station_lookup(self, mock_timetable):
        """Test looking up stations by ID."""
        station = mock_timetable.stations.get("station_1")

        assert station is not None
        assert station["stop_name"] == "Central Station"

    def test_connection_chain_for_route(self, mock_timetable):
        """Test that connections form valid chains."""
        trip_id = "trip_1_morning"
        connections = mock_timetable.trip_connections[trip_id]

        # Route 1: Central -> Dizengoff -> Rabin -> Reading
        expected_stops = ["station_1", "station_2", "station_3", "station_4"]

        actual_stops = [connections[0].departure_stop]
        for conn in connections:
            actual_stops.append(conn.arrival_stop)

        assert actual_stops == expected_stops

    def test_footpath_between_nearby_stations(self, mock_timetable):
        """Test that footpaths exist between nearby stations."""
        # Check that some stations have footpath connections
        has_footpaths = False
        for station_id, footpaths in mock_timetable.stations_footpaths.items():
            if len(footpaths) > 0:
                has_footpaths = True
                # Verify footpath structure
                assert "station_id" in footpaths[0]
                assert "time" in footpaths[0]
                assert "distance" in footpaths[0]
                break

        assert has_footpaths, "No footpaths found between any stations"
