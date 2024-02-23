from parse_gtfs import get_is_gtfs, get_is_tlv_gtfs, GTFS
from utils import ARTIFACTS_FOLDER, FOOTPATH_ID, is_footpath, is_car_route, get_some_items, print_log, error_log_to_file, load_artifact, save_artifact, decode_polyline, BinarySearchIdx, degrees_to_meters, further_than_length
from display import display_connections, display_all_gtfs_stations, display_stations, display_connections
import os
import math
from codetiming import Timer
from valhalla_interface import get_actor 

IS_GTFS_FOLDER = "../is_gtfs"
TLV_TIMETABLE_OBJ = os.path.join(ARTIFACTS_FOLDER, "tlv_timetable_obj.obj")



class SearchableStations(object):
    # Right now stations are grouped by id. i want to craete a stations array sorted by X, so it is searchable.
    # For maximum searchability, i will group each 100 meters of X into a bucket, which will later be sorted by Y value
    # TODO: make some expiriments and see how different bucket size affects search time
    # TODO: make this save sorted stations in a DB instead of in-memory (although paging is a thing, so maybe OS to the rescue?)
    def __init__(self, stations, BUCKET_SIZE=100):
        """
        @stations - a list of stations, by id
        @BUCEKT_SIZE - the size of each bucket in meters.
        """
        # self.stations = stations
        self.BUCKET_SIZE = BUCKET_SIZE
        self.sorted_stations = self._sort_stations(stations)

    def _sort_stations(self, stations):
        # Sort stations by X value, then group them into buckets of BUCKET_SIZE, then sort each bucket by Y value
        sorted_stations_ungrouped = sorted(stations, key=lambda x: float(x["stop_lon"]))
        sorted_stations = []
        current_bucket_x = degrees_to_meters(sorted_stations_ungrouped[0]["stop_lon"]) -  (degrees_to_meters(sorted_stations_ungrouped[0]["stop_lon"]) % self.BUCKET_SIZE) 
        current_bucket = [current_bucket_x]

        for station in sorted_stations_ungrouped:

            if degrees_to_meters(float(station["stop_lon"])) - current_bucket_x > self.BUCKET_SIZE:
                # We are done with this bucket. Sort it and add it to the list
                current_bucket = [current_bucket[0]] + sorted(current_bucket[1:], key=lambda x: float(x["stop_lat"]))
                sorted_stations.append(current_bucket)
                current_bucket_x = degrees_to_meters(float(station["stop_lon"])) - (degrees_to_meters(float(station["stop_lon"])) % self.BUCKET_SIZE)
                current_bucket = [current_bucket_x]
            else:
                current_bucket.append(station)

        # Add the last bucket
        current_bucket = [current_bucket[0]] + sorted(current_bucket[1:], key=lambda x: float(x["stop_lat"]))
        sorted_stations.append(current_bucket)
        return sorted_stations

    def search_nearby_stations(self, station, radius=1000):
        """
        @station - a station object
        @radius - the radius in meters to search for stations
        """
        results = []
        # Search for stations that are nearby the given station
        target_location = (station["stop_lon"], station["stop_lat"])
        target_location_meters = (degrees_to_meters(station["stop_lon"]),  degrees_to_meters(station["stop_lat"]))
        # Search for stations in the same bucket
        target_x = float(station["stop_lon"])
        target_y = float(station["stop_lat"])

        # sorted_stations is an array of buckets, each bucket's first element is the bucket lon in meters, following by a list of stations sorted by Y value
        bucket_x_idx = BinarySearchIdx(self.sorted_stations, degrees_to_meters(target_x), key=lambda x: float(x[0]))

        max_bucket_x_radius = math.ceil(radius / self.BUCKET_SIZE)
        start_search_idx = bucket_x_idx - max_bucket_x_radius - 1
        if start_search_idx < 0:
            start_search_idx = 0
        end_search_idx = bucket_x_idx + max_bucket_x_radius
        if end_search_idx > len(self.sorted_stations):
            end_search_idx = len(self.sorted_stations)

        # Search for stations in the same bucket radius
        for i, probable_stations in enumerate(self.sorted_stations[start_search_idx: end_search_idx]):
            

            # Discard the first item, which is the bucket lon
            probable_stations = probable_stations[1:]
            # probable_stations are Y ordered.
            # Search for stations in the same Y radius, Y is not stored in meters, but in degrees.
            starting_y_idx = BinarySearchIdx(probable_stations, target_y, key=lambda x: float(x["stop_lat"]))

            # TODO - this can be more efficient - we can search for the first station that is further than radius with binary search, and then search backwards
            # The only cavity here is that because of X variance we might be off by a BUCKET_SIZE.
            # Honestly i can just say i'm okay to give an accurecy of BUCKET_SIZE, and that's it.
            # Another better optimization - for each X bucket we have BREATH = radius - (BUCKET_SIZE * abs(i - bucket_x_idx))
            # We can do binary search to find edges of where BREATH ends. 
            # This way we get log(y) instead of y, and when dealing with large areas (above 1 KM) this becomes substatial.
            # For now iterate every station that is a possible match, the massive optimization should have been done by the X search 
            # 33843, 14161, 48790
            # Search up until i hit radius or higher 
            current_y_idx = starting_y_idx
            while current_y_idx < len(probable_stations):
                current_target_station = probable_stations[current_y_idx]
                current_target_location_meters = (degrees_to_meters(current_target_station["stop_lon"]),  degrees_to_meters(current_target_station["stop_lat"]))

                # Note below - We added self.BUCKET_SIZE to the search in order to make sure we don't miss any stations
                # Because Y sort does not garantee that the next station is closer to the target station, there is X variance of up to BUCEKT_SIZE
                if further_than_length(target_location_meters, current_target_location_meters, radius+self.BUCKET_SIZE):
                    break

                results.append(current_target_station)
                current_y_idx += 1
            
            # Search down until i hit radius or lower
            if starting_y_idx == 0:
                continue
            current_target_station = probable_stations[starting_y_idx-1] 
            current_target_location_meters = (degrees_to_meters(current_target_station["stop_lon"]),  degrees_to_meters(current_target_station["stop_lat"]))
            current_y_idx = starting_y_idx-1
            while current_y_idx >= 0:
                current_target_station = probable_stations[current_y_idx]
                current_target_location_meters = (degrees_to_meters(current_target_station["stop_lon"]),  degrees_to_meters(current_target_station["stop_lat"]))
                if further_than_length(target_location_meters, current_target_location_meters, radius+self.BUCKET_SIZE):
                    break
                results.append(current_target_station)
                current_y_idx -= 1
              
        
        return results

# What i need - a list of connection. a connection is a tuple of 5  elements:
# - depatrue stop
# - arrival stop
# - depatrue time
# - arrival time
# - trip id (trip is a sequence of connections)
class Connection(object):
    def __init__(self, departure_stop, arrival_stop, departure_time, arrival_time, trip_id):
        self.departure_stop = departure_stop # actual stop obj
        self.arrival_stop = arrival_stop # actual stop obj
        if type(departure_time) != str or type(arrival_time) != str:
            raise AssertionError("departure_time and arrival_time should be strings")
        self.departure_time = departure_time # in text format hh:mm:ss
        self.arrival_time = arrival_time # in text format hh:mm:ss
        self.trip_id = trip_id
        self.shapes = None
        # self.shapes = shapes # this is used to represent the connection on a map. 
    def __repr__(self):
        return f"Connection({self.departure_stop}, {self.arrival_stop}, {self.departure_time}, {self.arrival_time}, {self.trip_id})"

class Timetable(object):
    # timetable is a list of connections, sorted by departure time
    # Each stop has a list of connections that depart from it, sorted by departure time
    def __init__(self, gtfs):
        # self.timetable = []
        self.station_connections = {}
        self.trip_connections = {}

        # Add _walking_station_id 
        self._walking_station_id = 0

        # Just copy stations and trips from gtfs
        self.stations = gtfs.stations
        self.trips = gtfs.trips
     
        self.shapes = gtfs.shapes
        self.gtfs_instance = gtfs
        self.searchable_stations = SearchableStations(self.stations.values(),)
        self._build_timetable(gtfs)
        self.stations_footpaths = self.build_station_footpaths()

        
    def _create_walking_station(self, station_lon_lat, name="Walking"):
        self._walking_station_id += 1
        new_station = {"station_id" : str(self._walking_station_id), "stop_lon": station_lon_lat["lon"], "stop_lat": station_lon_lat["lat"], "stop_name" : name} 
        self.stations[str(self._walking_station_id)] = new_station
        self.station_connections[str(self._walking_station_id)] = []
        return new_station
    
    def _get_route_connection_shape(self, connection : Connection, costing="pedestrian"):

        if connection.shapes is not None:
            return # already found shapes for this

        # Do a Valhalla optimized route API request to get the walking shape
        actor = get_actor(self)
        start_lon_lat = {"lat": self.stations[connection.departure_stop]["stop_lat"], "lon": self.stations[connection.departure_stop]["stop_lon"]}
        end_lon_lat = {"lat": self.stations[connection.arrival_stop]["stop_lat"], "lon": self.stations[connection.arrival_stop]["stop_lon"]}
        query = {"locations": [start_lon_lat, end_lon_lat], "costing": costing, "directions_options": {"units":"meters"}}
        
        route_res = actor.optimized_route(query)
        decoded_shapes_lon_lat = decode_polyline(route_res["trip"]["legs"][0]["shape"])
        decoded_shapes = []
        for i, shape in enumerate(decoded_shapes_lon_lat):
            decoded_shapes.append({ 'shape_pt_lon' : shape[0], 'shape_pt_lat' :shape[1], 'shape_id' : connection.trip_id, 'shape_pt_sequence' : i+1})
        connection.shapes = decoded_shapes
    
    def build_station_footpaths(self, nearby_station_radius=1000, max_walking_distance = 1.2):
        '''
        This is a preprocessing step for the timetable.
        In here we will create footpath connections between stations that are close to each other.
        This will be saved in a special filed as a dict by station, and will be used in RAPTOR in the "Relax footpath" phase.
        In order to get results in a sensible time, limit search radius to 'nearby_station_radium'.
        In production we can enlarge this.
        How we will do it - 
        For each station, We will use SearchableStation class to find nearby stations, and use Valhalla one-to-many API to find walking paths between them.
        In concept this preprocessing saves me from the need later to run this on every station every query.
        
        * max_walking_distance - in KM, because this is how results from valhalla return
        '''

        # Note that also here i want to save time sending batches to valhalla, so for each station i will take all of the station in 1 km radius, then find many to many on a  2 KM radius.
        
        # This is the result. station -> [(station, path)]
        station_to_station_footpaths = {}

        # le'ts just go station by station
        for station in self.stations.values():
            if station['station_id'] in station_to_station_footpaths:
                # We already did this station with some other batch
                continue
            # initiate to empty list
            station_to_station_footpaths[station["station_id"]] = []

            # Find nearby stations
            # originally it was 1 and 2, but my PC couldn't carry it so i lower it so /2 and 1.5
            factor = 1
            batch_stations  = []
            batch_stations = self.searchable_stations.search_nearby_stations(station, nearby_station_radius / factor)
            while len(batch_stations) > 20 and factor < 15: 
                # If i got more than 20 this will be bad when i increase the amount i guess, so  
                factor +=1
                batch_stations = self.searchable_stations.search_nearby_stations(station, nearby_station_radius / factor)

            nearby_stations = self.searchable_stations.search_nearby_stations(station, nearby_station_radius + nearby_station_radius / factor)
            batch_stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in batch_stations]
            nearby_stations_as_locations = [{"lat": s["stop_lat"], "lon": s["stop_lon"]} for s in nearby_stations]
            
            actor = get_actor(self)
            query = {"sources" :batch_stations_as_locations, "targets": nearby_stations_as_locations, "costing": "pedestrian"}
            # print(f"[+] parsing query - {len(batch_stations_as_locations), len(nearby_stations_as_locations)}")
            source_footpath_connections = []
            source_footpath_connections = actor.matrix(query)
            for i, st in enumerate(batch_stations):
                footpaths = []
                for f in source_footpath_connections['sources_to_targets'][i]:
                    if f["distance"] > max_walking_distance or nearby_stations[f["to_index"]]["station_id"] == st["station_id"]:
                        continue
                    footpaths.append({"station_id": nearby_stations[f["to_index"]]["station_id"], "distance": f["distance"], "time": f["time"]})
                
                # Sort by walking time 
                station_to_station_footpaths[st["station_id"]] = sorted(footpaths, key=lambda x: x["time"])             
                #sts = [self.stations[fp["station_id"]] for fp in footpaths]
                #display_station_footpaths(self, st, footpaths)
                #display_stations(self, sts)

            # For tests break now
            # call valhalla many to many
        print("finished finding footpaths between stations!")
        return station_to_station_footpaths


    def _build_timetable(self, gtfs):
        # A connection is besically two following stations, so each pair of stops will be a connection.
        # Pretty easy.
        # First i will make the connections, then i will attribute them to the stops 
        for trip_id, trip_stops in gtfs.stop_times.items():
            self.trip_connections[trip_id] = []
            prev_stop = trip_stops[0]
            for stop in trip_stops[1:]:
                # At this point we count on trip_stops to be sorted by stop_sequence and departure time.
                # Get the set of shapes that represent this connection
                connection = Connection(prev_stop["station_id"], stop["station_id"], prev_stop["departure_time"], stop["arrival_time"], trip_id)
                # Add connection to the previous stop.
                if prev_stop["station_id"] not in self.station_connections:
                    self.station_connections[prev_stop["station_id"]] = []
                
                self.station_connections[prev_stop["station_id"]].append(connection)
                # if trip_id not in self.trip_connections:
                #     self.trip_connections[trip_id] = []
                self.trip_connections[trip_id].append(connection)
                # self.timetable.append(connection)
                prev_stop = stop
            connection = {}
        
        # For each stop, sort the connections by departure time
        for station_id in self.stations.keys():
            if station_id not in self.station_connections:
                continue
            self.station_connections[station_id] = sorted(self.station_connections[station_id], key=lambda x: x.departure_time) 
        print(f"got {len(self.stations)} stations, out of them {len(self.station_connections)} with connections")

    def follow_trip(self, connection, toConnection=False):
        # Receive a connection, and return a list of FOLLOWING connections that are in the same trip
        # The list will be sorted by departure time
        if connection.trip_id not in self.trip_connections:
            if not is_footpath(connection.trip_id) and not is_car_route(connection.trip_id):
                # For now this should only be valid for footpaths
                raise AssertionError("Trip id not found in trip connections")
            return [connection]
        
        trip_connections = self.trip_connections[connection.trip_id]
        # Find where this connection is placed in the trip
        # TODO: Change this to binary search
        connection_index = trip_connections.index(connection)
        # Return all following trips
        if toConnection:
            return trip_connections[:connection_index+1]
        else:
            return trip_connections[connection_index:]

    def match_shapes_to_connections(self, connections):
        # Assume all connections are from the same trip here. 
        trip_id = connections[0].trip_id
        if is_footpath(trip_id):
            for c in connections:
                self._get_route_connection_shape(c)
            return
        if is_car_route(trip_id):
            for c in connections:
                self._get_route_connection_shape(c, costing="auto")
            return
            
        stop_times = self.gtfs_instance.match_stops_to_shapes_for_trip(trip_id)
        # match stop_time to connection by station
        connections_by_station = {}
        for c in connections:
            if c.departure_stop not in connections_by_station:
                connections_by_station[c.departure_stop] = [c]
            connections_by_station[c.departure_stop].append(c)
        for stop in stop_times:
            if stop["station_id"] not in connections_by_station:
                # This stop is not in the connections list, so we can't match it to a connection
                continue
            stop_cons = connections_by_station[stop["station_id"]]
            # If there are more then one connections, satisfy the first one in the list.
            # Do a pop so it removes the other one! 
            con = stop_cons.pop(0)
            con.shapes = stop["shapes"]
        # Do sanity check that all connections have shapes
        for c in connections:
            if c.shapes is None:
                print(f"connection {c} does not have shapes!")
                print(f"connections_by_station - {connections_by_station}")
                print(f"stop_times - {stop_times}")
                raise Exception("Connection does not have shapes!")

def get_tlv_timetable(reparse=False, full_reparse=False):
    if os.path.isfile(TLV_TIMETABLE_OBJ) and not reparse:
        print_log("loading tlv timetable from file...")
        return load_artifact(TLV_TIMETABLE_OBJ)
    else:
        print_log("parsing tlv timetable from gtfs...")
        if(full_reparse):
            gtfs = get_is_tlv_gtfs(full_reparse, full_reparse)
        else:
            gtfs = get_is_tlv_gtfs()
        tt = Timetable(gtfs)
        save_artifact(tt, TLV_TIMETABLE_OBJ)
        return tt


def test_searchable_stations():
    # tt = get_tlv_timetable(True)
    tt = get_tlv_timetable()
    start_stop = "44420"
    # 33843, 14161, 48790
    start_station = tt.stations[start_stop]
    print("start station - ", start_station)
    print("searching for stations near start station...")
    
    with Timer(text="searching for stations near start station with 200 radius took {:.4f} seconds..."):
        nearby_stations_200 = tt.searchable_stations.search_nearby_stations(start_station, 200)
    print(f"got {len(nearby_stations_200)} stations")
    # display_stations(nearby_stations_200, marker_station=start_station, radius=200)

    with Timer(text="searching for stations near start station with 500 radius took {:.4f} seconds..."):
        nearby_stations_500 = tt.searchable_stations.search_nearby_stations(start_station, 500)
    print(f"got {len(nearby_stations_500)} stations")
    # display_stations(nearby_stations_500, start_station, radius=500)
    
    with Timer(text="searching for stations near start station with 1000 radius took {:.4f} seconds..."):
        nearby_stations_1000 = tt.searchable_stations.search_nearby_stations(start_station, 1000)
    print(f"got {len(nearby_stations_1000)} stations")
    # display_stations(nearby_stations_1000, start_station, radius=1000)

    with Timer(text="searching for stations near start station with 10000 radius took {:.4f} seconds..."):
        nearby_stations_10000 = tt.searchable_stations.search_nearby_stations(start_station, 10000)
    print(f"got {len(nearby_stations_10000)} stations")
    # display_stations(nearby_stations_10000, start_station, radius=10000)

def test_tlv_timetable():
    tt = get_tlv_timetable()
    # tt = get_tlv_timetable(True, True)
    # tt = get_tlv_timetable(True)
    some_station_connections =  get_some_items(tt.station_connections)
    some_trip_connections = get_some_items(tt.trip_connections)
    print("stop connections - ",some_station_connections[:3])
    print("trip connections - ", some_trip_connections[:3])

    following_trip = tt.follow_trip(list(some_station_connections[0].values())[0][0])
    print("following trip - ", following_trip)
    display_all_gtfs_stations(tt.gtfs_instance, 1)
    display_connections(tt, following_trip)
    print("done!")

def test_stations_footpaths():
    tt = get_tlv_timetable()
    # print(f"footpaths - {tt.stations_footpaths}")
    with Timer(text="[+] searching footpaths from stations took {:.4f} seconds..."):
        tt.stations_footpaths = tt.build_station_footpaths()
    save_artifact(tt, TLV_TIMETABLE_OBJ)

def display_station_footpaths(tt, station, station_footpaths):
    # Just fake connections for each footpath and display them as connections
    connections = []
    
    for i, footpath in enumerate(station_footpaths):
        # create a new trip for this walk
        # create a connection from start location to this station
        trip_id = FOOTPATH_ID + "_" + str(i)
        tt.trips[trip_id] = tt.trips[FOOTPATH_ID]  

        c = Connection(station["station_id"], footpath["station_id"], "00:00:00",
            "00:00:00", trip_id)
        connections.append(c)
    display_connections(tt, connections)



def main():
    # test_stations_footpaths()
    # get_tlv_timetable(reparse=True, full_reparse=True)
    # test_searchable_stations()
    # test_tlv_timetable()
    pass

if __name__ == '__main__':
    main()