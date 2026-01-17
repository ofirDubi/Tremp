"""
Mock Valhalla Actor for testing.

This module provides a mock implementation of the Valhalla routing engine API
that returns realistic but predictable responses for testing purposes.
The mock simulates:
- matrix(): One-to-many/many-to-one routing calculations
- isochrone(): Travel time polygon calculations
- optimized_route(): Point-to-point route with shape data

All responses follow the actual Valhalla API response format.
"""

import math
from typing import Dict, List, Any, Optional


class MockValhallaActor:
    """
    Mock implementation of Valhalla Actor for testing.

    This class provides deterministic responses that allow testing
    of the routing algorithms without requiring a running Valhalla instance.
    """

    # Configurable response parameters
    DEFAULT_WALKING_SPEED_MS = 1.4  # meters per second (~5 km/h)
    DEFAULT_DRIVING_SPEED_MS = 11.1  # meters per second (~40 km/h in urban area)

    def __init__(self, custom_responses: Optional[Dict] = None):
        """
        Initialize the mock actor.

        Args:
            custom_responses: Optional dict of custom responses keyed by query type.
                             Allows tests to inject specific responses.
        """
        self.custom_responses = custom_responses or {}
        self.call_history = []  # Track all API calls for assertions

    def _haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance in meters between two lat/lon points using Haversine formula."""
        R = 6371000  # Earth radius in meters

        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = math.sin(delta_phi / 2) ** 2 + \
            math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    def _estimate_travel_time(self, distance_m: float, costing: str) -> int:
        """
        Estimate travel time in seconds based on distance and mode.

        Args:
            distance_m: Distance in meters
            costing: Travel mode ('auto', 'pedestrian', etc.)

        Returns:
            Estimated travel time in seconds
        """
        if costing == "pedestrian":
            speed = self.DEFAULT_WALKING_SPEED_MS
        elif costing == "auto":
            speed = self.DEFAULT_DRIVING_SPEED_MS
        else:
            speed = self.DEFAULT_WALKING_SPEED_MS

        return int(distance_m / speed)

    def _encode_polyline(self, coordinates: List[tuple]) -> str:
        """
        Encode a list of (lat, lon) coordinates to a polyline string.
        Uses Valhalla's precision of 1e6.
        """
        result = []
        prev_lat = 0
        prev_lon = 0

        for lat, lon in coordinates:
            lat_int = int(round(lat * 1e6))
            lon_int = int(round(lon * 1e6))

            d_lat = lat_int - prev_lat
            d_lon = lon_int - prev_lon

            prev_lat = lat_int
            prev_lon = lon_int

            for value in [d_lat, d_lon]:
                value = ~(value << 1) if value < 0 else (value << 1)
                while value >= 0x20:
                    result.append(chr((0x20 | (value & 0x1f)) + 63))
                    value >>= 5
                result.append(chr(value + 63))

        return ''.join(result)

    def matrix(self, query: Dict[str, Any]) -> Dict[str, Any]:
        """
        Mock implementation of Valhalla matrix API.

        Calculates routing matrix between sources and targets using
        haversine distance approximation.

        Args:
            query: Dict with 'sources', 'targets', and 'costing' keys

        Returns:
            Dict with 'sources_to_targets' matrix containing time and distance
        """
        self.call_history.append(('matrix', query))

        # Check for custom response
        if 'matrix' in self.custom_responses:
            return self.custom_responses['matrix']

        sources = query.get('sources', [])
        targets = query.get('targets', [])
        costing = query.get('costing', 'auto')

        sources_to_targets = []

        for i, source in enumerate(sources):
            source_lat = source.get('lat')
            source_lon = source.get('lon')
            row = []

            for j, target in enumerate(targets):
                target_lat = target.get('lat')
                target_lon = target.get('lon')

                distance = self._haversine_distance(
                    source_lat, source_lon,
                    target_lat, target_lon
                )
                time = self._estimate_travel_time(distance, costing)

                row.append({
                    'time': time,
                    'distance': distance,
                    'to_index': j,
                    'from_index': i
                })

            sources_to_targets.append(row)

        return {'sources_to_targets': sources_to_targets}

    def isochrone(self, query: Dict[str, Any]) -> Dict[str, Any]:
        """
        Mock implementation of Valhalla isochrone API.

        Generates simplified circular isochrone polygons based on travel time.

        Args:
            query: Dict with 'locations', 'contours', and 'costing' keys

        Returns:
            Dict with 'features' containing polygon geometries
        """
        self.call_history.append(('isochrone', query))

        # Check for custom response
        if 'isochrone' in self.custom_responses:
            return self.custom_responses['isochrone']

        locations = query.get('locations', [])
        contours = query.get('contours', [])
        costing = query.get('costing', 'auto')

        if not locations:
            return {'features': []}

        center_lat = locations[0].get('lat')
        center_lon = locations[0].get('lon')

        features = []

        # Sort contours by time descending (outer to inner)
        sorted_contours = sorted(contours, key=lambda x: x.get('time', 0), reverse=True)

        for contour in sorted_contours:
            time_minutes = contour.get('time', 5)
            time_seconds = time_minutes * 60

            # Calculate radius based on travel time and mode
            if costing == "pedestrian":
                radius_m = time_seconds * self.DEFAULT_WALKING_SPEED_MS
            else:
                radius_m = time_seconds * self.DEFAULT_DRIVING_SPEED_MS

            # Convert radius to degrees (approximate)
            radius_deg = radius_m / 111320  # ~111km per degree at equator

            # Generate circular polygon with 16 points
            polygon_coords = []
            num_points = 16
            for i in range(num_points + 1):  # +1 to close the polygon
                angle = 2 * math.pi * i / num_points
                lat = center_lat + radius_deg * math.sin(angle)
                lon = center_lon + radius_deg * math.cos(angle) / math.cos(math.radians(center_lat))
                polygon_coords.append([lon, lat])  # GeoJSON uses [lon, lat]

            features.append({
                'type': 'Feature',
                'geometry': {
                    'type': 'Polygon',
                    'coordinates': polygon_coords
                },
                'properties': {
                    'contour': time_minutes,
                    'color': contour.get('color', 'ff0000')
                }
            })

        return {'features': features}

    def optimized_route(self, query: Dict[str, Any]) -> Dict[str, Any]:
        """
        Mock implementation of Valhalla optimized_route API.

        Generates a simple route between waypoints with encoded shape.

        Args:
            query: Dict with 'locations', 'costing', and optional 'directions_options'

        Returns:
            Dict with 'trip' containing 'legs' with route shape
        """
        self.call_history.append(('optimized_route', query))

        # Check for custom response
        if 'optimized_route' in self.custom_responses:
            return self.custom_responses['optimized_route']

        locations = query.get('locations', [])
        costing = query.get('costing', 'auto')

        if len(locations) < 2:
            return {'trip': {'legs': []}}

        legs = []

        for i in range(len(locations) - 1):
            start = locations[i]
            end = locations[i + 1]

            start_lat = start.get('lat')
            start_lon = start.get('lon')
            end_lat = end.get('lat')
            end_lon = end.get('lon')

            # Calculate distance and time
            distance = self._haversine_distance(start_lat, start_lon, end_lat, end_lon)
            time = self._estimate_travel_time(distance, costing)

            # Generate intermediate points for the shape (simple linear interpolation)
            num_points = max(3, int(distance / 100))  # One point per 100m
            shape_coords = []
            for j in range(num_points + 1):
                t = j / num_points
                lat = start_lat + t * (end_lat - start_lat)
                lon = start_lon + t * (end_lon - start_lon)
                shape_coords.append((lat, lon))

            # Encode the polyline
            encoded_shape = self._encode_polyline(shape_coords)

            legs.append({
                'shape': encoded_shape,
                'summary': {
                    'time': time,
                    'length': distance / 1000,  # Convert to km
                    'min_lat': min(start_lat, end_lat),
                    'min_lon': min(start_lon, end_lon),
                    'max_lat': max(start_lat, end_lat),
                    'max_lon': max(start_lon, end_lon)
                },
                'maneuvers': [
                    {
                        'type': 1,
                        'instruction': 'Start',
                        'length': distance / 1000,
                        'time': time
                    }
                ]
            })

        total_time = sum(leg['summary']['time'] for leg in legs)
        total_length = sum(leg['summary']['length'] for leg in legs)

        return {
            'trip': {
                'legs': legs,
                'summary': {
                    'time': total_time,
                    'length': total_length
                },
                'status_message': 'Found route between points',
                'status': 0
            }
        }

    def reset_history(self):
        """Clear the call history."""
        self.call_history = []

    def get_call_count(self, method: Optional[str] = None) -> int:
        """
        Get the number of API calls made.

        Args:
            method: Optional method name to filter by ('matrix', 'isochrone', 'optimized_route')

        Returns:
            Number of calls
        """
        if method is None:
            return len(self.call_history)
        return len([c for c in self.call_history if c[0] == method])


# Singleton instance for use with the get_actor pattern
_mock_actor_instance: Optional[MockValhallaActor] = None


def get_mock_actor(tt=None, custom_responses: Optional[Dict] = None) -> MockValhallaActor:
    """
    Get a singleton mock actor instance.

    This function matches the signature of valhalla_interface.get_actor()
    for easy patching in tests.

    Args:
        tt: Timetable instance (ignored in mock, kept for API compatibility)
        custom_responses: Optional custom responses to inject

    Returns:
        MockValhallaActor instance
    """
    global _mock_actor_instance
    if _mock_actor_instance is None or custom_responses is not None:
        _mock_actor_instance = MockValhallaActor(custom_responses)
    return _mock_actor_instance


def reset_mock_actor():
    """Reset the singleton mock actor."""
    global _mock_actor_instance
    _mock_actor_instance = None
