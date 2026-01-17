import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'place.dart';
import 'myMap.dart';
import 'search_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'other_screens.dart';
import 'server_comms.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
    ),
  );

  runApp(
    MaterialApp(
      title: 'Material Floating Search Bar Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        iconTheme: const IconThemeData(
          color: Color(0xFF4d4d4d),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: ChangeNotifierProvider<SearchModel>(
          create: (_) => SearchModel(),
          child: const Home(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FloatingSearchBarController controller = FloatingSearchBarController();
  final FloatingSearchBarController controller2 = FloatingSearchBarController();

  int _index = 0;
  int get index => _index;
  // Place _searchedLocation = Place();
  // Place get searchedLocation => _searchedLocation;
  Place originLocation = Place();
  Place destinationLocation = Place();
  final mapController = MapController();
  bool isChangingOrigin = false;
  List<Station> visibleStations = [];
  setSearchedLocation(String query) async {
    // Get the first location in the searched list
    Place newSearchedLocation = (await queryToPlaces(query))[0];
    // print("[+] new searchedLocation: $_searchedLocation");
    setState(() {
      if (isChangingOrigin) {
        originLocation = newSearchedLocation;
      } else {
        destinationLocation = newSearchedLocation;
      }
    });

    if (originLocation.hashCode != 1 && destinationLocation.hashCode != 1) {
      CameraFit ft = CameraFit.coordinates(coordinates: [
        destinationLocation.coordinates,
        originLocation.coordinates
      ], padding: const EdgeInsets.all(50.0));
      mapController.fitCamera(ft);
    } else {
      mapController.move(newSearchedLocation.coordinates, 15.0);
    }
  }

  void loadStations() async {
    LatLngBounds bnds = mapController.camera.visibleBounds;
    print(
        "[+] attempting to load stations at bounds ${bnds.northWest}, ${bnds.southEast}");
    List<Station>? stations =
        await StationApi().getAllStationsInArea(bnds.northWest, bnds.southEast);
    print("[+] stations: $stations");
    setState(() {
      visibleStations = stations ?? [];
    });
  }

  set index(int value) {
    _index = min(value, 2);
    _index == 2
        ? controller.hide()
        : controller
            .show(); // this hides the search controller when passing from explore/commute to saved/contribute/updates
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: Container(
          width: 200,
        ),
      ),
      body: buildSearchBar(),
    );
  }

  Widget buildSearchBar() {
    final List<FloatingSearchBarAction> actions = <FloatingSearchBarAction>[
      FloatingSearchBarAction(
        child: CircularButton(
          icon: const Icon(Icons.place),
          onPressed: () {},
        ),
      ),
      FloatingSearchBarAction.searchToClear(
        showIfClosed: false,
      ),
    ];

    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<SearchModel>(
      builder: (BuildContext context, SearchModel model, _) =>
          FloatingSearchBar(
        automaticallyImplyBackButton: false,
        controller: controller,
        hint: 'חיפוש...',
        iconColor: Colors.grey,
        transitionDuration: const Duration(milliseconds: 800),
        transitionCurve: Curves.easeInOutCubic,
        physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        actions: actions,
        progress: model.isLoading,
        debounceDelay: const Duration(milliseconds: 500),
        onQueryChanged: model.onQueryChanged,
        onKeyEvent: (KeyEvent keyEvent) {
          if (keyEvent.logicalKey == LogicalKeyboardKey.escape) {
            controller.query = '';
            controller.close();
          }
        },
        onSubmitted: (String query) {
          DateTime now = DateTime.now();
          print("${now.hour}:${now.minute}:${now.second}");
          print('[+] submitted search for string in mapaaa - $query');
          setSearchedLocation(query);
          model.clear();
          controller.close();
        },
        scrollPadding: EdgeInsets.zero,
        transition: CircularFloatingSearchBarTransition(spacing: 16),
        builder: (BuildContext context, _) => buildExpandableBody(model),
        body: buildBody(),
      ),
    );
  }

  // Main body
  Widget buildBody() {
    return Column(
      children: <Widget>[
        Expanded(
          child: IndexedStack(
            // By using indexed stack we travel through different pages when clicking on the bottom navigation bar
            index: min(index, 2),
            children: <Widget>[
              Stack(
                children: [
                  Map(mapController, originLocation, destinationLocation),
                  // This is the toggle button to switch between origin and destination
                  Positioned(
                    top: 100.0, // Adjust position as needed
                    left: 0.0, // Adjust position as needed
                    right: 0.0, // Adjust position to span width
                    child: Wrap(
                      children: [
                        Container(
                            padding: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              border:
                                  Border.all(color: Colors.black, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: ToggleButtons(
                                isSelected: [
                                  !isChangingOrigin,
                                  isChangingOrigin
                                ],
                                selectedColor: Colors.white,
                                // text color of not selected toggle
                                color: Colors.blue,
                                // fill color of selected toggle
                                fillColor: Colors.lightBlue.shade900,
                                // when pressed, splash color is seen
                                splashColor: Colors.red,
                                // long press to identify highlight color
                                highlightColor: Colors.orange,
                                // if consistency is needed for all text style
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                // border properties for each toggle
                                renderBorder: true,
                                borderColor: Colors.black,
                                borderWidth: 1.5,
                                // borderRadius: BorderRadius.circular(10),
                                selectedBorderColor: Colors.pink,
// add widgets for which the users need to toggle
                                children: const [
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('Destination',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('Origin',
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ],
                                // to select or deselect when pressed
                                onPressed: (int newIndex) {
                                  setState(() {
                                    isChangingOrigin = newIndex == 1;
                                  });
                                })),
                      ],
                    ),
                  ),
                ],
              ), // contruct the map in the background
              const SomeScrollableContent(), // Contribute page
              const FloatingSearchAppBarExample(), // Saved page
            ],
          ),
        ),
        buildBottomNavigationBar(), // this is the lower navigation line which can be used to pass to\from different routes
      ],
    );
  }

  // Hold search list
  Widget buildExpandableBody(SearchModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ImplicitlyAnimatedList<Place>(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          items: model.suggestions,
          insertDuration: const Duration(milliseconds: 700),
          itemBuilder: (BuildContext context, Animation<double> animation,
              Place item, _) {
            return SizeFadeTransition(
              animation: animation,
              child: buildItem(context, item),
            );
          },
          updateItemBuilder:
              (BuildContext context, Animation<double> animation, Place item) {
            return FadeTransition(
              opacity: animation,
              child: buildItem(context, item),
            );
          },
          areItemsTheSame: (Place a, Place b) => a == b,
        ),
      ),
    );
  }

  // Display item on the search list
  Widget buildItem(BuildContext context, Place place) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    final SearchModel model = Provider.of<SearchModel>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            FloatingSearchBar.of(context)?.close();
            Future<void>.delayed(
              const Duration(milliseconds: 500),
              () => model.clear(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: model.suggestions == history
                        ? const Icon(Icons.history, key: Key('history'))
                        : const Icon(Icons.place, key: Key('place')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        place.level1Address,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.level2Address,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (model.suggestions.isNotEmpty && place != model.suggestions.last)
          const Divider(height: 0),
      ],
    );
  }

  // Build bottom bar
  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      onTap: (int value) => index = value,
      currentIndex: index,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      selectedFontSize: 11.5,
      unselectedFontSize: 11.5,
      unselectedItemColor: const Color(0xFF4d4d4d),
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.homeVariantOutline),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.homeCityOutline),
          label: 'Commute',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.bookmarkOutline),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.plusCircleOutline),
          label: 'Contribute',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.bellOutline),
          label: 'Updates',
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget Map(MapController mapController, Place originLocation,
      Place destinationLocation) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        buildMyMap2(mapController, originLocation, destinationLocation,
            visibleStations),
        buildFabs(), // fabs are the icons on the bottom right corner. not really interesting
        // Text(searchedLocation.toString(),
        //     style: TextStyle(
        //         color: Colors.black,
        //         fontSize: 20,
        //         fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget buildFabs() {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 16, end: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(
              builder: (BuildContext context) => FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<dynamic>(
                      builder: (BuildContext context) => const SearchBar2(),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.gps_fixed, color: Color(0xFF4d4d4d)),
              ),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () {
                // TODO - display stations in my area by communicating with the server
                loadStations();
                // List<Station>? stations = StationApi().getAllStationsInArea(
                // LatLng(32.0, 34.0), LatLng(31.0, 35.0));
              },
              heroTag: 'öslkföl',
              backgroundColor: Colors.blue,
              child: const Icon(Icons.directions),
            ),
          ],
        ),
      ),
    );
  }
}
