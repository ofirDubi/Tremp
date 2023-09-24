from bisect import bisect_left
import time
import pickle

from dataclasses import dataclass, field
import time
from typing import Callable, ClassVar, Dict, Optional


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

# class TimerError(Exception):
#     """A custom exception used to report errors in use of Timer class"""

# @dataclass
# class Timer:
#     timers: ClassVar[Dict[str, float]] = {}
#     name: Optional[str] = None
#     text: str = "Elapsed time: {:0.4f} seconds"
#     logger: Optional[Callable[[str], None]] = print
#     _start_time: Optional[float] = field(default=None, init=False, repr=False)

#     def __post_init__(self) -> None:
#         """Add timer to dict of timers after initialization"""
#         if self.name is not None:
#             self.timers.setdefault(self.name, 0)

#     def start(self) -> None:
#         """Start a new timer"""
#         if self._start_time is not None:
#             raise TimerError(f"Timer is running. Use .stop() to stop it")

#         self._start_time = time.perf_counter()

#     def stop(self) -> float:
#         """Stop the timer, and report the elapsed time"""
#         if self._start_time is None:
#             raise TimerError(f"Timer is not running. Use .start() to start it")

#         # Calculate elapsed time
#         elapsed_time = time.perf_counter() - self._start_time
#         self._start_time = None

#         # Report elapsed time
#         if self.logger:
#             self.logger(self.text.format(elapsed_time))
#         if self.name:
#             self.timers[self.name] += elapsed_time

#         return elapsed_time

#     def __enter__(self):
#         """Start a new timer as a context manager"""
#         self.start()
#         return self

#     def __exit__(self, *exc_info):
#         """Stop the context manager timer"""
#         self.stop()

# def my_bisect_left(a, x, lo=0, hi=None, *, key=None):
#     """Return the index where to insert item x in list a, assuming a is sorted.

#     The return value i is such that all e in a[:i] have e < x, and all e in
#     a[i:] have e >= x.  So if x already appears in the list, a.insert(i, x) will
#     insert just before the leftmost x already there.

#     Optional args lo (default 0) and hi (default len(a)) bound the
#     slice of a to be searched.
#     """

#     if lo < 0:
#         raise ValueError('lo must be non-negative')
#     if hi is None:
#         hi = len(a)
#     # Note, the comparison uses "<" to match the
#     # __lt__() logic in list.sort() and in heapq.
#     if key is None:
#         while lo < hi:
#             mid = (lo + hi) // 2
#             if a[mid] < x:
#                 lo = mid + 1
#             else:
#                 hi = mid
#     else:
#         while lo < hi:
#             mid = (lo + hi) // 2
#             if key(a[mid]) < x:
#                 lo = mid + 1
#             else:
#                 hi = mid
#     return lo

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
