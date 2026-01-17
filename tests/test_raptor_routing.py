"""
Tests for the raptor_routing module.

These tests verify the RAPTOR routing algorithm, RaptorResult class,
and the integration with car routing.
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
    MOCK_STOP_TIMES,
    TEST_LOCATIONS
)


class TestRVisidetStation:
    """Tests for the RVisidetStation dataclass."""

    def test_rvisited_station_creation(self):
        """Test basic RVisidetStation creation."""
        from raptor_routing import RVisidetStation

        rvs = RVisidetStation(
            arrival_time=28800,  # 08:00:00 in seconds
            leading_connections=[],
            walking_arrival_time_to_end=29400  # 08:10:00
        )

        assert rvs.arrival_time == 28800
        assert rvs.leading_connections == []
        assert rvs.walking_arrival_time_to_end == 29400


class TestRaptorResultV2:
    """Tests for RaptorResult_v2 class."""

    @pytest.fixture
    def mock_connection(self):
        """Create a mock connection for testing."""
        conn = MagicMock()
        conn.departure_time = "08:00:00"
        conn.arrival_time = "08:10:00"
        conn.departure_stop = "station_1"
        conn.arrival_stop = "station_2"
        conn.trip_id = "trip_1"
        return conn

    def test_raptor_result_calculates_trip_time(self, mock_timetable, mock_connection):
        """Test that RaptorResult calculates trip time correctly."""
        from raptor_routing import RaptorResult_v2

        # Create a simple result route
        mock_end_conn = MagicMock()
        mock_end_conn.departure_time = "08:10:00"
        mock_end_conn.arrival_time = "08:20:00"
        mock_end_conn.departure_stop = "station_2"
        mock_end_conn.arrival_stop = "station_3"
        mock_end_conn.trip_id = "trip_1"

        # Mock bus_line_from_trip_id
        with patch('raptor_routing.bus_line_from_trip_id', return_value="5"):
            result_route = [
                ("station_2", [mock_connection]),
                ("station_3", [mock_end_conn])
            ]

            result = RaptorResult_v2(result_route, mock_timetable)

            assert result.departure_time == "08:00:00"
            assert result.arrival_time == "08:20:00"
            assert result.trip_time == 20  # 20 minutes


class TestRaptorRouter:
    """Tests for the RaptorRouter class."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_raptor_router_initialization(self, mock_timetable):
        """Test RaptorRouter initialization."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            from raptor_routing import RaptorRouter

            router = RaptorRouter(mock_timetable)

            assert router.tt == mock_timetable
            assert router.actor == self.mock_actor

    def test_get_stations_as_locations(self, mock_timetable):
        """Test _get_stations_as_locations returns correct format."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            from raptor_routing import RaptorRouter

            router = RaptorRouter(mock_timetable)
            locations = router._get_stations_as_locations()

            assert isinstance(locations, list)
            assert len(locations) > 0

            # Each location should have lat/lon
            for loc in locations:
                assert "lat" in loc
                assert "lon" in loc

    def test_get_walking_start_end_results(self, mock_timetable):
        """Test walking path calculation."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            # Patch file operations to avoid actual file I/O
            with patch('os.path.isfile', return_value=False):
                with patch('raptor_routing.utils.save_artifact'):
                    from raptor_routing import RaptorRouter

                    router = RaptorRouter(mock_timetable)

                    start = {"lat": 32.0600, "lon": 34.7700}
                    end = {"lat": 32.0750, "lon": 34.7750}

                    sorted_start, end_footpaths = router._get_walking_start_end_results(
                        start, end, reparse=True
                    )

                    # Should return sorted results
                    assert isinstance(sorted_start, list)
                    assert len(sorted_start) > 0

                    # Results should be sorted by time
                    times = [s["time"] for s in sorted_start]
                    assert times == sorted(times)

                    # End footpaths should have sources_to_targets
                    assert "sources_to_targets" in end_footpaths


class TestRaptorRoute:
    """Tests for the raptor_route function."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_raptor_route_returns_results(self, mock_timetable):
        """Test that raptor_route returns result structure."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            from raptor_routing import raptor_route

            # Build end footpath connections mock
            end_footpath_connections = {
                "sources_to_targets": [
                    [{"time": 300, "from_index": i}]  # 5 minutes walking
                    for i in range(len(mock_timetable.stations))
                ]
            }

            results = raptor_route(
                start_station="station_1",
                end_station="station_4",
                start_time="08:00:00",
                tt=mock_timetable,
                end_footpath_connections=end_footpath_connections,
                relax_footpaths=False,
                debug=False
            )

            # Should return a list of round results
            assert isinstance(results, list)

    def test_raptor_route_respects_time_limit(self, mock_timetable):
        """Test that raptor respects walking time limit."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            from raptor_routing import raptor_route

            end_footpath_connections = {
                "sources_to_targets": [
                    [{"time": 7200, "from_index": i}]  # 2 hours - beyond limit
                    for i in range(len(mock_timetable.stations))
                ]
            }

            results = raptor_route(
                start_station="station_1",
                end_station="station_4",
                start_time="08:00:00",
                tt=mock_timetable,
                end_footpath_connections=end_footpath_connections,
                relax_footpaths=False,
                limit_walking_time=3600,  # 1 hour limit
                debug=False
            )

            # Results structure should still be returned
            assert isinstance(results, list)


class TestTraverseStation:
    """Tests for the _traverse_station helper function."""

    def test_traverse_station_builds_route(self):
        """Test that _traverse_station correctly builds a route."""
        from raptor_routing import _traverse_station, RVisidetStation
        from connection_builder import Connection

        # Create mock visited stations
        conn1 = Connection("station_1", "station_2", "08:00:00", "08:10:00", "trip_1")
        conn2 = Connection("station_2", "station_3", "08:10:00", "08:20:00", "trip_1")

        visited_stations = {
            "station_1": RVisidetStation(28800, [], 29400),  # Start
            "station_2": RVisidetStation(29400, [conn1], 30000),  # 08:10
            "station_3": RVisidetStation(30000, [conn1, conn2], 30600),  # 08:20
        }

        result = _traverse_station(
            station_to_traverse="station_3",
            visited_stations=visited_stations,
            end_station="station_4",
            start_station="station_1"
        )

        # Result should be a list of (station, connections) tuples
        assert isinstance(result, list)
        assert len(result) > 0

        # Last entry should be the end station
        assert result[-1][0] == "station_4"


class TestSemiUltraRoute:
    """Tests for the semi_ultra_route method."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_semi_ultra_route_creates_walking_stations(self, mock_timetable):
        """Test that semi_ultra_route creates start/end walking stations."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            with patch('os.path.isfile', return_value=False):
                with patch('raptor_routing.utils.save_artifact'):
                    from raptor_routing import RaptorRouter

                    router = RaptorRouter(mock_timetable)

                    initial_stations = len(mock_timetable.stations)

                    start = {"stop_lat": 32.0600, "stop_lon": 34.7700}
                    end = {"stop_lat": 32.0750, "stop_lon": 34.7750}

                    router.semi_ultra_route(
                        start_location=start,
                        end_location=end,
                        start_time="08:00:00",
                        tt=mock_timetable,
                        car_route=False,
                        relax_footpaths=False,
                        debug=False,
                        limit_walking_time=3600
                    )

                    # Should have created at least 2 new stations (start and end)
                    assert len(mock_timetable.stations) >= initial_stations + 2

    def test_semi_ultra_route_creates_walking_connections(self, mock_timetable):
        """Test that walking connections are created from start."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            with patch('os.path.isfile', return_value=False):
                with patch('raptor_routing.utils.save_artifact'):
                    from raptor_routing import RaptorRouter

                    router = RaptorRouter(mock_timetable)

                    start = {"stop_lat": 32.0600, "stop_lon": 34.7700}
                    end = {"stop_lat": 32.0750, "stop_lon": 34.7750}

                    router.semi_ultra_route(
                        start_location=start,
                        end_location=end,
                        start_time="08:00:00",
                        tt=mock_timetable,
                        car_route=False,
                        relax_footpaths=False,
                        debug=False,
                        limit_walking_time=3600
                    )

                    # Check that start station has connections
                    start_stations = [s for s in mock_timetable.stations
                                     if s.startswith("Start_")]
                    assert len(start_stations) > 0

                    start_id = start_stations[0]
                    assert start_id in mock_timetable.station_connections
                    # Should have walking connections
                    assert len(mock_timetable.station_connections[start_id]) > 0


class TestRunUltraWrapper:
    """Tests for the run_ultra_wrapper function."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_run_ultra_wrapper_returns_results(self, mock_timetable):
        """Test that run_ultra_wrapper returns RaptorResult objects."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            with patch('os.path.isfile', return_value=False):
                with patch('raptor_routing.utils.save_artifact'):
                    with patch('raptor_routing.bus_line_from_trip_id', return_value="5"):
                        from raptor_routing import run_ultra_wrapper

                        start = {"stop_lat": 32.0556, "stop_lon": 34.7818}
                        end = {"stop_lat": 32.0750, "stop_lon": 34.7750}

                        results = run_ultra_wrapper(
                            start_loc=start,
                            end_loc=end,
                            start_time="08:00:00",
                            tt=mock_timetable,
                            car_route=False,
                            relax_footpaths=False,
                            limit_walking_time=3600,
                            debug=False
                        )

                        # Should return list (possibly empty if no route found)
                        assert isinstance(results, list)

    def test_run_ultra_wrapper_with_car_route(self, mock_timetable):
        """Test that run_ultra_wrapper works with car routing enabled."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            with patch('car_routing.get_actor', return_value=self.mock_actor):
                with patch('os.path.isfile', return_value=False):
                    with patch('raptor_routing.utils.save_artifact'):
                        with patch('raptor_routing.bus_line_from_trip_id', return_value="5"):
                            from raptor_routing import run_ultra_wrapper

                            start = {"stop_lat": 32.0556, "stop_lon": 34.7818}
                            end = {"stop_lat": 32.0750, "stop_lon": 34.7750}

                            results = run_ultra_wrapper(
                                start_loc=start,
                                end_loc=end,
                                start_time="08:00:00",
                                tt=mock_timetable,
                                car_route=True,  # Enable car routing
                                relax_footpaths=False,
                                limit_walking_time=3600,
                                debug=False
                            )

                            # Should return list
                            assert isinstance(results, list)


class TestRelaxFootpaths:
    """Tests for footpath relaxation in RAPTOR."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup mock environment."""
        reset_mock_actor()
        self.mock_actor = MockValhallaActor()

    def test_relax_footpaths_adds_walking_connections(self, mock_timetable):
        """Test that relaxing footpaths adds walking connection options."""
        with patch('raptor_routing.get_actor', return_value=self.mock_actor):
            from raptor_routing import raptor_route

            end_footpath_connections = {
                "sources_to_targets": [
                    [{"time": 300, "from_index": i}]
                    for i in range(len(mock_timetable.stations))
                ]
            }

            initial_trips = len(mock_timetable.trips)

            raptor_route(
                start_station="station_1",
                end_station="station_4",
                start_time="08:00:00",
                tt=mock_timetable,
                end_footpath_connections=end_footpath_connections,
                relax_footpaths=True,  # Enable footpath relaxation
                limit_mid_walking_time=360,  # 6 minutes
                debug=False
            )

            # Should have added footpath trips
            footpath_trips = [t for t in mock_timetable.trips
                            if t.startswith("footpath_")]
            assert len(footpath_trips) > 0
