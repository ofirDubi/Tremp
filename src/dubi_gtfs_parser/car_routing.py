from utils import BinarySearchIdx, time_text_to_int, get_some_items, time_int_to_text, FOOTPATH_ID, CAR_ROUTE_ID, is_footpath, bus_line_from_trip_id
from connection_builder import Connection, Timetable, get_tlv_timetable
from display import display_connections, display_visited_stations, display_RaptorResult, display_stations
import time
import utils
import os
import pickle
from codetiming import Timer
from dataclasses import dataclass
from valhalla_interface import get_actor 
import shapely


def get_faster_car_route(tt, start_loc, end_loc):
    """
    * start_loc: (lat, lon)
    * end_loc: (lat, lon)
    * start_time: text in format "HH:MM:SS"
    Pass the query to valhalla! It uses CH architecture to find the fastest route.
    I could implement a custom routing algorithm, might be fun but it would take ma alot of time
    returns min_times in seconds and min_distance in meters
    """
    # Do a Valhalla optimized route API request to get the walking shape
    actor = get_actor(tt)
    query = {"sources" :[start_loc], "targets": [end_loc], "costing": "auto"}
    # print(f"[+] parsing query - {len(batch_stations_as_locations), len(nearby_stations_as_locations)}")
    res = actor.matrix(query)
    min_time = res['sources_to_targets'][0][0]['time']
    min_distance = res['sources_to_targets'][0][0]['distance']
    return (min_time, min_distance) 


def get_passable_stations(tt, start_loc, end_loc, deviation=60*5, debug=False):
    """
    Let's say deviation=5 min and A to B faster route is X.
    1. search the fastest car route from A to B. set it to X. say we have an agreed deviation time of 5.
    2. Do initial fast pruning of stations by taking an isochrone from A and B and only taking an intersection of the two.
    3. do a one-to-many search from A to every possible station, and many-to-one from very station to B.
        a. This query can be time-limited - the combined journey must be shorter than X+5, so at the least we can limit each of them by X+5.
    4. Prune all of the irrelevant stations - only keep station S if A->S->B takes less than X+5 time. 
    5. At the end we will remain with station that it is possible for the car to pass through.
    
    * deviation - allowed deviation from the fastest car route in seconds
    """ 
    (min_time, min_distance) = get_faster_car_route(tt, start_loc, end_loc)
    actor = get_actor(tt)
    # Do an isochrone search, the limit will be min_time 
    
    
    # TODO: The current algorithm should involve taking a reverse isochrone from stations to end,
    # but it seems like this doesn't really work with the current valhalla API.
    # So the approach would be like so - 
    # Take the X and X/2 isochrones from start to stations and from stations to end.
    # Then only allow for intersections of outer half of start with inner half of end and vice versa. 
    # This is a bit of a hack, but it should provide a minimized enough stations set for one-to-many search (800 is what i got with the naive approach and it was too much).

    query = {"locations" :[start_loc], "contours": [{"time" : min_time/60, "color" : "ff0000"}, {"time" : min_time / 60 / 2, "color" : "00ff00"}], "costing": "auto"}
    start_to_stations = actor.isochrone(query)
    outer_poly_start =  shapely.Polygon(start_to_stations['features'][0]['geometry']['coordinates'])
    inner_poly_start =  shapely.Polygon(start_to_stations['features'][1]['geometry']['coordinates'])
    
    possible_outer_stations_start = []
    possible_inner_stations_start = []
    for s in tt.stations.values():
        p = shapely.Point(s["stop_lon"], s["stop_lat"])
        if outer_poly_start.contains(p):
            possible_outer_stations_start.append(s)
            if inner_poly_start.contains(p):
                possible_inner_stations_start.append(s)

    query = {"locations" :[end_loc], "contours": [{"time" : min_time/60, "color" : "ff0000"}, {"time" : min_time / 60 / 2, "color" : "00ff00"}], "costing": "auto", 
             # Note that this does not work - but it should be something like this
             "reverse" : True, "reverse_flow": True}
    end_to_stations = actor.isochrone(query)


    outer_poly_end =  shapely.Polygon(end_to_stations['features'][0]['geometry']['coordinates'])
    inner_poly_end =  shapely.Polygon(end_to_stations['features'][1]['geometry']['coordinates'])
    
    possible_outer_stations_end = []
    possible_inner_stations_end = []
    for s in tt.stations.values():
        p = shapely.Point(s["stop_lon"], s["stop_lat"])
        if outer_poly_end.contains(p):
            possible_outer_stations_end.append(s)
            if inner_poly_end.contains(p):
                possible_inner_stations_end.append(s)


    # Now take intersection of inner start with outer end and vice versa
    # Intersetcion of outer end with inner start
    possible_stations = []
    for s in possible_outer_stations_end:
        if s in possible_inner_stations_start:
            possible_stations.append(s)

    for s in possible_outer_stations_start:
        if s in possible_inner_stations_end and s not in possible_stations:
            possible_stations.append(s)
  
    # I need to do pruning with a reverse isochrone search, from the end location to the stations.
    # Another option is do an X(where X is time to target) isochrone search from destenation, and then do a X isochrone search 
    # from the end destenations to the station, and only take the intersection
    with Timer(text="[+] Getting stations after initial pruning took {:.4f} seconds..."):
        # Note - this took 3 seconds for me for a 15 min trip with 5 min deviation, not so good
        matches = get_passable_stations_with_one_to_many(tt, start_loc, end_loc, deviation=deviation, debug=debug, possible_stations=possible_stations)
    
    return matches  


def get_passable_stations_with_one_to_many(tt, start_loc, end_loc, deviation=60*5, debug=False, min_time=None, possible_stations=None):
    """
    Let's say deviation=5 min and A to B faster route is X.
    1. search the fastest car route from A to B. set it to X. say we have an agreed deviation time of 5.
    2. do a one-to-many search from A to every station, and many-to-one from very station to B.
        a. This query can be time-limited - the combined journey must be shorter than X+5, so at the least we can limit each of them by X+5.
    3. Prune all of the irrelevant stations - only keep station S if A->S->B takes less than X+5 time. 
    4. At the end we will remain with station that it is possible for the car to pass through.
    
    * deviation - allowed deviation from the fastest car route in seconds
    * possible_stations - list of stations to check, if None, all stations will be checked
    Without this list this algorithm is not viable, a s doing one-to-many for all stations is too expensive.
    This list should be gathered by a previous isochrone search. to minimize possiblities for sutable stations.
    Note that maybe we can devise a better algorithm - something that does one-to-many and many-to-one at the same time and is limited by total time it would take.

    * return - [(station, time_from_start, time_to_end), ....] - list of stations that are possible to pass through within time limit
    """ 

    # Get the fastest car route, if not provided
    if min_time is None:
        (min_time, min_distance) = get_faster_car_route(tt, start_loc, end_loc)

    if not possible_stations:
        possible_stations = tt.stations.values()

    # 1. do one to many from A to stations - 
    stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in possible_stations]
    actor = get_actor(tt)
    # TODO: optimization - set a time limit here to not search for all stations...
    # This is too expensive for my PC... i need to try a different approach
    query = {"sources" :[start_loc], "targets": stations_as_locations, "costing": "auto"}
    start_to_stations = actor.matrix(query)
    valid_stations_p1 = []
    print("finished first query!")
    # Prune invalid stations
    for i, station in enumerate(possible_stations):
        if start_to_stations['sources_to_targets'][0][i]['time'] < min_time + deviation:
            valid_stations_p1.append((station, start_to_stations['sources_to_targets'][0][i]['time']))

    stations_as_locations = [{"lat": s[0]["stop_lat"], "lon": s[0]["stop_lon"]} for s in valid_stations_p1]
    actor = get_actor(tt)
    # TODO: optimization - set a time limit here to not search for all stations...
    query = {"sources" :stations_as_locations, "targets": [end_loc], "costing": "auto"}
    stations_to_end = actor.matrix(query)
    valid_stations_p2 = []
    # Prune invalid station
    for i, (station, start_so_station_time) in enumerate(valid_stations_p1):
        if stations_to_end['sources_to_targets'][i][0]['time'] + start_so_station_time < min_time + deviation:
            valid_stations_p2.append((station, start_so_station_time, stations_to_end['sources_to_targets'][i][0]['time']))
    return valid_stations_p2


def build_connections_for_car_route(tt, start_loc, end_loc, start_time, deviation=60*5, debug=False):
    """
    get possible stations, and build connections out of them to add to the time table 
    # This does the affected changes on the timetable.
    """

    # First i need to add a stations for the start_loc and end_loc
    start_station = tt._create_walking_station(start_loc, "car_start")
    end_station = tt._create_walking_station(end_loc, "car_end")

    valid_stations = get_passable_stations(tt, start_loc, end_loc, deviation=deviation, debug=debug)
    for i, s in enumerate(valid_stations):
        trip_id = CAR_ROUTE_ID + "_" + str(i)
        tt.trips[trip_id] = tt.trips[CAR_ROUTE_ID]  

        c = Connection(start_station, s[0], start_time, s[1], trip_id)
        tt.station_connections[start_station["station_id"]].append(c)
        c2 = Connection(s[0], end_station, s[1], s[2], trip_id)
        tt.station_connections[end_station["station_id"]].append(c2)

    return valid_stations

############################################################
### TEST Car           ####################################
############################################################




def main():
    # glilot base - {"stop_lat": 32.145549, "stop_lon": 34.819354}
    # my home - {"stop_lat": 32.111850, "stop_lon": 34.831520}
    tt = get_tlv_timetable()
    print("[+] starting ultra test!")
    with Timer(text="[+] Getting possible stations for journey took {:.4f} seconds..."):
        # Note - this takes 2.5-3.5 seconds for me for a 15 min trip with 5 min deviation, not so good.
        # Initial pruning with isochrones takes 0.7 seconds, then one-to-many takes 2 seconds.
        # Maybe i can prune more stations after i have initial raptor results - it might be so that some stations won't be optimal and can be dropped.
        valid_stations = get_passable_stations(tt, {"lat": 32.145549, "lon": 34.819354}, {"lat": 32.111850, "lon": 34.831520})
    
    valid_stations_s = [s[0] for s in valid_stations]
    display_stations(valid_stations_s)
    print("break")
if __name__ == "__main__":
    main()