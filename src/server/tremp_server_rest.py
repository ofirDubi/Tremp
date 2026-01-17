import socket
import ssl
import pprint
import itertools
import json
import sys
import traceback
import falcon

from dubi_gtfs_parser.connection_builder import Connection, Timetable, get_is_timetable, SearchableStations
from dubi_gtfs_parser.parse_gtfs import get_is_gtfs, reduce_gtfs

tt = None

# Falcon follows the REST architectural style, meaning (among
# other things) that you think in terms of resources and state
# transitions, which map to HTTP verbs.
class StationsResource:
    def on_get(self, req, resp):
        """Handles GET requests for stations"""
        min_lon = req.get_param('min_lon')
        max_lon = req.get_param('max_lon')
        min_lat = req.get_param('min_lat')
        max_lat = req.get_param('max_lat')
        

        rgtfs = reduce_gtfs(gtfs, min_lon, max_lon, min_lat, max_lat)
        stations = rgtfs.stations() 

        resp.status = falcon.HTTP_200  # This is the default status
        #resp.content_type = falcon.MEDIA_TEXT  # Default is JSON, so override
        resp.text = json.dumps(stations)


def test_ultra_route_with_car(reparse=False, full_reparse=False):
    tt = get_tlv_timetable(reparse, full_reparse)

    print("[+] starting ultra test!")

    # Glilot camp
    start_car = {"lat": 32.145549, "lon": 34.819354}
    # Some random address in ramash
    end_car = {"lat": 32.14188, "lon": 34.84082}

    with Timer(text="[+] Building connections for car route {:.4f} seconds..."):
        # Note - this takes 2.5-3.5 seconds for me for a 15 min trip with 5 min deviation, not so good.
        # Initial pruning with isochrones takes 0.7 seconds, then one-to-many takes 2 seconds.
        # Maybe i can prune more stations after i have initial raptor results - it might be so that some stations won't be optimal and can be dropped.
        valid_stations = build_connections_for_car_route(tt, start_car, end_car, "10:05:00", deviation=60*2)

    with Timer(text="[+] running semi ULTRA took {:.4f} seconds..."):
        result_routes = run_ultra_wrapper({"stop_lat": 32.145549, "stop_lon": 34.819354}, {"stop_lat": 32.111850, "stop_lon": 34.831520}, "10:00:00", 
                                            tt, car_route=True, relax_footpaths=True, limit_walking_time=60*15, debug=False)

    optimize_departure_time(result_routes)
    
    for r in result_routes:
        print(r)
        r.display_result()
    

def main():
    global tt
    tt = get_is_timetable(reparse=False)

    # setup server
    app = falcon.App()
    app.add_route('/quote', TrempResource())

    

if __name__ == '__main__':
    main()