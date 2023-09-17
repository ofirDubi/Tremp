from parse_gtfs import get_is_gtfs, get_is_tlv_gtfs


# What i need - a list of connection. a connection is a tuple of 5  elements:
# - depatrue stop
# - arrival stop
# - depatrue time
# - arrival time
# - trip id (trip is a sequence of connections)

def build_connections(gtfs):
    # A connection is besically two following stops, so each pair of stops will be a connection.
    # Pretty easy. 

    pass

def main():
    gtfs = get_is_tlv_gtfs()

    # 

if __name__ == '__main__':
    pass