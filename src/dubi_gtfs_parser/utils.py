from bisect import bisect_left
import time
import pickle

from dataclasses import dataclass, field
import time
from typing import Callable, ClassVar, Dict, Optional


DEBUG_LOGS = True
ARTIFACTS_FOLDER = "artifacts"
VALHALLA_FOLDER = "../valhalla"
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
