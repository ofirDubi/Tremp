"""
Mock GTFS data fixtures for testing.

This module provides realistic mock GTFS data structures that can be used
to test the routing algorithms without requiring actual GTFS files.

The mock data represents a simplified transit network with:
- 10 stations in a grid-like pattern around Tel Aviv
- 3 bus routes connecting the stations
- Scheduled trips with realistic departure times
"""

from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from unittest.mock import MagicMock


# Mock station data - representing a small transit network in Tel Aviv area
MOCK_STATIONS: Dict[str, Dict[str, Any]] = {
    "station_1": {
        "station_id": "station_1",
        "stop_name": "Central Station",
        "stop_lat": 32.0556,
        "stop_lon": 34.7818,
        "stop_code": "1001"
    },
    "station_2": {
        "station_id": "station_2",
        "stop_name": "Dizengoff Center",
        "stop_lat": 32.0750,
        "stop_lon": 34.7750,
        "stop_code": "1002"
    },
    "station_3": {
        "station_id": "station_3",
        "stop_name": "Rabin Square",
        "stop_lat": 32.0870,
        "stop_lon": 34.7810,
        "stop_code": "1003"
    },
    "station_4": {
        "station_id": "station_4",
        "stop_name": "Reading Terminal",
        "stop_lat": 32.0950,
        "stop_lon": 34.7900,
        "stop_code": "1004"
    },
    "station_5": {
        "station_id": "station_5",
        "stop_name": "Carmel Market",
        "stop_lat": 32.0650,
        "stop_lon": 34.7680,
        "stop_code": "1005"
    },
    "station_6": {
        "station_id": "station_6",
        "stop_name": "Rothschild Blvd",
        "stop_lat": 32.0640,
        "stop_lon": 34.7750,
        "stop_code": "1006"
    },
    "station_7": {
        "station_id": "station_7",
        "stop_name": "Habima Square",
        "stop_lat": 32.0720,
        "stop_lon": 34.7790,
        "stop_code": "1007"
    },
    "station_8": {
        "station_id": "station_8",
        "stop_name": "Tel Aviv Museum",
        "stop_lat": 32.0770,
        "stop_lon": 34.7870,
        "stop_code": "1008"
    },
    "station_9": {
        "station_id": "station_9",
        "stop_name": "Sarona",
        "stop_lat": 32.0720,
        "stop_lon": 34.7850,
        "stop_code": "1009"
    },
    "station_10": {
        "station_id": "station_10",
        "stop_name": "Azrieli Center",
        "stop_lat": 32.0740,
        "stop_lon": 34.7920,
        "stop_code": "1010"
    }
}


# Mock routes
MOCK_ROUTES: Dict[str, Dict[str, Any]] = {
    "route_1": {
        "route_id": "route_1",
        "route_short_name": "5",
        "route_long_name": "Central - Reading",
        "route_type": 3,  # Bus
        "route_color": "FF0000"
    },
    "route_2": {
        "route_id": "route_2",
        "route_short_name": "18",
        "route_long_name": "Carmel - Museum",
        "route_type": 3,
        "route_color": "00FF00"
    },
    "route_3": {
        "route_id": "route_3",
        "route_short_name": "25",
        "route_long_name": "Rothschild - Azrieli",
        "route_type": 3,
        "route_color": "0000FF"
    }
}


# Mock trips - instances of routes at specific times
MOCK_TRIPS: Dict[str, Dict[str, Any]] = {
    # Route 1 trips (Central -> Dizengoff -> Rabin -> Reading)
    "trip_1_morning": {
        "trip_id": "trip_1_morning",
        "route_id": "route_1",
        "service_id": "weekday",
        "trip_headsign": "Reading Terminal",
        "direction_id": 0
    },
    "trip_1_midday": {
        "trip_id": "trip_1_midday",
        "route_id": "route_1",
        "service_id": "weekday",
        "trip_headsign": "Reading Terminal",
        "direction_id": 0
    },
    "trip_1_return": {
        "trip_id": "trip_1_return",
        "route_id": "route_1",
        "service_id": "weekday",
        "trip_headsign": "Central Station",
        "direction_id": 1
    },
    # Route 2 trips (Carmel -> Rothschild -> Habima -> Museum)
    "trip_2_morning": {
        "trip_id": "trip_2_morning",
        "route_id": "route_2",
        "service_id": "weekday",
        "trip_headsign": "Tel Aviv Museum",
        "direction_id": 0
    },
    "trip_2_midday": {
        "trip_id": "trip_2_midday",
        "route_id": "route_2",
        "service_id": "weekday",
        "trip_headsign": "Tel Aviv Museum",
        "direction_id": 0
    },
    # Route 3 trips (Rothschild -> Sarona -> Azrieli)
    "trip_3_morning": {
        "trip_id": "trip_3_morning",
        "route_id": "route_3",
        "service_id": "weekday",
        "trip_headsign": "Azrieli Center",
        "direction_id": 0
    },
    # Footpath pseudo-trip
    "footpath": {
        "trip_id": "footpath",
        "route_id": "footpath",
        "service_id": "always",
        "trip_headsign": "Walking",
        "direction_id": 0
    },
    # Car route pseudo-trip
    "car_route": {
        "trip_id": "car_route",
        "route_id": "car_route",
        "service_id": "always",
        "trip_headsign": "Driving",
        "direction_id": 0
    }
}


# Mock stop_times - schedule for each trip
MOCK_STOP_TIMES: Dict[str, List[Dict[str, Any]]] = {
    "trip_1_morning": [
        {"station_id": "station_1", "arrival_time": "08:00:00", "departure_time": "08:00:00", "stop_sequence": 1},
        {"station_id": "station_2", "arrival_time": "08:10:00", "departure_time": "08:11:00", "stop_sequence": 2},
        {"station_id": "station_3", "arrival_time": "08:20:00", "departure_time": "08:21:00", "stop_sequence": 3},
        {"station_id": "station_4", "arrival_time": "08:30:00", "departure_time": "08:30:00", "stop_sequence": 4}
    ],
    "trip_1_midday": [
        {"station_id": "station_1", "arrival_time": "12:00:00", "departure_time": "12:00:00", "stop_sequence": 1},
        {"station_id": "station_2", "arrival_time": "12:10:00", "departure_time": "12:11:00", "stop_sequence": 2},
        {"station_id": "station_3", "arrival_time": "12:20:00", "departure_time": "12:21:00", "stop_sequence": 3},
        {"station_id": "station_4", "arrival_time": "12:30:00", "departure_time": "12:30:00", "stop_sequence": 4}
    ],
    "trip_1_return": [
        {"station_id": "station_4", "arrival_time": "09:00:00", "departure_time": "09:00:00", "stop_sequence": 1},
        {"station_id": "station_3", "arrival_time": "09:10:00", "departure_time": "09:11:00", "stop_sequence": 2},
        {"station_id": "station_2", "arrival_time": "09:20:00", "departure_time": "09:21:00", "stop_sequence": 3},
        {"station_id": "station_1", "arrival_time": "09:30:00", "departure_time": "09:30:00", "stop_sequence": 4}
    ],
    "trip_2_morning": [
        {"station_id": "station_5", "arrival_time": "08:05:00", "departure_time": "08:05:00", "stop_sequence": 1},
        {"station_id": "station_6", "arrival_time": "08:12:00", "departure_time": "08:13:00", "stop_sequence": 2},
        {"station_id": "station_7", "arrival_time": "08:20:00", "departure_time": "08:21:00", "stop_sequence": 3},
        {"station_id": "station_8", "arrival_time": "08:28:00", "departure_time": "08:28:00", "stop_sequence": 4}
    ],
    "trip_2_midday": [
        {"station_id": "station_5", "arrival_time": "12:05:00", "departure_time": "12:05:00", "stop_sequence": 1},
        {"station_id": "station_6", "arrival_time": "12:12:00", "departure_time": "12:13:00", "stop_sequence": 2},
        {"station_id": "station_7", "arrival_time": "12:20:00", "departure_time": "12:21:00", "stop_sequence": 3},
        {"station_id": "station_8", "arrival_time": "12:28:00", "departure_time": "12:28:00", "stop_sequence": 4}
    ],
    "trip_3_morning": [
        {"station_id": "station_6", "arrival_time": "08:15:00", "departure_time": "08:15:00", "stop_sequence": 1},
        {"station_id": "station_9", "arrival_time": "08:22:00", "departure_time": "08:23:00", "stop_sequence": 2},
        {"station_id": "station_10", "arrival_time": "08:30:00", "departure_time": "08:30:00", "stop_sequence": 3}
    ]
}


# Mock shapes - polyline coordinates for routes
MOCK_SHAPES: Dict[str, List[Dict[str, Any]]] = {
    "shape_route_1": [
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0556, "shape_pt_lon": 34.7818, "shape_pt_sequence": 1},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0653, "shape_pt_lon": 34.7784, "shape_pt_sequence": 2},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0750, "shape_pt_lon": 34.7750, "shape_pt_sequence": 3},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0810, "shape_pt_lon": 34.7780, "shape_pt_sequence": 4},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0870, "shape_pt_lon": 34.7810, "shape_pt_sequence": 5},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0910, "shape_pt_lon": 34.7855, "shape_pt_sequence": 6},
        {"shape_id": "shape_route_1", "shape_pt_lat": 32.0950, "shape_pt_lon": 34.7900, "shape_pt_sequence": 7}
    ]
}


# Calendar data
MOCK_CALENDAR: Dict[str, Dict[str, Any]] = {
    "weekday": {
        "service_id": "weekday",
        "monday": 1,
        "tuesday": 1,
        "wednesday": 1,
        "thursday": 1,
        "friday": 1,
        "saturday": 0,
        "sunday": 0,
        "start_date": "20240101",
        "end_date": "20241231"
    },
    "always": {
        "service_id": "always",
        "monday": 1,
        "tuesday": 1,
        "wednesday": 1,
        "thursday": 1,
        "friday": 1,
        "saturday": 1,
        "sunday": 1,
        "start_date": "20240101",
        "end_date": "20241231"
    }
}


class MockGTFS:
    """
    Mock GTFS data class that mimics the structure of the real GTFS parser.
    """

    def __init__(
        self,
        stations: Optional[Dict] = None,
        routes: Optional[Dict] = None,
        trips: Optional[Dict] = None,
        stop_times: Optional[Dict] = None,
        shapes: Optional[Dict] = None,
        calendar: Optional[Dict] = None
    ):
        """
        Initialize mock GTFS data.

        Args:
            stations: Optional custom stations dict
            routes: Optional custom routes dict
            trips: Optional custom trips dict
            stop_times: Optional custom stop_times dict
            shapes: Optional custom shapes dict
            calendar: Optional custom calendar dict
        """
        self.stations = stations or MOCK_STATIONS.copy()
        self.routes = routes or MOCK_ROUTES.copy()
        self.trips = trips or MOCK_TRIPS.copy()
        self.stop_times = stop_times or MOCK_STOP_TIMES.copy()
        self.shapes = shapes or MOCK_SHAPES.copy()
        self.calendar = calendar or MOCK_CALENDAR.copy()
        self.agencies = {"agency_1": {"agency_id": "agency_1", "agency_name": "Tel Aviv Transit"}}

    def match_stops_to_shapes_for_trip(self, trip_id: str) -> List[Dict[str, Any]]:
        """
        Match stop times to shapes for a trip.

        Args:
            trip_id: The trip identifier

        Returns:
            List of stop dictionaries with associated shape points
        """
        if trip_id not in self.stop_times:
            return []

        route_id = self.trips[trip_id]["route_id"]
        shape_id = f"shape_{route_id}"

        result = []
        for stop_time in self.stop_times[trip_id]:
            station = self.stations[stop_time["station_id"]]
            stop_with_shapes = {
                "station_id": stop_time["station_id"],
                "arrival_time": stop_time["arrival_time"],
                "departure_time": stop_time["departure_time"],
                "shapes": [
                    {
                        "shape_id": shape_id,
                        "shape_pt_lat": station["stop_lat"],
                        "shape_pt_lon": station["stop_lon"],
                        "shape_pt_sequence": stop_time["stop_sequence"]
                    }
                ]
            }
            result.append(stop_with_shapes)

        return result


def create_mock_gtfs(
    stations: Optional[Dict] = None,
    routes: Optional[Dict] = None,
    trips: Optional[Dict] = None,
    stop_times: Optional[Dict] = None
) -> MockGTFS:
    """
    Factory function to create a MockGTFS instance.

    Args:
        stations: Optional custom stations
        routes: Optional custom routes
        trips: Optional custom trips
        stop_times: Optional custom stop_times

    Returns:
        MockGTFS instance
    """
    return MockGTFS(
        stations=stations,
        routes=routes,
        trips=trips,
        stop_times=stop_times
    )


def create_mock_timetable(mock_gtfs: Optional[MockGTFS] = None):
    """
    Create a mock Timetable object for testing.

    This function creates a simplified timetable that doesn't require
    Valhalla for initialization.

    Args:
        mock_gtfs: Optional MockGTFS instance

    Returns:
        Mock Timetable-like object
    """
    if mock_gtfs is None:
        mock_gtfs = create_mock_gtfs()

    # Create a mock timetable object with necessary attributes
    timetable = MagicMock()
    timetable.stations = mock_gtfs.stations.copy()
    timetable.trips = mock_gtfs.trips.copy()
    timetable.shapes = mock_gtfs.shapes.copy()
    timetable.gtfs_instance = mock_gtfs

    # Build station connections from stop_times
    station_connections = {}
    trip_connections = {}

    for trip_id, stop_times in mock_gtfs.stop_times.items():
        trip_connections[trip_id] = []
        prev_stop = None

        for stop_time in stop_times:
            if prev_stop is not None:
                # Create a mock Connection
                connection = MagicMock()
                connection.departure_stop = prev_stop["station_id"]
                connection.arrival_stop = stop_time["station_id"]
                connection.departure_time = prev_stop["departure_time"]
                connection.arrival_time = stop_time["arrival_time"]
                connection.trip_id = trip_id
                connection.shapes = None

                # Add to station connections
                if prev_stop["station_id"] not in station_connections:
                    station_connections[prev_stop["station_id"]] = []
                station_connections[prev_stop["station_id"]].append(connection)

                # Add to trip connections
                trip_connections[trip_id].append(connection)

            prev_stop = stop_time

    timetable.station_connections = station_connections
    timetable.trip_connections = trip_connections

    # Build stations footpaths (simplified - just nearby stations)
    stations_footpaths = {}
    for station_id in mock_gtfs.stations:
        stations_footpaths[station_id] = []
        current_station = mock_gtfs.stations[station_id]

        for other_id, other_station in mock_gtfs.stations.items():
            if other_id != station_id:
                # Calculate simple distance
                dlat = abs(current_station["stop_lat"] - other_station["stop_lat"])
                dlon = abs(current_station["stop_lon"] - other_station["stop_lon"])
                distance_deg = (dlat ** 2 + dlon ** 2) ** 0.5

                # ~1km radius in degrees
                if distance_deg < 0.01:
                    distance_m = distance_deg * 111320  # rough conversion
                    time_s = int(distance_m / 1.4)  # walking speed
                    stations_footpaths[station_id].append({
                        "station_id": other_id,
                        "distance": distance_m / 1000,  # in km
                        "time": time_s
                    })

    timetable.stations_footpaths = stations_footpaths

    # Add helper method for creating walking stations
    timetable._walking_station_id = 0

    def create_walking_station(station_lon_lat, name="Walking"):
        timetable._walking_station_id += 1
        station_id = f"{name}_{timetable._walking_station_id}"
        new_station = {
            "station_id": station_id,
            "stop_lon": station_lon_lat["lon"],
            "stop_lat": station_lon_lat["lat"],
            "stop_name": name
        }
        timetable.stations[station_id] = new_station
        timetable.station_connections[station_id] = []
        return new_station

    timetable._create_walking_station = create_walking_station

    return timetable


# Test locations (lat/lon pairs for common test scenarios)
TEST_LOCATIONS = {
    "home": {"lat": 32.0600, "lon": 34.7700},  # Near Carmel Market
    "work": {"lat": 32.0740, "lon": 34.7920},  # Azrieli Center
    "downtown": {"lat": 32.0750, "lon": 34.7750},  # Dizengoff
    "north": {"lat": 32.0950, "lon": 34.7900},  # Reading Terminal
    "south": {"lat": 32.0556, "lon": 34.7818},  # Central Station
}
