import os
import matplotlib.pyplot as plt
import tilemapbase
import time

from display import display_gtfs_stations, display_gtfs_stations_for_trip

from utils import *

VALIDATE = True
COMPLETE_PARSE = False

IS_GTFS_FOLDER = "../is_gtfs"
IS_GTFS_OBJ = os.path.join(ARTIFACTS_FOLDER, "is_gtfs_obj.obj")
TLV_GTFS_OBJ = os.path.join(ARTIFACTS_FOLDER, "tlv_gtfs_obj.obj")

#               (min_lon, max_lon, min_lat, max_lat)
TEL_AVIV_AREA = (34.7127, 34.9437, 31.9280, 32.2012)
class CSVParser:
    def __init__(self, file_path) -> None:
        self.file_path = file_path

    def parse(self, id_tag, dup_ids_allowed=False, validator=None): 
        with open(self.file_path, "r", encoding="utf-8-sig") as f:
            # read file header and see all 
            header = f.readline().replace("\n", "")
            fields = header.split(",")
            res = {}
            for line in f:
                line_dict = {}
                line_data = line.replace("\n", "").split(",")
                for i in range(len(fields)):
                    if i >= len(line_data):
                        line_dict[fields[i]] = None
                    else:
                        line_dict[fields[i]] = line_data[i]

                # if validator is not None:
                #     # This should throw if we get something bad
                #     validator(line_dict)
                if line_dict[id_tag] in res:
                    if not dup_ids_allowed:
                        raise ValueError("Got duplicate id - ", line_dict[id_tag])
                    else:
                        res[line_dict[id_tag]].append(line_dict)
                elif dup_ids_allowed:
                    res[line_dict[id_tag]] = [line_dict]
                else:
                    # No dups allowed, so treat this as a dict of objects, not lists
                    res[line_dict[id_tag]] = line_dict
            return res


class GTFS:
    """

    This class represent a parsed GTFS folder.
    It should contain the following data (might be more fileds but these are mandatory):
    @agencies - a dict of agency, which translate agency_id to data {"agency_id": "1", "agency_name": "Dan", "agency_url" :"<url>", 'agency_timezone': 'Asia/Jerusalem', 'agency_lang': 'he'}
    
    @calendar - a list of service options {'service_id': '1', 'sunday': '1', 'monday': '1', 'tuesday': '1', 'wednesday': '1', 'thursday': '1', 'friday': '1', 'saturday': '0', 'start_date': '20230209', 'end_date': '20230311'}
    
    @stops - a list of stops  {'stop_id': '1', 'stop_code': '38831', 'stop_name': "בי''ס בר לב/בן יהודה", 'stop_desc': 'רחוב: בן יהודה 74 עיר: כפר סבא רציף:  קומה: ',
      'stop_lat': '32.183985', 'stop_lon': '34.917554', 'location_type': '0', 'parent_station': '', 'zone_id': '38831'}

    @routes - a list of routes (bus line is a route) {'route_id': '1', 'agency_id': '25', 'route_short_name': '1', 'route_long_name': 'ת. רכבת יבנה מערב-יבנה<->ת. רכבת יבנה מזרח-יבנה-1#',
      'route_desc': '67001-1-#', 'route_type': '3', 'route_color': ''}
      route_type - 0 - Tram, Streetcar, Light rail. Any light rail or street level system within a metropolitan area.
        1 - Subway, Metro. Any underground rail system within a metropolitan area.
        2 - Rail. Used for intercity or long-distance travel.
        3 - Bus. Used for short- and long-distance bus routes.
        4 - Ferry. Used for short- and long-distance boat service.
        5 - Cable car. Used for street-level cable cars where the cable runs beneath the car.
        6 - Gondola, Suspended cable car. Typically used for aerial cable cars where the car is suspended from the cable.
        7 - Funicular. Any rail system designed for steep inclines.
        11 - Trolleybus. Electric buses that draw power from overhead wires using poles.
        12 - Monorail. Railway in which the track consists of a single rail or a beam.
    
    @shapes - list of shapes, in original specifications each shape is 2 dots in a shape-sequence, determined by the sequence_id.
            We will process it so that each shape is a list of dots, and we will drop "shape_pt_sequence" field.
        {'shape_id': '44779', 'shape_pt_lat': '31.887695', 'shape_pt_lon': '35.016271', 'shape_pt_sequence': '1'}
    
    @trips - a list of trips, each trip is a sequence of connections.
        {'route_id': '68', 'service_id': '18668', 'trip_id': '4240_090223', 'trip_headsign': 'תל אביב יפו_תחנה מרכזית', 'direction_id': '0', 'shape_id': '128020'}
    
    
        
    # Notes for future:
    # Something is stil missing... i got trips.
    # I got stop_times, which is a list of stops for each trip - but i need to create connections myself.
    # I can create connections by iterating stop_times of a given trip and create a connection for each pair of consecutive stop_times.
    """

    def __init__(self, folder_path, load_existing=False) -> None:
        # In init read all the files and create a dict of dataframes
        if not os.path.isdir(folder_path):
            raise ValueError("The path provided is not a directory")
        self.folder_path = folder_path
        self.area = None
        # Note - parsing order is important. 
        self.agencies = self._parse_agencies()
        self.calendar = self._parse_calendar()
        self.stops = self._parse_stops()
        self.routes = self._parse_routes()
        self.shapes = self._parse_shapes()
        self.trips = self._parse_trips()
        self.stop_times = self._parse_stop_times()

        if COMPLETE_PARSE:
            # parse non-mendatory tables which i do not plan to use any time soon
            self.fare_attributes = self._parse_fare_attributes()
            self.fare_rules = self._parse_fare_rules()
            self.translations = self._parse_translations()
    
        # populate everything
    def _parse_agencies(self):
        agensies_path = os.path.join(self.folder_path, "agency.txt")
        parser = CSVParser(agensies_path)
        return parser.parse(id_tag="agency_id")
        
    def _parse_stops(self):
        agensies_path = os.path.join(self.folder_path, "stops.txt")
        parser = CSVParser(agensies_path)
        stops = parser.parse(id_tag="stop_id")

        # Define area based on furthest stop
        min_lon = min(stops.values(), key=lambda x: float(x["stop_lon"]))
        max_lon = max(stops.values(), key=lambda x: float(x["stop_lon"]))
        min_lat = min(stops.values(), key=lambda x: float(x["stop_lat"]))
        max_lat = max(stops.values(), key=lambda x: float(x["stop_lat"]))
        # print("min_lon - ", min_lon)
        # print("max_lon - ", max_lon)
        # print("min_lat - ", min_lat)
        # print("max_lat - ", max_lat)
        self.area = (float(min_lon["stop_lon"]), float(max_lon["stop_lon"]), float(min_lat["stop_lat"]), float(max_lat["stop_lat"])) 
        return stops
    
    def _parse_routes(self):
        curr_path = os.path.join(self.folder_path, "routes.txt")
        parser = CSVParser(curr_path)
        routes = parser.parse(id_tag="route_id")
        return routes

    def _parse_calendar(self):
        curr_path = os.path.join(self.folder_path, "calendar.txt")
        parser = CSVParser(curr_path)
        calendar = parser.parse(id_tag="service_id")
        return calendar
    
    def _parse_shapes(self):
        curr_path = os.path.join(self.folder_path, "shapes.txt")
        parser = CSVParser(curr_path)
        shapes = parser.parse(id_tag="shape_id", dup_ids_allowed=True)
        
        # # Connect shapes of the same shape_id
        # shapes_dict = {}
        # for s in shapes:
        #     if s["shape_id"] not in shapes_dict:
        #         shapes_dict[s["shape_id"]] = []
            
        #     shapes_dict[s["shape_id"]].append(s)

        return shapes

    def _parse_trips(self):
        if self.routes is None or self.calendar is None or self.shapes is None:
            raise ValueError("Routes and calendar must be parsed before parsing trips")    
        
        curr_path = os.path.join(self.folder_path, "trips.txt")
        parser = CSVParser(curr_path)
        trips = parser.parse(id_tag="trip_id")
        bad_trips = []
        if VALIDATE:
            print_log("validating trips....")
            # validate trips
            # service_ids = sorted(set([int(c["service_id"]) for c in self.calendar]))
            # route_ids = sorted(set([int(r["route_id"]) for r in self.routes]))
            # shape_ids = sorted(set([int(s["shape_id"]) for s in self.shapes]))
            for i, t in enumerate(trips.values()):
                if i % 1000 == 0:
                    print_log("validated {} trips...".format(i))
                try:
                    if t["service_id"] not in self.calendar:
                        raise ValueError("service_id {} not found in calendar".format(t["service_id"]))
                    if t["route_id"] not in self.routes:
                        raise ValueError("route_id {} not found in routes".format(t["route_id"]))
                    # We will allow this for now
                    # if t["shape_id"] not in self.shapes:
                    #     raise ValueError("shape_id {} not found in shapes".format(t["shape_id"]))

                except ValueError as e:
                    # print("got exception on trip - ", t, i)
                    bad_trips.append((t, str(e)))
                    # raise e
            if len(bad_trips) > 0:
                error_log_to_file("Got bad trips:")
                error_log_to_file(bad_trips)
            for t in bad_trips:
                # Pop bad trips from trips dict - do this in different loop because of python shit
                trips.pop(t[0]["trip_id"])
            print_log("finished validating trips.")
            # I see that i get some trips without headsigns, which screws me, because then shape_id is shifted one left.
            # Or alternativly, there is no shape_id and the headsign is a number, which is wired. 
            print_log(f"got {len(bad_trips)} bad trips out of {len(trips)} trips")
        
        return trips


    def _parse_stop_times(self):
        # trip_id,arrival_time,departure_time,stop_id,stop_sequence,pickup_type,drop_off_type,shape_dist_traveled
        curr_path = os.path.join(self.folder_path, "stop_times.txt")
        # Merge stop_times with by trips (and not by stations...?)
        parser = CSVParser(curr_path)
        stop_times = parser.parse(id_tag="trip_id", dup_ids_allowed=True)
        # arrange stops by stop_sequence
        # for s in stop_times.keys():
        #     stop_times[s] = sorted(stop_times["s"]
        bad_stop_times = []

        if VALIDATE:
            # Validate stop times
            print_log("validating stop times....")
            for i, (st_keys, st_list) in enumerate(stop_times.items()):
                if i % 1000 == 0:
                    print_log("validated {} stop_times...".format(i))
                try:
                    # sort this by stop_sequence, as we've seen it's not always sorted
                    sorted_st_list = sorted(st_list, key=lambda x: int(x["stop_sequence"]))
                    stop_times[st_keys] = sorted_st_list
                    prev_sequence = -1
                    prev_dipartue_time = "00:00:00"
                    prev_stop = None
                    # TODO: some sequences are not ordered currectly - maybe add a sort here (it's only about 200 out of 191592)
                    for st in sorted_st_list:
                        if st["trip_id"] not in self.trips:
                            raise ValueError("trip_id {} not found in trips".format(st["trip_id"]))
                        if st["stop_id"] not in self.stops:
                            raise ValueError("stop_id {} not found in routes".format(st["stop_id"]))
                        if int(st["stop_sequence"]) < prev_sequence:
                            # TODO: this jumps alot, which means that this is not sorted in any way
                            # From an investigation i did, it seesm like the sequence is not right in 2 cases
                            # * sometimes when the same stations is visited twice in the same trip.
                            # * sometimes when the trip time is crossing midnight
                            raise ValueError("stop_sequence {}, {} in wrong order in stop_times".format(prev_sequence, st["stop_sequence"]))
                        
                        # Check if arrival time is before prev depatrue time
                        # arrival time of 00:02:00 is before previous departure time 23:52:00,               
                        if time_text_to_int(st["arrival_time"]) < time_text_to_int(prev_dipartue_time):
                            if time_text_to_int(st["arrival_time"]) < time_text_to_int("12:00:00") and time_text_to_int(prev_dipartue_time) > time_text_to_int("12:00:00"):
                                # Do heuristics which assumes trip doesn't take more then 12 hours.
                                # If this happens then we crossed midnight, so this is ok
                                log_to_file("identified day transfer")
                            else:
                                # After sequences are sorted out then several things might be bad
                                # 1. The trip is visiting the same station twice
                                if st["stop_id"] == prev_stop["stop_id"]:
                                    log_to_file("identified same station twice")
                                    # swap arival\departure times...
                                    tmp_arrival = st["arrival_time"]
                                    tmp_departure = st["departure_time"]
                                    st["arrival_time"] = prev_stop["arrival_time"]
                                    st["departure_time"] = prev_stop["departure_time"]
                                    prev_stop["arrival_time"] = tmp_arrival
                                    prev_stop["departure_time"] = tmp_departure
                                else:
                                    # 2. The times are simply messed up
                                    # For now just keep it that way, from a few trips i've examined i saw that this is probably a mistake
                                    # The sequences are correct, but the times are not.
                                    # And that by always fixing the arrival time to be after the previous departure time, we get the right order.
                                    raise ValueError("arrival time of {} is before previous departure time {}, sequences {}, {}".format(
                                        st["arrival_time"], prev_dipartue_time, st["stop_sequence"], prev_sequence))
                        
                        prev_sequence = int(st["stop_sequence"])
                        prev_dipartue_time = st["departure_time"]
                        prev_stop = st
                except ValueError as e:
                    # print("got exception on stop_times - ", st_list, i)
                    bad_stop_times.append((sorted_st_list, str(e)))
                    prev_sequence = -1
                    prev_dipartue_time = "00:00:00"
                    continue
                    # raise e
            if len(bad_stop_times) > 0:
                error_log_to_file("Got bad stop_times:")
                error_log_to_file(bad_stop_times)

            # for st_list in bad_stop_times:
            # # Pop bad trips from trips dict - do this in different loop because of python shit
            #     stop_times.pop(st_list[0][0]["trip_id"])
            print_log("finished validating stop_times.")
            # I see that i get some trips without headsigns, which screws me, because then shape_id is shifted one left.
            # Or alternativly, there is no shape_id and the headsign is a number, which is wired. 
            print_log(f"got {len(bad_stop_times)} bad stop_times out of {len(bad_stop_times) + len(stop_times)} stop_times")
        return stop_times


    # ************************************* #
    # Non-mandatory tables
    # ************************************* #

    def _parse_fare_attributes(self):
        curr_path = os.path.join(self.folder_path, "fare_attributes.txt")
        parser = CSVParser(curr_path)
        fare_attributes = parser.parse(id_tag="fare_id")
        return fare_attributes
    
    def _parse_fare_rules(self):
        curr_path = os.path.join(self.folder_path, "fare_rules.txt")
        # Group by fare_ids
        parser = CSVParser(curr_path)
        fare_rules = parser.parse(id_tag="fare_id", dup_ids_allowed=True)
        return fare_rules
    

    def _parse_translations(self):
        curr_path = os.path.join(self.folder_path, "translations.txt")
        # I do not know yet what is this translation format, its wired.
        parser = CSVParser(curr_path)
        translations = parser.parse(id_tag="trans_id")
        return translations
    
    def get_trip_stations(self, trip_id):
        return [(trip_stop["stop_sequence"], self.stops[trip_stop["stop_id"]]) for trip_stop in self.stop_times[trip_id]]
    

    def generate_connections():
        # iterate stop_times and create connections
        pass
# I need to figure out the final data stracture i want to achive.
# I think i want a timetable - which is a list of stations, each station has some metadata(like name, id, location, etc)
# And a list of connections/trips which runs through the stations.



def get_is_gtfs(reparse=False):
    if os.path.isfile(IS_GTFS_OBJ) and not reparse:
        print_log("loading gtfs from file...")
        return load_artifact(IS_GTFS_OBJ)
    else:
        print_log("parsing gtfs from folder...")
        gtfs = GTFS(IS_GTFS_FOLDER)
        save_artifact(gtfs, IS_GTFS_OBJ)
        return gtfs

def get_is_tlv_gtfs(reparse=False):
    if os.path.isfile(TLV_GTFS_OBJ) and not reparse:
        print_log("loading gtfs from file...")
        return load_artifact(TLV_GTFS_OBJ)
    else:
        print_log("parsing reducing from is_gtfs...")
        gtfs = get_is_gtfs()
        rgtfs = reduce_gtfs(gtfs, *TEL_AVIV_AREA)
        save_artifact(rgtfs, TLV_GTFS_OBJ)
        return gtfs


def reduce_gtfs(gtfs, min_lon, max_lon, min_lat, max_lat):
    # Reduce gtfs to only include trips in a certain area.
    # I do this to create a smaller set of data for which to tryout my algorithms
    # I will do this by reducing the stops, and then remove trips which contains these stops
    new_stops = {}
    for stop in gtfs.stops.items():
        if float(stop[1]["stop_lon"]) >= min_lon and float(stop[1]["stop_lon"]) <= max_lon and \
            float(stop[1]["stop_lat"]) >= min_lat and float(stop[1]["stop_lat"]) <= max_lat:
            new_stops[stop[0]] = stop[1]
    new_trips = {}
    new_stop_times = {}
    for trip in gtfs.trips.keys():
        keep_trip = True
        for stop in gtfs.stop_times[trip]:
            if stop["stop_id"] not in new_stops:
                # TODO: maybe instead of deleting trips i can just delete the stops which are not in the area
                keep_trip = False
                break
        if keep_trip:
            new_trips[trip] = gtfs.trips[trip]
            new_stop_times[trip] = gtfs.stop_times[trip]
    
    # change 3 segnificant parameters of gtfs
    gtfs.stops = new_stops
    gtfs.trips = new_trips
    gtfs.stop_times = new_stop_times
    return gtfs


def test_is_gtfs_parser():
    print(f"[+] running from cwd: {os.getcwd()}")
    time1 = time.time()
    gtfs = get_is_gtfs()
    time2 = time.time()
    print("finished loading gtfs in {} seconds".format(time2 - time1))
    error_log_to_file("test this!")
    print_log("num of trips - ", len(gtfs.trips))
    # print("agencies: ", get_some_items(gtfs.agencies))
    # print("stops: ", get_some_items(gtfs.stops))
    # print("routes: ", get_some_items(gtfs.routes))
    # print("calendar: ", get_some_items(gtfs.calendar))
    # print("shapes: ", get_some_items(gtfs.shapes))
    # print("trips: ", get_some_items(gtfs.trips))
    display_gtfs_stations(gtfs, 0.5)
    
    # display_gtfs_stations_for_trip(gtfs, 1, "17076498_090223")
    # display_stations(gtfs, 1)

def test_is_tlv_gtfs_parser():

    print(f"[+] running from cwd: {os.getcwd()}")    
    time1 = time.time()
    gtfs = get_is_tlv_gtfs()
    time2 = time.time()
    print("finished loading tlv gtfs in {} seconds".format(time2 - time1))
    error_log_to_file("test this!")
    print_log("num of trips - ", len(gtfs.trips))
    display_gtfs_stations(gtfs, 0.5)

def main():
    test_is_tlv_gtfs_parser()

if __name__ == '__main__':
    main()
    #display_stations(None)
