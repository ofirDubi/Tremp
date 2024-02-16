from bisect import bisect_left
import time
import pickle

from dataclasses import dataclass, field
import time
from typing import Callable, ClassVar, Dict, Optional

FOOTPATH_ID = "footpath"

def is_footpath(trip_id):
    return str(trip_id).startswith(FOOTPATH_ID) 

DEBUG_LOGS = True
ARTIFACTS_FOLDER = "artifacts"
log_file = f"logs\\log_{int(time.time())}.txt"

def print_log(*args, **kwargs):
    if DEBUG_LOGS:
        print("[+] ", *args, **kwargs)
    log_to_file(*args, **kwargs)

def log_to_file(*args, **kwargs):
    if DEBUG_LOGS:
        with open(log_file, "a") as f:
            print("[+] ", *args, **kwargs, file=f)
            
def error_log_to_file(*args, **kwargs):
    if DEBUG_LOGS:
        with open(log_file, "a") as f:
            print("[-] ", *args, **kwargs, file=f)

def BinarySearchIdx(a, x, key=None):
    i = bisect_left(a, x, key=key)
    return i
           
def BinarySearch(a, x, key=None):
    i = BinarySearchIdx(a, x, key)
    if i != len(a) and a[i] == x:
        return i
    else:
        return -1


def save_artifact(obj, filename) -> None:
    pickle.dump(obj, open(filename, 'wb'))
    
def load_artifact(filename) -> None:
    return pickle.load(open(filename, 'rb'))

def distance(p1, p2):
    return ((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)**0.5

def further_than_length(p1, p2, length):
    # faster calculation without sqrt
    length_squared = length**2
    dist_square = ((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)
    return dist_square > length_squared

def distance_degrees_to_meters(p1, p2):
    return ((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)**0.5


def time_text_to_int(time_text):
    h, m, s = time_text.split(":")
    return (int(h) * 60 + int(m)) * 60 + int(s)

def time_int_to_text(seconds):
    return time.strftime('%H:%M:%S', time.gmtime(seconds))



def get_some_items(d):
    res = []
    for i, k in enumerate(d.keys()):
        if i >= 1:
            break
        res.append({k:d[k]})
    return res


def degrees_to_meters(degrees):
    # one degree is 111.32 km
    if type(degrees) == str:
        degrees = float(degrees)
    return degrees * 1000.0 * 111.32
def meters_to_degrees(meters):
    # one degree is 111.32 km
    return meters / 1000.0 / 111.32


# decode an encoded polyline string
def decode_polyline(encoded):
  #six degrees of precision in valhalla
  inv = 1.0 / 1e6
  decoded = []
  previous = [0,0]
  i = 0
  #for each byte
  while i < len(encoded):
    #for each coord (lat, lon)
    ll = [0,0]
    for j in [0, 1]:
      shift = 0
      byte = 0x20
      #keep decoding bytes until you have this coord
      while byte >= 0x20:
        byte = ord(encoded[i]) - 63
        i += 1
        ll[j] |= (byte & 0x1f) << shift
        shift += 5
      #get the final value adding the previous offset and remember it for the next
      ll[j] = previous[j] + (~(ll[j] >> 1) if ll[j] & 1 else (ll[j] >> 1))
      previous[j] = ll[j]
    #scale by the precision and chop off long coords also flip the positions so
    #its the far more standard lon,lat instead of lat,lon
    decoded.append([float('%.6f' % (ll[1] * inv)), float('%.6f' % (ll[0] * inv))])
  #hand back the list of coordinates
  return decoded

def bus_line_from_trip_id(tt, trip_id):
    return tt.gtfs_instance.routes[tt.trips[trip_id]["route_id"]]["route_short_name"]


def get_station_connections_as_lines(tt, station_id):
    res = []
    for c in tt.station_connections[station_id]:
        res.append((c,  bus_line_from_trip_id(tt, c.trip_id)))
    return res