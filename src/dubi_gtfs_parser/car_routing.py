from utils import BinarySearchIdx, time_text_to_int, get_some_items, time_int_to_text, FOOTPATH_ID, is_footpath, bus_line_from_trip_id
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
    """
    # Do a Valhalla optimized route API request to get the walking shape
    actor = get_actor(tt)
    query = {"sources" :[start_loc], "targets": [end_loc], "costing": "auto"}
    # print(f"[+] parsing query - {len(batch_stations_as_locations), len(nearby_stations_as_locations)}")
    res = actor.matrix(query)
    min_time = res['sources_to_targets'][0][0]['time']
    min_distance = res['sources_to_targets'][0][0]['distance']
    return (min_time, min_distance) 


def get_passable_stations2(tt, start_loc, end_loc, deviation=60*5, debug=False):
    """
    Let's say deviation=5 min and A to B faster route is X.
    1. search the fastest car route from A to B. set it to X. say we have an agreed deviation time of 5.
    2. do a one-to-many search from A to every station, and many-to-one from very station to B.
        a. This query can be time-limited - the combined journey must be shorter than X+5, so at the least we can limit each of them by X+5.
    3. Prune all of the irrelevant stations - only keep station S if A->S->B takes less than X+5 time. 
    4. At the end we will remain with station that it is possible for the car to pass through.
    
    * deviation - allowed deviation from the fastest car route in seconds
    """ 
    (min_time, min_distance) = get_faster_car_route(tt, start_loc, end_loc)
    actor = get_actor(tt)
    # Do an isochrone search, the limit will be min_time 
    
    query = {"locations" :[start_loc], "contours": [{"time" : min_time/60, "color" : "ff0000"}], "costing": "auto"}
    start_to_stations = actor.isochrone(query)
    ## TODO: use shapely to check for each station if it's within the isochrome
    # Should be something like this  - 
    # a= shapely.contains(start_to_stations['features'][0]['geometry'], np.array(p))
    print("break")

def get_passable_stations(tt, start_loc, end_loc, deviation=60*5, debug=False):
    """
    Let's say deviation=5 min and A to B faster route is X.
    1. search the fastest car route from A to B. set it to X. say we have an agreed deviation time of 5.
    2. do a one-to-many search from A to every station, and many-to-one from very station to B.
        a. This query can be time-limited - the combined journey must be shorter than X+5, so at the least we can limit each of them by X+5.
    3. Prune all of the irrelevant stations - only keep station S if A->S->B takes less than X+5 time. 
    4. At the end we will remain with station that it is possible for the car to pass through.
    
    * deviation - allowed deviation from the fastest car route in seconds
    """ 
    (min_time, min_distance) = get_faster_car_route(tt, start_loc, end_loc)

    # 1. do one to many from A to stations - 
    stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in tt.stations.values()]
    actor = get_actor(tt)
    # TODO: optimization - set a time limit here to not search for all stations...
    # This is too expensive for my PC... i need to try a different approach
    query = {"sources" :[start_loc], "targets": stations_as_locations, "costing": "auto"}
    start_to_stations = actor.matrix(query)
    valid_stations_p1 = []
    print("finished first query!")
    # Prune invalid stations
    for i, station in enumerate(tt.stations.values()):
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
            valid_stations_p2.append(station, start_so_station_time, stations_to_end['sources_to_targets'][i][0]['time'])
    return valid_stations_p2

############################################################
### TEST Car           ####################################
############################################################


def main():
    # glilot base - {"stop_lat": 32.145549, "stop_lon": 34.819354}
    # my home - {"stop_lat": 32.111850, "stop_lon": 34.831520}
    tt = get_tlv_timetable()
    print("[+] starting ultra test!")
    with Timer(text="[+] Getting possible stations for journey took {:.4f} seconds..."):
        valid_stations = get_passable_stations2(tt, {"lat": 32.145549, "lon": 34.819354}, {"lat": 32.111850, "lon": 34.831520})
    
    valid_stations_s = [s[0] for s in valid_stations]
    display_stations(valid_stations_s)
    print("break")
if __name__ == "__main__":
    main()