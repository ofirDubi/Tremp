"""
Pytest configuration and fixtures for Tremp tests.

This module provides shared fixtures and configuration for all tests.
"""

import sys
import os
import pytest
from unittest.mock import patch, MagicMock

# Add source directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'dubi_gtfs_parser'))

# Import mock modules
from mocks.valhalla_mock import MockValhallaActor, get_mock_actor, reset_mock_actor
from fixtures.gtfs_fixtures import (
    create_mock_gtfs,
    create_mock_timetable,
    MockGTFS,
    MOCK_STATIONS,
    MOCK_TRIPS,
    MOCK_ROUTES,
    MOCK_STOP_TIMES,
    TEST_LOCATIONS
)


@pytest.fixture
def mock_gtfs():
    """Provide a fresh MockGTFS instance for each test."""
    return create_mock_gtfs()


@pytest.fixture
def mock_timetable(mock_gtfs):
    """Provide a mock Timetable instance with pre-built connections."""
    return create_mock_timetable(mock_gtfs)


@pytest.fixture
def mock_valhalla_actor():
    """Provide a fresh MockValhallaActor instance for each test."""
    reset_mock_actor()
    actor = MockValhallaActor()
    yield actor
    reset_mock_actor()


@pytest.fixture
def mock_valhalla_actor_with_custom_responses():
    """
    Factory fixture for creating MockValhallaActor with custom responses.

    Usage:
        def test_something(mock_valhalla_actor_with_custom_responses):
            actor = mock_valhalla_actor_with_custom_responses({
                'matrix': {'sources_to_targets': [[{'time': 100, 'distance': 500}]]}
            })
    """
    def _create_actor(custom_responses):
        reset_mock_actor()
        return MockValhallaActor(custom_responses)

    yield _create_actor
    reset_mock_actor()


@pytest.fixture
def patch_valhalla():
    """
    Fixture that patches the valhalla_interface.get_actor to use mock.

    Usage:
        def test_something(patch_valhalla):
            # Now any code that calls get_actor() will use the mock
            result = some_function_that_uses_valhalla()
    """
    mock_actor = MockValhallaActor()
    with patch('valhalla_interface.get_actor', return_value=mock_actor):
        yield mock_actor


@pytest.fixture
def sample_stations():
    """Provide the default mock stations dict."""
    return MOCK_STATIONS.copy()


@pytest.fixture
def sample_trips():
    """Provide the default mock trips dict."""
    return MOCK_TRIPS.copy()


@pytest.fixture
def sample_routes():
    """Provide the default mock routes dict."""
    return MOCK_ROUTES.copy()


@pytest.fixture
def sample_stop_times():
    """Provide the default mock stop_times dict."""
    return MOCK_STOP_TIMES.copy()


@pytest.fixture
def test_locations():
    """Provide common test locations."""
    return TEST_LOCATIONS.copy()


@pytest.fixture
def start_end_locations(test_locations):
    """Provide a simple start/end location pair for routing tests."""
    return {
        'start': test_locations['home'],
        'end': test_locations['work']
    }


# Markers for test categorization
def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "slow: marks tests as slow")
    config.addinivalue_line("markers", "integration: marks tests as integration tests")
    config.addinivalue_line("markers", "unit: marks tests as unit tests")
