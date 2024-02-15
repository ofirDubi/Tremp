import valhalla
import os

VALHALLA_FOLDER = "../valhalla"

class ValhallaActor():

    def __init__(self) -> None:
        self.actor = None

    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(ValhallaActor, cls).__new__(cls)
        return cls.instance
    
    def init_actor(self, tt):
        config = valhalla.get_config(tile_extract=os.path.join(VALHALLA_FOLDER,'./custom_files/valhalla_tiles.tar'), verbose=True)
        # TODO: figure out why changing this in json doesn't work
        config["service_limits"]["pedestrian"]["max_matrix_location_pairs"] = len(tt.stations) + 100 # pad another 100 just to be sure
        self.actor = valhalla.Actor(config)

    
def get_actor(tt):
    va = ValhallaActor()
    if va.actor is None:
        va.init_actor(tt)
    return va.actor