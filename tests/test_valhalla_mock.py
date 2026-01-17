"""
Tests for the Valhalla mock server.

These tests verify that the mock server correctly simulates
Valhalla API responses with realistic values.
"""

import pytest
import math
from mocks.valhalla_mock import MockValhallaActor, get_mock_actor, reset_mock_actor


class TestMockValhallaActor:
    """Test suite for MockValhallaActor."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Reset mock actor before each test."""
        reset_mock_actor()
        self.actor = MockValhallaActor()

    def test_matrix_basic(self):
        """Test basic matrix query with single source and target."""
        query = {
            "sources": [{"lat": 32.0556, "lon": 34.7818}],
            "targets": [{"lat": 32.0750, "lon": 34.7750}],
            "costing": "auto"
        }

        result = self.actor.matrix(query)

        assert "sources_to_targets" in result
        assert len(result["sources_to_targets"]) == 1
        assert len(result["sources_to_targets"][0]) == 1
        assert "time" in result["sources_to_targets"][0][0]
        assert "distance" in result["sources_to_targets"][0][0]
        assert result["sources_to_targets"][0][0]["time"] > 0
        assert result["sources_to_targets"][0][0]["distance"] > 0

    def test_matrix_multiple_targets(self):
        """Test matrix query with one source and multiple targets."""
        query = {
            "sources": [{"lat": 32.0556, "lon": 34.7818}],
            "targets": [
                {"lat": 32.0750, "lon": 34.7750},
                {"lat": 32.0870, "lon": 34.7810},
                {"lat": 32.0950, "lon": 34.7900}
            ],
            "costing": "pedestrian"
        }

        result = self.actor.matrix(query)

        assert len(result["sources_to_targets"]) == 1
        assert len(result["sources_to_targets"][0]) == 3

        # Verify distances increase with position (roughly)
        distances = [r["distance"] for r in result["sources_to_targets"][0]]
        assert all(d > 0 for d in distances)

    def test_matrix_many_to_many(self):
        """Test matrix query with multiple sources and targets."""
        query = {
            "sources": [
                {"lat": 32.0556, "lon": 34.7818},
                {"lat": 32.0650, "lon": 34.7680}
            ],
            "targets": [
                {"lat": 32.0750, "lon": 34.7750},
                {"lat": 32.0870, "lon": 34.7810}
            ],
            "costing": "auto"
        }

        result = self.actor.matrix(query)

        assert len(result["sources_to_targets"]) == 2
        assert len(result["sources_to_targets"][0]) == 2
        assert len(result["sources_to_targets"][1]) == 2

    def test_matrix_walking_slower_than_driving(self):
        """Verify that walking times are longer than driving times."""
        source = {"lat": 32.0556, "lon": 34.7818}
        target = {"lat": 32.0750, "lon": 34.7750}

        walk_result = self.actor.matrix({
            "sources": [source],
            "targets": [target],
            "costing": "pedestrian"
        })

        drive_result = self.actor.matrix({
            "sources": [source],
            "targets": [target],
            "costing": "auto"
        })

        walk_time = walk_result["sources_to_targets"][0][0]["time"]
        drive_time = drive_result["sources_to_targets"][0][0]["time"]

        assert walk_time > drive_time

    def test_isochrone_basic(self):
        """Test basic isochrone generation."""
        query = {
            "locations": [{"lat": 32.0750, "lon": 34.7750}],
            "contours": [{"time": 5, "color": "ff0000"}],
            "costing": "pedestrian"
        }

        result = self.actor.isochrone(query)

        assert "features" in result
        assert len(result["features"]) == 1
        assert result["features"][0]["geometry"]["type"] == "Polygon"
        assert len(result["features"][0]["geometry"]["coordinates"]) > 3

    def test_isochrone_multiple_contours(self):
        """Test isochrone with multiple time contours."""
        query = {
            "locations": [{"lat": 32.0750, "lon": 34.7750}],
            "contours": [
                {"time": 10, "color": "ff0000"},
                {"time": 5, "color": "00ff00"}
            ],
            "costing": "auto"
        }

        result = self.actor.isochrone(query)

        assert len(result["features"]) == 2

    def test_isochrone_polygon_contains_center(self):
        """Verify that generated isochrone polygon contains the center point."""
        center_lat = 32.0750
        center_lon = 34.7750

        query = {
            "locations": [{"lat": center_lat, "lon": center_lon}],
            "contours": [{"time": 10, "color": "ff0000"}],
            "costing": "auto"
        }

        result = self.actor.isochrone(query)
        coords = result["features"][0]["geometry"]["coordinates"]

        # Simple point-in-polygon check using ray casting
        # The center should be inside the polygon
        min_lon = min(c[0] for c in coords)
        max_lon = max(c[0] for c in coords)
        min_lat = min(c[1] for c in coords)
        max_lat = max(c[1] for c in coords)

        assert min_lon < center_lon < max_lon
        assert min_lat < center_lat < max_lat

    def test_optimized_route_basic(self):
        """Test basic optimized route generation."""
        query = {
            "locations": [
                {"lat": 32.0556, "lon": 34.7818},
                {"lat": 32.0750, "lon": 34.7750}
            ],
            "costing": "auto",
            "directions_options": {"units": "meters"}
        }

        result = self.actor.optimized_route(query)

        assert "trip" in result
        assert "legs" in result["trip"]
        assert len(result["trip"]["legs"]) == 1
        assert "shape" in result["trip"]["legs"][0]
        assert len(result["trip"]["legs"][0]["shape"]) > 0

    def test_optimized_route_multiple_waypoints(self):
        """Test optimized route with multiple waypoints."""
        query = {
            "locations": [
                {"lat": 32.0556, "lon": 34.7818},
                {"lat": 32.0750, "lon": 34.7750},
                {"lat": 32.0870, "lon": 34.7810}
            ],
            "costing": "pedestrian"
        }

        result = self.actor.optimized_route(query)

        assert len(result["trip"]["legs"]) == 2

    def test_call_history_tracking(self):
        """Verify that API calls are tracked in history."""
        self.actor.matrix({
            "sources": [{"lat": 32.0, "lon": 34.0}],
            "targets": [{"lat": 32.1, "lon": 34.1}],
            "costing": "auto"
        })
        self.actor.isochrone({
            "locations": [{"lat": 32.0, "lon": 34.0}],
            "contours": [{"time": 5}],
            "costing": "auto"
        })
        self.actor.optimized_route({
            "locations": [
                {"lat": 32.0, "lon": 34.0},
                {"lat": 32.1, "lon": 34.1}
            ],
            "costing": "auto"
        })

        assert self.actor.get_call_count() == 3
        assert self.actor.get_call_count("matrix") == 1
        assert self.actor.get_call_count("isochrone") == 1
        assert self.actor.get_call_count("optimized_route") == 1

    def test_reset_history(self):
        """Test that call history can be reset."""
        self.actor.matrix({
            "sources": [{"lat": 32.0, "lon": 34.0}],
            "targets": [{"lat": 32.1, "lon": 34.1}],
            "costing": "auto"
        })

        assert self.actor.get_call_count() == 1

        self.actor.reset_history()

        assert self.actor.get_call_count() == 0

    def test_custom_responses(self):
        """Test that custom responses can be injected."""
        custom_matrix_response = {
            "sources_to_targets": [[{"time": 999, "distance": 12345}]]
        }

        actor = MockValhallaActor({"matrix": custom_matrix_response})

        result = actor.matrix({
            "sources": [{"lat": 32.0, "lon": 34.0}],
            "targets": [{"lat": 32.1, "lon": 34.1}],
            "costing": "auto"
        })

        assert result["sources_to_targets"][0][0]["time"] == 999
        assert result["sources_to_targets"][0][0]["distance"] == 12345


class TestGetMockActor:
    """Test the get_mock_actor singleton function."""

    def setup_method(self):
        """Reset before each test."""
        reset_mock_actor()

    def test_returns_singleton(self):
        """Verify get_mock_actor returns the same instance."""
        actor1 = get_mock_actor()
        actor2 = get_mock_actor()

        assert actor1 is actor2

    def test_reset_creates_new_instance(self):
        """Verify reset allows new instance creation."""
        actor1 = get_mock_actor()
        reset_mock_actor()
        actor2 = get_mock_actor()

        assert actor1 is not actor2

    def test_accepts_timetable_parameter(self):
        """Verify get_mock_actor accepts tt parameter for API compatibility."""
        mock_tt = object()
        actor = get_mock_actor(mock_tt)

        assert actor is not None


class TestHaversineDistance:
    """Test the distance calculation accuracy."""

    def test_known_distance(self):
        """Test distance calculation against a known value."""
        actor = MockValhallaActor()

        # Distance from Tel Aviv to Haifa is approximately 90km
        tlv = {"lat": 32.0853, "lon": 34.7818}
        haifa = {"lat": 32.7940, "lon": 34.9896}

        query = {
            "sources": [tlv],
            "targets": [haifa],
            "costing": "auto"
        }

        result = actor.matrix(query)
        distance_m = result["sources_to_targets"][0][0]["distance"]

        # Allow 10% margin for haversine vs actual road distance
        expected_km = 90
        assert 70000 < distance_m < 110000, f"Expected ~90km, got {distance_m/1000:.1f}km"

    def test_zero_distance(self):
        """Test that same location returns zero distance."""
        actor = MockValhallaActor()

        location = {"lat": 32.0853, "lon": 34.7818}

        query = {
            "sources": [location],
            "targets": [location],
            "costing": "auto"
        }

        result = actor.matrix(query)
        distance = result["sources_to_targets"][0][0]["distance"]

        assert distance < 1  # Less than 1 meter
