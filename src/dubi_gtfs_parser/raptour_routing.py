from utils import BinarySearchIdx, time_text_to_int, get_some_items, time_int_to_text, FOOTPATH_ID, is_footpath, bus_line_from_trip_id
from connection_builder import Connection, Timetable, get_tlv_timetable
from display import display_connections, display_visited_stations, display_RaptorResult
import time
import utils
import os
import pickle
from codetiming import Timer
from dataclasses import dataclass
from valhalla_interface import get_actor 

class RaptorResult_v2():
    def __init__(self, result_route, tt):
        """
        @result_route - a list of tuples (station_id, [connections]), where the last connection in the connection's list is the one arriving at the current station.
        # Note - the first element in the list is the first station, and the last element is the last station
        @tt - timetable object
        """
        # Departure time is the departure time from the first station
        self.departure_time = result_route[0][1][0].departure_time
        # Arrival time is the arrival time to the last station, should be walk connection
        self.arrival_time = result_route[-1][1][-1].arrival_time
        self.result_route = result_route
        self.tt = tt
        self.result_connections = []
        for station, connections in result_route:
            self.result_connections += connections
        self.num_stops = len(self.result_connections) - 2 # remove 2 because of walking...?
        self.num_transfers = len(result_route)-2 # if no transfers, the result route is of length 2 (start station, end station)
        self.trip_time = (time_text_to_int(self.arrival_time) - time_text_to_int(self.departure_time)) / 60
        self.bus_lines = []
        for r in self.result_route:
            line = bus_line_from_trip_id(self.tt, r[1][0].trip_id)
            self.bus_lines.append(line)

    def display_result(self):
        display_RaptorResult(self)

    def __str__(self):
        return f"RaptorResult: departure_time={self.departure_time}, arrival_time={self.arrival_time}, trip_time={self.trip_time}, num_stops={self.num_stops}, num_transfers={self.num_transfers}, bus_lines={self.bus_lines}"


class RaptorRouter(object):
    def __init__(self, tt):
        # All optimizations should be perforemd on the timetable object
        # This class should only be used to route and handle Valhalla API
        self.actor = get_actor(tt)
        # TODO: maybe i should save it like this in tt, to save time here. 
        self.stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in tt.stations.values()]
        self._walking_station_id = 0
  
    
    def _get_walking_start_end_results(self, start_lon_lat, end_lon_lat, tt):
        # load from file if exists
        file_path = os.path.join(utils.ARTIFACTS_FOLDER, f"walking_start_{'_'.join([str(i) for i in start_lon_lat.values()])}_end_{'_'.join([str(i) for i in end_lon_lat.values()])}_results.pkl")
        if os.path.isfile(file_path):
            with Timer(text="[+] loading from file paths from src to all stations took {:.4f} seconds..."):
                sorted_start_to_st, end_footpath_connections = utils.load_artifact(file_path)
        else:
            targets = [end_lon_lat] + self.stations_as_locations
            query = {"sources" :[start_lon_lat], "targets": targets, "costing": "pedestrian"}
            print(f"[+] parsing query - {len(self.stations_as_locations)}")
            with Timer(text="[+] searching paths from src to all stations took {:.4f} seconds..."):
                source_footpath_connections = self.actor.matrix(query)
                sorted_start_to_st = sorted(source_footpath_connections["sources_to_targets"][0], key=lambda x: x["time"])
            # Now in sorted_stt we have all the stations sorted by time to get there by foot from start station.
            # Also the first index in source_footpath_connections["targets"] is the end location, so we already have walking time to it if we want :)

            # Get paths from all other stations to end station
            query = {"sources" : self.stations_as_locations, "targets": [end_lon_lat], "costing": "pedestrian"}
            with Timer(text="[+] searching paths from all stations to dst took {:.4f} seconds..."):
                end_footpath_connections = self.actor.matrix(query)
                #sorted_st_to_end = sorted(source_footpath_connections["sources_to_targets"][0], key=lambda x: x["time"])     
            utils.save_artifact((sorted_start_to_st, end_footpath_connections), file_path)
        
        return sorted_start_to_st, end_footpath_connections


    def semi_ultra_route(self, start_location, end_location, start_time, tt : Timetable, relax_footpaths=True,debug=False, limit_walking_time=60*60):        
        """
        # route using the ULTRA algorithm, but only for the first and last leg of the trip
        # for now we skip optimization for the middle part of the trip, because it requires alot of preprocessing on the graph.
        Algorithm works as follows
        1. Relax footpaths at start and end (using one-to-many implemented in Valhalla)
            1.2 let's start by implementing it as added connections from the start and end stations to all other stations.
        2. Route from start to end using RAPTOR (for now still without relaxing middle footpaths)
        """
        # {"sources":[{"lat":40.744014,"lon":-73.990508}],"targets":[{"lat":40.744014,"lon":-73.990508},{"lat":40.739735,"lon":-73.979713},{"lat":40.752522,"lon":-73.985015},{"lat":40.750117,"lon":-73.983704},{"lat":40.750552,"lon":-73.993519}],"costing":"pedestrian"}
        # Get paths from start to all other stations
        start_lon_lat = {"lat": start_location["stop_lat"], "lon": start_location["stop_lon"]}
        end_lon_lat = {"lat": end_location["stop_lat"], "lon": end_location["stop_lon"]}
        start_station = tt._create_walking_station(start_lon_lat, name="Start")
        end_station = tt._create_walking_station(end_lon_lat, name="End")
        
        sorted_start_to_st, end_footpath_connections = self._get_walking_start_end_results(start_lon_lat, end_lon_lat, tt)
       
        # Now we have all the stations sorted by time to get there by foot from end station, so insert it to the graph!
        # TODO: optimization - it might be faster to search for stations 1 km from me, and only if the algorithm is not satisfied at the end i will search more.
        for i, s_to_t in enumerate(sorted_start_to_st):
            if s_to_t["time"] > limit_walking_time:
                break
            if s_to_t["to_index"] == 0:
                # found path to end location - considered exiting here, but idk if i want to actually. 
                target_station = end_station
            else:
                # Note below, -1 because i also search a path to the end location.
                target_station = list(tt.stations.values())[s_to_t["to_index"]-1]
            
            # create a new trip for this walk
            trip_id = FOOTPATH_ID + "_" + str(i)
            tt.trips[trip_id] = tt.trips[FOOTPATH_ID]  

            # create a connection from start location to this station
            c = Connection(start_station["station_id"], target_station["station_id"], start_time,
             time_int_to_text(time_text_to_int(start_time) + s_to_t["time"]), trip_id)
            
            # TODO: there is an issue here, i can't just append this, i need to insert this at start_time!
            # Because the start station is one we just created, and this for loop is run on a sorted list by time,
            # The station_connections for this station will also be sorted by time and there is no issue here. 
            tt.station_connections[start_station["station_id"]].append(c)

        # Call normal raptor_route, with the exception that now we can relax end footpaths
        return raptor_route(start_station["station_id"], end_station["station_id"], start_time, tt,
                             end_footpath_connections=end_footpath_connections, limit_walking_time=limit_walking_time, debug=debug)

    
@dataclass
class RVisidetStation:
    arrival_time: int
    leading_connections : list[Connection]
    walking_arrival_time_to_end: int # This is the hour at which we will arrive at the target station if we start walking at `arrival_time`

def _traverse_station(station_to_traverse : str, visited_stations : dict[str: RVisidetStation], end_station : str, start_station : str):
    # I got here if the station_to_traverse was a good option to get to the end station.
    # Now i need to iterate through visited_stations, and find the path to this station from the start station
    #end_arrival_time, prev_station, end_connection, prev_connection = visited_stations[end_station]
    result_route = []
    final_walk_connection = Connection(station_to_traverse, end_station, time_int_to_text(visited_stations[station_to_traverse].arrival_time),
             time_int_to_text(visited_stations[station_to_traverse].walking_arrival_time_to_end), FOOTPATH_ID)
    result_route.insert(0, (end_station, [final_walk_connection]))
    prev_station = station_to_traverse
    while prev_station != start_station:
        result_route.insert(0, (prev_station,  visited_stations[prev_station].leading_connections))
        prev_station = visited_stations[prev_station].leading_connections[0].departure_stop
    
    # Insert the first station as well
    # result_route.insert(0, (prev_station, []))
    return result_route

def raptor_route(start_station, end_station, start_time, tt, end_footpath_connections=None, limit_walking_time=1* 60 * 60, debug=False):
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
    # The algorithm is described in the paper "Raptor: Routing with Transit Hubs and Intermediate Stops" by Peter Sanders and Dominik Schultes.
 

    # stations_to_end - This is a dict of station -> time to the end station. Initialise it with the walking time to the end station.
    stations_to_end = {}
    if end_footpath_connections is not None:
        source_stations = list(tt.stations.values())
        for s_to_t in end_footpath_connections["sources_to_targets"]:
            st = source_stations[s_to_t[0]["from_index"]]
            # if s_to_t[0]["time"] > limit_walking_time:
            #     continue
            # Here i can not make a connection, because i don't know the arrival time to the end station.
            """
            visited_stations[following_c.arrival_stop] = (following_c.arrival_time, station, following_c, origin_c)
            next_round_new_stations[following_c.arrival_stop] = following_c.arrival_time
            """
            # This will only work if i traverse the first walking connections before this one... this is not very good
            # shouldn't be thinking of algorithms at 1 AM i guess...
            stations_to_end[st["station_id"]] = s_to_t[0]["time"]
    
   
    # visited_routes is a dict of routes - Do not iterate the same route twice
    visited_routes = {}
   
    # visited_stations is a dict of station_id -> RVisidetStation(arrival_time, leading_connections, walking_arrival_time_to_end)
    visited_stations = {start_station : RVisidetStation(time_text_to_int(start_time), [], time_text_to_int(start_time) + stations_to_end[start_station])}

    new_stations = {start_station: time_text_to_int(start_time)}
    next_round_new_stations = {}
    total_result_routes = []
    MAX_ROUNDS = 4
    current_target_arrival_time = time_text_to_int("23:59:59") + 1000 # initiate to impossible time
    for r in range(MAX_ROUNDS):
        # if end_station in visited_stations:
        #     current_target_arrival_time = visited_stations[end_station].arrival_time

        for station, st_arrival_time in new_stations.items():
            # iterate connections starting from the start_time
            # TODO: think about what to do regarding day-night transitions...
            if station not in tt.station_connections:
                # if station has no connections leaving from it.
                continue
            
            # Check if the arrival time here is later in a significant amount than the current best arrival time
            # (use limit_walking_time as an approximation for flexibility, TODO: maybe i should use a different value here...)
            # Do not simply check if it is later, because maybe we will prefer more transfers and a slightly later arrival time.
            # Note that i will get many like these at the second/third round usually. I've been thinking if there is a way to not get them at all,
            # But it would be difficult because i only calculate current_target_arrival_time at the end of each round. if i'll build it dynamically i might save some time.
            # Maybe a greedy approach for each round will improve this, but for now it's good enough. 
            MAX_TIME_THRESHOLD = current_target_arrival_time + limit_walking_time
            if st_arrival_time > MAX_TIME_THRESHOLD:
                continue

            first_connection = BinarySearchIdx(tt.station_connections[station], st_arrival_time, key=lambda x: time_text_to_int(x.departure_time))
            connections =  tt.station_connections[station][first_connection:]
            # Iterate all connections from station which depart after our arrival time to it.
            for origin_c in connections:
                # Check if we already visited this route
                #if tt.trips[origin_c.trip_id]["route_id"] in visited_routes:
                #    continue
                if origin_c.trip_id in visited_routes:
                   continue

                # Again here i need to check if the arrival time is later than the current best arrival time
                # Break here if not, since connections are sorted by departure time from the station
                if time_text_to_int(origin_c.departure_time) > MAX_TIME_THRESHOLD:
                    break

                visited_routes[origin_c.trip_id] = True
                # Check if we can improve the arrival time to the arrival station
                trip_connections = tt.follow_trip(origin_c)

                for conn_idx, following_c in enumerate(trip_connections):
                    curr_arrival_time = time_text_to_int(following_c.arrival_time) 
                    if curr_arrival_time >= current_target_arrival_time:
                        # We can't improve the arrival time to this station, so we can stop searching this trip
                        break
                    if following_c.arrival_stop not in visited_stations or \
                        curr_arrival_time < visited_stations[following_c.arrival_stop].arrival_time:
                        # It is not enough to save station, because if a trip has circles we need to know.
                        # So if this is the best connection to bring us to the station, set the arrival stop of this station to this connection.
                        # TODO: implement walking to the end stations. i need to approach this with a fresher mind, but what i think
                        # is possible is instead of comparing arrival time, we will compare arrival time + walking time to the end station.
                        
                        # 
                        # V2 - in visited stations, i will save entire connections for this trip, to avoid needing traversing the trip again.
                        # V2 - also calculate walking distance from the end station.
                        visited_stations[following_c.arrival_stop] = RVisidetStation(curr_arrival_time, trip_connections[:conn_idx+1], curr_arrival_time + stations_to_end[following_c.arrival_stop])
                        next_round_new_stations[following_c.arrival_stop] = curr_arrival_time 
                    
                    if following_c.arrival_stop == end_station:
                        # We found a route !
                        # There is no point further persuing this trip...
                        break
        
        # For new stations, find candidates for best walking
        best_walking_time = -1
        best_walking_station = None
        # TODO: get several best stations instead of one - e.g. limit walking time...
        for station, st_arrival_time in next_round_new_stations.items():
            # walking_arrival_time_to_end is relative - it's time of day in which we will arrive at the end if we leave at arrival_time to that station.
            # stations_to_end[station] is the absolute time the walk takes
            if  (best_walking_time == -1 or best_walking_time > visited_stations[station].walking_arrival_time_to_end) \
                and stations_to_end[station] < limit_walking_time:

                best_walking_time = visited_stations[station].walking_arrival_time_to_end 
                best_walking_station = station
       
        round_res_routes = [] # results which where best this round.
        if best_walking_station is not None:
            round_res_routes.append(_traverse_station(best_walking_station, visited_stations, end_station, start_station))
            current_target_arrival_time = best_walking_time
            # Add walking connection to the end station
        
        # for round_res_station in round_res_routes:
        #     res_route = _traverse_station(round_res_station, visited_stations, end_station, start_station)
        total_result_routes.append(round_res_routes)
        if debug:
            print("round - ", r)
            print("visited stations - ", visited_stations)
            print("new stations - ", new_stations)
            # Disply visited stations. 
            print(round_res_routes)
            print(f"best walking time - {time_int_to_text(current_target_arrival_time)}")
            display_visited_stations(tt, visited_stations, start_station=tt.stations[start_station], end_station=tt.stations[end_station])
            print("break")
        # TODO: Relax footpaths from each new station to nearby stations, thus allowing transitions to other stations.
        # This requires calculating shortcuts, which is heavy precomputation, so for now i'll skip it :)))
        new_stations = next_round_new_stations
        next_round_new_stations = {}

    # # Now we need to trace back the route
    # if end_station not in visited_stations.keys():
    #     print("No route found :(")
    #     return None

    # result routes should be ordered by number of transfers from base station    
    return total_result_routes




############################################################
### TEST RAPTOR           ##################################
############################################################


# base_stop = 44420, maybe 48790
# target_stop = 29462? 14003?
# base_stop = 44420
# base_stop = 44420
def run_ultra_wrapper(start_loc, end_loc, start_time, tt, limit_walking_time=60*60, debug=False):
    final_results = []
    rr = RaptorRouter(tt)  
    result_routes = rr.semi_ultra_route(start_loc, end_loc, start_time, tt, limit_walking_time=limit_walking_time, debug=debug)
    if result_routes is None:
        return None
    
    last_res_connections = []
    for i, round_res in enumerate(result_routes):
        for res in round_res:
            if len(res) == 0:
                continue
            raptor_res = RaptorResult_v2(res, tt)
            res_connections = raptor_res.result_connections
            if len(res_connections) == len(last_res_connections) and all([res_connections[i] == last_res_connections[i] for i in range(len(res_connections))]):
                continue
            final_results.append(raptor_res)
            last_res_connections = res_connections
    return final_results

def test_ultra_route():
    tt = get_tlv_timetable()
    print("[+] starting ultra test!")
    
    # rr = RaptorRouter(tt)
    # glilot base - {"stop_lat": 32.145549, "stop_lon": 34.819354}
    # my home - {"stop_lat": 32.111850, "stop_lon": 34.831520}
    with Timer(text="[+] running semi ULTRA took {:.4f} seconds..."):
            result_routes = run_ultra_wrapper({"stop_lat": 32.145549, "stop_lon": 34.819354}, {"stop_lat": 32.111850, "stop_lon": 34.831520}, "10:00:00", 
                                              tt, limit_walking_time=60*15, debug=False)
        
    for r in result_routes:
        print(r)
        r.display_result()
    
    print("[+] finished ultra test!")

def main():
    # test_raptor_route_simple()
    test_ultra_route()

if __name__ == "__main__":
    main()