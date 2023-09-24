from utils import BinarySearchIdx, time_text_to_int, get_some_items
from connection_builder import Connection, Timetable, get_tlv_timetable
from display import display_connections, display_visited_stations, display_RaptorResult
import time

from valhalla import Actor, get_config, get_help


class RaptorResult():
    def __init__(self, result_route, tt):
        """
        @result_route - a list of tuples (station_id, connection)
        # Note - the first element in the list is the first station, and the last element is the last station
        @tt - timetable object
        """
        # Departure time is the departure time from the first station
        self.departure_time = result_route[0][1].departure_time
        # Arrival time is the arrival time to the last station
        self.arrival_time = result_route[-1][1].arrival_time
        self.result_route = result_route
        self.tt = tt
        self.result_connections = self._get_result_connections()
        self.num_stops = len(self.result_connections) - 1
        self.num_transfers = len(result_route)-2 # if no transfers, the result route is of length 2 (start station, end station)
        self.trip_time = (time_text_to_int(self.arrival_time) - time_text_to_int(self.departure_time)) / 60
        self.bus_lines = []
        for r in self.result_route[1:]:
            line = tt.gtfs_instance.routes[tt.trips[r[1].trip_id]["route_id"]]["route_short_name"]
            self.bus_lines.append(line)

    def display_result(self):
        display_RaptorResult(self)

    def _get_result_connections(self):
        # Given a result route, return the connections that make up the route
        # The result route is a list of tuples (station_id, connection)
        # Skip the first station, because it is the start station
        prev_station, prev_connection = self.result_route[0]
        connections = []
        for i in range(1, len(self.result_route)):
            station, connection = self.result_route[i]
            # Algorithm searchs a specific trip from the start of the previous station up to this station
            following_connections = self.tt.follow_trip(connection, toConnection=True)
            taken_following_connections =[]
            found_link = False
            starting_idx = -1
            for i, c in enumerate(following_connections):
                if c.arrival_stop == prev_station:
                    starting_idx = i+1
                    break
            if starting_idx == -1:
                print("fml!")
                raise ValueError("Could not find the connection between {} and {}".format(prev_station, station))
            taken_following_connections = following_connections[starting_idx:]
            # display_connections(tt, taken_following_connections)
            connections += taken_following_connections
            # display_connections(tt, connections)
            prev_station, prev_connection = station, connection                
            # Find the connection between prev_station and station
        return connections
    
    def __str__(self):
        return f"RaptorResult: departure_time={self.departure_time}, arrival_time={self.arrival_time}, trip_time={self.trip_time}, num_stops={self.num_stops}, num_transfers={self.num_transfers}, bus_lines={self.bus_lines}"

def _traverse_route(visited_stations, end_station, start_station):
    result_route = []
    if end_station not in visited_stations:
        return None
    end_arrival_time, prev_station, end_connection, prev_connection = visited_stations[end_station]
    result_route.insert(0, (end_station, end_connection))
    curr_station = prev_station
    while prev_station != start_station:
        curr_arrival_time, prev_station, curr_connection, prev_connection = visited_stations[curr_station]
        result_route.insert(0, (curr_station, curr_connection))
        curr_station = prev_station
    # Insert the first station as well, for this i need to get the trip that got us to the second-to-first station, and find it's connection in the start_station.
    result_route.insert(0, (prev_station, prev_connection))
    
    return result_route

class RaptorRouter(object):
    def __init__(self, tt):
        # All optimizations should be perforemd on the timetable object
        # This class should only be used to route and handle Valhalla API
        config = get_config(tile_extract='./custom_files/valhalla_tiles.tar', verbose=False)
        self.actor = Actor(config)
        self.stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in tt.stations]

    def semi_ultra_route(self, start_location, end_location, start_time, tt, relax_footpaths=True,debug=False):        
        """
        # route using the ULTRA algorithm, but only for the first and last leg of the trip
        # for now we skip optimization for the middle part of the trip, because it requires alot of preprocessing on the graph.
        Algorithm works as follows
        1. Relax footpaths at start and end (using one-to-many implemented in Valhalla)
            1.2 let's start by implementing it as added connections from the start and end stations to all other stations.
        2. Route from start to end using RAPTOR (for now still without relaxing middle foorpaths)
        """
        # {"sources":[{"lat":40.744014,"lon":-73.990508}],"targets":[{"lat":40.744014,"lon":-73.990508},{"lat":40.739735,"lon":-73.979713},{"lat":40.752522,"lon":-73.985015},{"lat":40.750117,"lon":-73.983704},{"lat":40.750552,"lon":-73.993519}],"costing":"pedestrian"}
        # Get paths from start to all other stations
        query = {"sources" :[{"lat": start_location["stop_lat"], "lon": start_location["stop_lon"]}], "targets": self.stations_as_locations, "costing": "pedestrian"}
        source_footpath_connections = self.actor.matrix(query)
        print("got res!")
    
def raptor_route(start_station, end_station, start_time, tt, relax_footpaths=True,debug=False):
    """
    Route from location A to location B, using raptor algorithm and relaxing footpaths at start and end. 
    """
    # Preprocessing 
    # 1. Relax footpaths at start and end
    # 

def raptor_route_from_station(start_station, end_station, start_time, tt, relax_footpaths=True,debug=False):
    """
    Route from station to station
    @start_station - the station to start from
    @end_station - the station to end at
    @start_time - the time to start from
    @tt - a timetable object
    """
    # The algorithm is as follows:
    # 1. Initialize a set of stations that we know we can reach from the start station
    #   TODO: pre-2, relax footpaths to get to the nearest station
    # 2. For each station in the set, find the earliest connection that departs from it after the arrival time that we get from the trip
    #    2.1 only add to station set if we improve our arrival time to that station, and if it is before the current end time
    #   
    # 3. For each connection, add the arrival station to the set of reachable stations
    # 4. if the reachable stations is in the set of stations, set current_end_time to the arrival time of that station, also remove it. 
    # 5. Repeat 2-3 until no new stations are added to the set of reachable stations
    #    5.1 as an optimization, let's do it only 4 times max, in order to avoid many swaps
    # 6. If the end station is in the set of reachable stations, we found a route. Otherwise, no route exists.
    # 
    # The algorithm is described in the paper "Raptor: Routing with Trasit Hubs and Intermediate Stops" by Peter Sanders and Dominik Schultes.
    # 
    visited_stations = {start_station : (start_time, start_station, None, None)}
    # visited_stations is a dict of station_id -> (arrival_time, prev_station, connection, prev_connection)
    #
    # Do not iterate the same route twice
    visited_routes = {}
    new_stations = {start_station: start_time}
    next_round_new_stations = {}
    result_routes = []
    MAX_ROUNDS = 4
    current_target_arrival_time = time_text_to_int("23:59:59") + 1000
    for r in range(MAX_ROUNDS):
        if end_station in visited_stations:
            current_target_arrival_time = time_text_to_int(visited_stations[end_station][0])

        for station, st_arrival_time in new_stations.items():
            # iterate cho nnections starting from the start_time
            # TODO: think about what to do regarding day-night transotions...
            if station not in tt.station_connections:
                # TODO: i don't think this should happen tbh
                continue
            firts_connection = BinarySearchIdx(tt.station_connections[station], time_text_to_int(st_arrival_time), key=lambda x: time_text_to_int(x.departure_time))
            connections =  tt.station_connections[station][firts_connection:]
            for origin_c in connections:
                # Check if we already visited this route
                if tt.trips[origin_c.trip_id]["route_id"] in visited_routes:
                    continue
                visited_routes[origin_c.trip_id] = True
                # Check if we can improve the arrival time to the arrival station
                trip_connections = tt.follow_trip(origin_c)

                for following_c in trip_connections:
                    if time_text_to_int(following_c.arrival_time) >= current_target_arrival_time:
                        # We can't improve the arrival time to this station, so we can stop searching this trip
                        break
                    if (following_c.arrival_stop not in visited_stations or \
                        time_text_to_int(following_c.arrival_time) < time_text_to_int(visited_stations[following_c.arrival_stop][0])):
                        # IT is not enough to save station, because if a trip has circles we need to know.
                        # So if this is the best connection to bring us to the station, set the arrival stop of this station to this connection.
                        visited_stations[following_c.arrival_stop] = (following_c.arrival_time, station, following_c, origin_c)
                        next_round_new_stations[following_c.arrival_stop] = following_c.arrival_time
                    
                    if following_c.arrival_stop == end_station:
                        # We found a route !
                        # There is no point further persuing this trip...
                        break
                        # We already visited this station with an earlier arrival time
        res_route = _traverse_route(visited_stations, end_station, start_station)
        result_routes.append(res_route)
        if debug:
            print("round - ", r)
            print("visited stations - ", visited_stations)
            print("new stations - ", new_stations)
            # Disply visited stations. 
            display_visited_stations(tt, visited_stations, start_station=tt.stations[start_station], end_station=tt.stations[end_station])
            print("a")
        new_stations = next_round_new_stations
        next_round_new_stations = {}

    # Now we need to trace back the route
    if end_station not in visited_stations.keys():
        print("No route found :(")
        return None

    # resoult routes should be ordered by number of transfers from base station    
    return result_routes

# base_stop = 44420, maybe 48790
# target_stop = 29462? 14003?
# base_stop = 44420
# base_stop = 44420

# def test_raptor_route_simple():
#     tt = get_tlv_timetable()

#     some_station_connections =  get_some_items(tt.station_connections)
#     some_trip_connections = get_some_items(tt.trip_connections)
#     # print("stop connections - ",some_station_connections[:3])
#     # print("trip connections - ", some_trip_connections[:3])

#     following_trip = tt.follow_trip(list(some_station_connections[0].values())[0][0])
#     start_station = following_trip[0].departure_stop
#     target_station = following_trip[-2].arrival_stop
    
#     time1 = time.time()
#     result_routes = raptor_route(start_station, target_station, following_trip[0].departure_time, tt)   
#     time2 = time.time()
#     print("finished running RAPTOR in {} seconds".format(time2 - time1))
#     if result_routes is None:
#         return

#     last_res_connections =[]
#     for i, res in enumerate(result_routes):
#         print(res)
#         res_connections = get_result_connections(res, tt)
#         if len(res_connections) == len(last_res_connections) and all([res_connections[i] == last_res_connections[i] for i in range(len(res_connections))]):
#             continue
#         print("displaying res for round {i}!!")
#         display_connections(tt, res_connections)
#         last_res_connections = res_connections
    
#     # display_connections(tt, following_trip)

def run_raptor_wrapper(start_stop, end_stop, start_time, tt, debug=False):
    # Filter raptor results and only return distinctive ones
    final_results = []
    result_routes = raptor_route(start_stop, end_stop, start_time, tt, debug=debug)   
    if result_routes is None:
        return None
    last_res_connections = []
    for i, res in enumerate(result_routes):
        if res is None:
            continue
        raptor_res = RaptorResult(res, tt)
        res_connections = raptor_res.result_connections
        if len(res_connections) == len(last_res_connections) and all([res_connections[i] == last_res_connections[i] for i in range(len(res_connections))]):
            continue
        final_results.append(raptor_res)
        last_res_connections = res_connections

    return final_results


def test_ultra_route():
    tt = get_tlv_timetable()
    
    rr = RaptorRouter(tt)
    # glilot base - {"stop_lat": 32.145549, "stop_lon": 34.819354}
    # my home - {"stop_lat": 32.111850, "stop_lon": 34.831520}
    rr.semi_ultra_route({"stop_lat": 32.145549, "stop_lon": 34.819354}, {"stop_lat": 32.111850, "stop_lon": 34.831520}, "10:00:00", tt)

def test_raptor_route():

    time1 = time.time()
    tt = get_tlv_timetable()
    time2 = time.time()
    print("finished loading tlv timetable in {} seconds".format(time2 - time1))

    start_stop = "44420"
    end_stop = "29462"
    time1 = time.time()
    result_raptors = run_raptor_wrapper(start_stop, end_stop, "10:00:00", tt, debug=False)   
    time2 = time.time()
    print("finished running RAPTOR in {} seconds".format(time2 - time1))
    if result_raptors is None:
        return
    
    for r in result_raptors:
        print(r)
        r.display_result()
    
def main():
    # test_raptor_route_simple()
    test_ultra_route()

if __name__ == "__main__":
    main()