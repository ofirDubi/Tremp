from parse_gtfs import get_is_gtfs, get_is_tlv_gtfs, GTFS
from utils import ARTIFACTS_FOLDER, get_some_items, print_log, error_log_to_file, load_artifact, save_artifact
from display import display_connections
import os

IS_GTFS_FOLDER = "../is_gtfs"
TLV_TIMETABLE_OBJ = os.path.join(ARTIFACTS_FOLDER, "tlv_timetable_obj.obj")


# What i need - a list of connection. a connection is a tuple of 5  elements:
# - depatrue stop
# - arrival stop
# - depatrue time
# - arrival time
# - trip id (trip is a sequence of connections)
class Connection(object):
    def __init__(self, departure_stop, arrival_stop, departure_time, arrival_time, trip_id, shapes):
        self.departure_stop = departure_stop
        self.arrival_stop = arrival_stop
        self.departure_time = departure_time
        self.arrival_time = arrival_time
        self.trip_id = trip_id
        self.shapes = shapes # this is used to represent the connection on a map. 
    def __repr__(self):
        return f"Connection({self.departure_stop}, {self.arrival_stop}, {self.departure_time}, {self.arrival_time}, {self.trip_id})"


class Timetable(object):
    # timetable is a list of connections, sorted by departure time
    # Each stop has a list of connections that depart from it, sorted by departure time
    def __init__(self, gtfs):
        # self.timetable = []
        self.stop_connections = {}
        self.trip_connections = {}

        # Just copy stations and trips from gtfs
        self.stations = gtfs.stations
        self.trips = gtfs.trips
        self.build_timetable(gtfs)

    def build_timetable(self, gtfs):
        # A connection is besically two following stations, so each pair of stops will be a connection.
        # Pretty easy.
        # First i will make the connections, then i will attribute them to the stops 
        for trip_id, trip_stops in gtfs.stop_times.items():
            prev_stop = trip_stops[0]
            for stop in trip_stops[1:]:
                # At this point we count on trip_stops to be sorted by stop_sequence and departure time.
                # Get the set of shapes that represent this connection
                

                connection = Connection(prev_stop["stop_id"], stop["stop_id"], prev_stop["departure_time"], stop["arrival_time"], trip_id)
                # Add connection to the previous stop.
                if prev_stop["stop_id"] not in self.stop_connections:
                    self.stop_connections[prev_stop["stop_id"]] = []
                
                self.stop_connections[prev_stop["stop_id"]].append(connection)
                if trip_id not in self.trip_connections:
                    self.trip_connections[trip_id] = []
                self.trip_connections[trip_id].append(connection)
                # self.timetable.append(connection)
                prev_stop = stop
            connection = {}
        
        # For each stop, sort the connections by departure time
        for stop_id in self.stops.keys():
            if stop_id not in self.stop_connections:
                continue
            self.stop_connections[stop_id] = sorted(self.stop_connections[stop_id], key=lambda x: x.departure_time) 
        print(f"got {len(self.stops)} stops, out of them {len(self.stop_connections)} with connections")

    def follow_trip(self, connection):
        # Receive a connection, and return a list of FOLLOWING connections that are in the same trip
        # The list will be sorted by departure time
        trip_connections = self.trip_connections[connection.trip_id]
        # Find where this connection is placed in the trip
        connection_index = trip_connections.index(connection)
        # Return all following trips
        return trip_connections[connection_index:]

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


def test_tlv_timetable():
    # tt = get_tlv_timetable()
    tt = get_tlv_timetable(True, True)
    some_stop_connections =  get_some_items(tt.stop_connections)
    some_trip_connections = get_some_items(tt.trip_connections)
    print("stop connections - ",some_stop_connections[:3])
    print("trip connections - ", some_trip_connections[:3])

    following_trip = tt.follow_trip(list(some_stop_connections[0].values())[0][0])
    print("following trip - ", following_trip)
    display_connections(following_trip)

def main():
    test_tlv_timetable()

if __name__ == '__main__':
    main()