import tilemapbase
from matplotlib import pyplot as plt



def initiate_plotter(area):
    """
    @param area - a tuple of 4 floats: (min_lon, max_lon, min_lat, max_lat)
    """
    tilemapbase.start_logging()
    tilemapbase.init(create=True)
    t = tilemapbase.tiles.build_OSM()

    # print(*gtfs_instance.area)
    extent = tilemapbase.Extent.from_lonlat(*area)
    # my_neightborhood =(34.8224, 34.8486, 32.1001, 32.1331)
    # extent = tilemapbase.Extent.from_lonlat(*my_neightborhood)
    extent = extent.to_aspect(1.0)

    # On my desktop, DPI gets scaled by 0.75 
    fig, ax = plt.subplots(figsize=(8, 8), dpi=100)
    ax.xaxis.set_visible(False)
    ax.yaxis.set_visible(False)

    plotter = tilemapbase.Plotter(extent, t, width=600)
    plotter.plot(ax, t)
    return plotter, ax

def display_gtfs_stations(gtfs_instance, plot_chance=1):
    """
    Display the stations on a map using tilemapbase
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    plotter, ax = initiate_plotter(gtfs_instance.area)
    plot_filter = 1//plot_chance
    longs = (float(s["stop_lon"]) for s in gtfs_instance.stops.values() if int(s["stop_id"]) % plot_filter == 0)
    lats = (float(s["stop_lat"]) for s in gtfs_instance.stops.values() if int(s["stop_id"]) % plot_filter == 0)
    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    # Show the plot
    plt.show()

def display_gtfs_stations_for_trip(gtfs_instance, trip_id):
    """
    Display the stations on a map using tilemapbase
    @gtfs_instance - an instance of GTFS class
    @plot_chance - the chance to plot a station. 1 means plot all stations, 2 means plot every second station, etc.
    """
    plotter, ax = initiate_plotter(gtfs_instance.area)
    # display stations that are on trip 58849630_170223
    stations_seq = gtfs_instance.get_trip_stations(trip_id)
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

def display_connections(connections):
    # Display a route on a map using tilemapbase
    
    # Get area of the route to display
    stops = [c.departure_stop for c in connections]
    # Also get last arrival stop
    stops.append(connections[-1].arrival_stop)
    min_lon = min(stops, key=lambda x: float(x["stop_lon"]))
    max_lon = max(stops, key=lambda x: float(x["stop_lon"]))
    min_lat = min(stops, key=lambda x: float(x["stop_lat"]))
    max_lat = max(stops, key=lambda x: float(x["stop_lat"]))
   
    area = (float(min_lon["stop_lon"]), float(max_lon["stop_lon"]), float(min_lat["stop_lat"]), float(max_lat["stop_lat"])) 
    print(area)

    plotter, ax = initiate_plotter(area)
    print("got specific stations for trip")
    print(stops)

    longs = (float(s[1]["stop_lon"]) for s in stops)
    lats = (float(s[1]["stop_lat"]) for s in stops)

    path = [tilemapbase.project(x,y) for x,y in zip(longs, lats)]
    x, y = zip(*path)
    # Plot stations as dots on the map
    ax.scatter(x,y, marker=".", color="black")
    for i, st in enumerate(stops):
        ax.annotate(st[0], (x[i], y[i]))

    # Next - plot arrows between the stations
    for i in range(len(x)-1):
        ax.annotate("", xy=(x[i+1], y[i+1]), xytext=(x[i], y[i]), arrowprops=dict(arrowstyle="->", color="red"))
    # Show the plot
    plt.show()

