import tilemapbase
from matplotlib import pyplot as plt
from utils import meters_to_degrees, FOOTPATH_ID, is_footpath

def get_stations_area(stations):
    min_lon = min(stations, key=lambda x: float(x["stop_lon"]))
    max_lon = max(stations, key=lambda x: float(x["stop_lon"]))
    min_lat = min(stations, key=lambda x: float(x["stop_lat"]))
    max_lat = max(stations, key=lambda x: float(x["stop_lat"]))
    area = (float(min_lon["stop_lon"]), float(max_lon["stop_lon"]), float(min_lat["stop_lat"]), float(max_lat["stop_lat"])) 
    return area

def get_color(i, trip_id=None):
    if is_footpath(trip_id):
        return 'gray'
    colors = ['b', 'g', 'r', 'c', 'm', 'y', 'k', 'w']
    return colors[i % len(colors)]

def get_cmap(n, name='hsv'):
    '''Returns a function that maps each index in 0, 1, ..., n-1 to a distinct 
    RGB color; the keyword argument name must be a standard mpl colormap name.'''
    return plt.cm.get_cmap(name, n)

def initiate_plotter(area):
    """
    @param area - a tuple of 4 floats: (min_lon, max_lon, min_lat, max_lat)
    """
    tilemapbase.start_logging()
    tilemapbase.init(create=True)
    t = tilemapbase.tiles.build_OSM()

    # increase area lat and lon alittle bit, to get nicer view.
    area = (area[0] - 0.01, area[1] + 0.01, area[2] - 0.01, area[3] + 0.01)

    extent = tilemapbase.Extent.from_lonlat(*area)
    # my_neightborhood =(34.8224, 34.8486, 32.1001, 32.1331)
    # extent = tilemapbase.Extent.from_lonlat(*my_neightborhood)
    # Shrink=True fucks me up real good....
    extent = extent.to_aspect(1.0, False)

    # On my desktop, DPI gets scaled by 0.75 
    fig, ax = plt.subplots(figsize=(8, 8), dpi=100)
    ax.xaxis.set_visible(False)
    ax.yaxis.set_visible(False)

    plotter = tilemapbase.Plotter(extent, t, width=600)
    plotter.plot(ax, t)
    return plotter, ax

def display_visited_stations(tt, visited_stations, start_station, end_station):
    stations = [tt.stations[st_id] for st_id in visited_stations.keys()]
    # Also get last arrival stop
    area = get_stations_area(stations)
    plotter, ax = initiate_plotter(tt.gtfs_instance.area)
    # visited_stations is a dict of station_id -> (arrival_time, prev_station, connection, prev_connection)
    
    longs = (float(s["stop_lon"]) for s in stations)
    lats = (float(s["stop_lat"]) for s in stations)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(visited_stations.values()):
        ax.annotate(st.arrival_time, (x[i], y[i]))
    
    # Display start station and end station with different colors
    path = [tilemapbase.project(float(start_station["stop_lon"]), float(start_station["stop_lat"]))]
    x, y = zip(*path)
    ax.scatter(x,y, marker="x", color="blue")
    
    path = [tilemapbase.project(float(end_station["stop_lon"]), float(end_station["stop_lat"]))]
    x, y = zip(*path)
    ax.scatter(x,y, marker="x", color="red")

    # Show the plot
    plt.show()

    
def display_all_gtfs_stations(gtfs_instance, plot_chance=1, marker_station=None, radius=0):
    """
    Display the stations on a map using tilemapbase
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    plotter, ax = initiate_plotter(gtfs_instance.area)
    plot_filter = 1//plot_chance
    longs = (float(s["stop_lon"]) for s in gtfs_instance.stations.values() if int(s["station_id"]) % plot_filter == 0)
    lats = (float(s["stop_lat"]) for s in gtfs_instance.stations.values() if int(s["station_id"]) % plot_filter == 0)
    station_ids = (s["station_id"] for s in gtfs_instance.stations.values() if int(s["station_id"]) % plot_filter == 0)
    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    
    for i, st in enumerate(station_ids):
        ax.annotate(st, (x[i], y[i]))
    
    if marker_station is not None:
        path = [tilemapbase.project(float(marker_station["stop_lon"]), float(marker_station["stop_lat"]))]
        x, y = zip(*path)
        ax.scatter(x,y, marker="x", color="red")

        if radius > 0:
            # project radisu which is in meters to appropriate scale. so first we need to cast to degrees
        
            radius_degs = meters_to_degrees(radius)
            path = [tilemapbase.project(radius_degs, radius_degs)]
            radius_scaled, garbg  = zip(*path)
            # print(radius_scaled)
            radius_scaled = radius_scaled[0] - 0.5
            # print("plotting radius!!", (x,y), radius_scaled)
            circle = plt.Circle((x, y), radius_scaled, color='r')
            ax.add_artist(circle)
    # Show the plot
    plt.show()

def display_stations(stations, marker_station=None, radius=0, fill=False, direct=False):
    area = get_stations_area(stations)
    plotter, ax = initiate_plotter(area)
    longs = (float(s["stop_lon"]) for s in stations)
    lats = (float(s["stop_lat"]) for s in stations)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stations):
        ax.annotate(st["station_id"], (x[i], y[i]))

    if marker_station is not None:
        path = [tilemapbase.project(float(marker_station["stop_lon"]), float(marker_station["stop_lat"]))]
        x, y = zip(*path)
        ax.scatter(x,y, marker="x", color="red")

        if radius > 0:
            # project radisu which is in meters to appropriate scale. so first we need to cast to degrees
            if(direct):
                radius_scaled = radius
            else:
                radius_degs = meters_to_degrees(radius)
                path = [tilemapbase.project(radius_degs, radius_degs)]
                radius_scaled, garbg  = zip(*path)
                # print(radius_scaled)
                radius_scaled = radius_scaled[0] - 0.5
            # print("plotting radius!!", (x,y), radius_scaled)
            circle = plt.Circle((x, y), radius_scaled, color='r', fill=fill)
            ax.add_artist(circle)
    # Show the plot
    plt.show()

def display_all_gtfs_stations_for_trip(gtfs_instance, trip_id):
    """
    Display the stations on a map using tilemapbase
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    stations_seq = gtfs_instance.get_trip_stations(trip_id)

    area = get_stations_area([s[1] for s in stations_seq])
    plotter, ax = initiate_plotter(area)

    print("got specific stations for trip")
    print(stations_seq)

    longs = (float(s[1]["stop_lon"]) for s in stations_seq)
    lats = (float(s[1]["stop_lat"]) for s in stations_seq)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stations_seq):
        ax.annotate(st[0], (x[i], y[i]))
    # Show the plot
    plt.show()


def display_gtfs_trip(gtfs_instance, trip_id):
    """
    Display the stops on a map using tilemapbase
    Display the shape of the trip
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    stations_seq = gtfs_instance.get_trip_stations(trip_id)
    area = get_stations_area([s[1] for s in stations_seq])
    
    plotter, ax = initiate_plotter(area)
    # display stations that are on trip 58849630_170223
    print("display_gtfs_trip")
    print(stations_seq)

    longs = (float(s[1]["stop_lon"]) for s in stations_seq)
    lats = (float(s[1]["stop_lat"]) for s in stations_seq)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stations_seq):
        ax.annotate(st[0], (x[i], y[i]))
    
    # Now plot the shape of the trip
    # trip_shapes = gtfs_instance.shapes[gtfs_instance.trips[trip_id]["shape_id"]]
    
    # for each stop, plot the shape from it to the next stop in a different color
    for i, stop in enumerate(gtfs_instance.stop_times[trip_id]):
        if stop["shapes"] == []:
            continue
        shape_longs = (float(s["shape_pt_lon"]) for s in stop["shapes"])
        shape_lats = (float(s["shape_pt_lat"]) for s in stop["shapes"])
        shapes_path = [tilemapbase.project(x,y) for x,y in zip(shape_longs, shape_lats)]
        shapes_x, shapes_y = zip(*shapes_path)
        # connect each shape point to the next one with a line
        # plot with x and y data
        ax.plot(shapes_x, shapes_y, get_cmap(i))
    plt.show()

    # shape_longs = (float(s["shape_pt_lon"]) for s in trip_shapes)
    # shape_lats = (float(s["shape_pt_lat"]) for s in trip_shapes)
    # shapes_path = [tilemapbase.project(x,y) for x,y in zip(shape_longs, shape_lats)]
    # shapes_x, shapes_y = zip(*shapes_path)
    # # connect each shape point to the next one with a line
    # # plot with x and y data
    # ax.plot(shapes_x, shapes_y)
    # # for i in range(len(shapes_x)-1):
    #     ax.annotate("", xy=(shapes_x[i+1], shapes_y[i+1]), xytext=(shapes_x[i], shapes_y[i]), arrowprops=dict(arrowstyle="->", color="red"))

    #ax.scatter(shapes_x,shapes_y, marker=".", color="red")

    # Show the plot


def display_gtfs_trip_shapes(gtfs_instance, trip_id):
    """
    Display the stops on a map using tilemapbase
    Display the shape of the trip
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    stations_seq = gtfs_instance.get_trip_stations(trip_id)
    area = get_stations_area([s[1] for s in stations_seq])
    
    plotter, ax = initiate_plotter(area)
    # display stations that are on trip 58849630_170223
    print("got specific stations for trip")
    print(stations_seq)

    longs = (float(s[1]["stop_lon"]) for s in stations_seq)
    lats = (float(s[1]["stop_lat"]) for s in stations_seq)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stations_seq):
        ax.annotate(st[0], (x[i], y[i]))
    
    # Now plot the shape of the trip
    trip_shapes = gtfs_instance.shapes[gtfs_instance.trips[trip_id]["shape_id"]]
    shape_longs = (float(s["shape_pt_lon"]) for s in trip_shapes)
    shape_lats = (float(s["shape_pt_lat"]) for s in trip_shapes)
    shapes_path = [tilemapbase.project(x,y) for x,y in zip(shape_longs, shape_lats)]
    shapes_x, shapes_y = zip(*shapes_path)
    # connect each shape point to the next one with a line
    # plot with x and y data
    # ax.plot(shapes_x, shapes_y)
    ax.scatter(shapes_x,shapes_y, marker=".", color="red")
    for i, st in enumerate(trip_shapes):
        ax.annotate(trip_shapes[i]["shape_pt_sequence"], (shapes_x[i], shapes_y[i]))
    
    plt.show()


def display_RaptorResult(raptor_result):
    ax = display_connections(raptor_result.tt, raptor_result.result_connections, no_show=True)
    
    # Display the line transfers at designated stations, skip last station
    stations = [raptor_result.tt.stations[r[0]] for r in raptor_result.result_route[:-1]]
    # Also get last arrival stop
    longs = (float(s["stop_lon"]) for s in stations)
    lats = (float(s["stop_lat"]) for s in stations)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    
    for i, st in enumerate(stations):
        print(x,y)
        if i == 0:
            ax.annotate(raptor_result.bus_lines[i], (x[i], y[i]), color="red")
        else:
            ax.annotate(f"{raptor_result.bus_lines[i-1]}->{raptor_result.bus_lines[i]}", (x[i], y[i]), color="red")

    # Add description of this result on top
    ax.text(.01, .99, str(raptor_result), ha='left', va='top', transform=ax.transAxes)
    plt.show()
    print("showed result")
def display_connections(timetable, connections, no_show=False):
    # Display a route on a map using tilemapbase
    
    # match shapes to stations in trip, match it for all trips.
    connections_by_trip = {}
    for c in connections:
        if c.trip_id not in connections_by_trip:
            connections_by_trip[c.trip_id] = [c]
        else:
            connections_by_trip[c.trip_id].append(c)
    trip_colors = {}
    trip_colors_options = get_cmap(len(connections_by_trip.keys()))
    for i, trip_id in enumerate(connections_by_trip.keys()):
        timetable.match_shapes_to_connections(connections_by_trip[trip_id])
        trip_colors[trip_id] = get_color(i, trip_id)


    # Get area of the route to display
    stations = [timetable.stations[c.departure_stop] for c in connections]
    # Also get last arrival stop
    stations.append(timetable.stations[connections[-1].arrival_stop])
    area = get_stations_area(stations)
    print(area)

    plotter, ax = initiate_plotter(area)
    # print("got specific stations for trip")
    # print(stations)

    longs = (float(s["stop_lon"]) for s in stations)
    lats = (float(s["stop_lat"]) for s in stations)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stations):
        ax.annotate(i, (x[i], y[i]))

    # Now plot the shape of the trip
    prev_last_shape = []
    painted_trip_id = {}
    for c in connections:
        # Start with connection to last shape
        c_shapes = prev_last_shape + c.shapes  
        prev_last_shape = [c_shapes[-1]]
        shape_longs = (float(s["shape_pt_lon"]) for s in c_shapes)
        shape_lats = (float(s["shape_pt_lat"]) for s in c_shapes)
        shapes_path = [tilemapbase.project(x,y) for x,y in zip(shape_longs, shape_lats)]
        shapes_x, shapes_y = zip(*shapes_path)
        # connect each shape point to the next one with a line
        # plot with x and y datawq  1
        painted_trip_id[c.trip_id] = trip_colors[c.trip_id]
        ax.plot(shapes_x, shapes_y, color=trip_colors[c.trip_id])

    # # Next - plot arrows between the stations
    # for i in range(len(x)-1):
    #     ax.annotate("", xy=(x[i+1], y[i+1]), xytext=(x[i], y[i]), arrowprops=dict(arrowstyle="->", color="red"))
    # Show the plot
    if no_show:
        return ax
    else:
        plt.show()

