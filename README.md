/* Copyright (C) Ofir Dubi - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Ofir Dubi, 2023
 */

# Tremp

tremp app
This is the repo for the app that's a combination between Moovit and Waze, and it's suppose to solve the following problem - 
if someone can give you a ride, but he will only diviate 5-min from his planned trajectory, what is the best possible drop location i can get, 
so that continuing from there by public transportaion will provide the shourtest trip time.

## Phase 1 - The Algorithm
I need to figure out alot of stuff - 
1. how can i connect to Google API (or is there another possible way to achive maps data).
2. how can i connect to bus API
3. Should the algorithem run on the phone or on a server - for starters i will do it on the server, and will develop a python client side beacuse idk how to do an app

ok... This problem is conceptually kind of solved - There is this thing called Multimodal transportaion. and google maps at some locations will allow you
to include an Uber ride in your trip. So basically i need to replace that Uber ride with a ride from the starting location to a location in X min radius.
I will start with that, and maybe then i will run this search again on the length of original car trajectory.
This is not so nice as it's O(n), it will be better to use Djikstra's, and to make each car edge i take will have a "price", and there is a sum that i can't pass (5 min).


So... lets get started. First i need the data.

## The Database
I'm probably gonna use OpenStreetMap
Advantages - 
    * open data about ways and routes
    * can provide distance.
    * has data about bus stations
    * Has speed limit of some ways, not all of them
        * I can probably infer the speed limits of the missing onse by road type (Primary roads).
    * There are some routing apps which are based on the map's data, so it should also have the driving direction of roads.
        * Yes - the order in which the nodes apear in a way, is the order in which the traffic flows.
Disadvantages - 
    * Does not provide speed limits for all roads 
    * Does not have live trafic data (rush hours, traffic jams, etc).
    * Not sure if it has railway information
        * That can be added at a later time. 

## Quick search - 
    * I can use Photon for this, it uses elastic search on OpenStreetMap, which is kindof what i wanted to do anyway. 


# The Algorithm
an "Isochrone" can be fetcehd - given a location and a time travel contraint, an Isochrone is a polygon which includes all the points the car can get to within that time limit. 
This is pretty usefull for me, as what i'd like to do is generate a path for the car, then get Isochrones for the car path (i can do this efficiently i guess),

And then basically get the best starting node from within that graph to the target location. This can be tricky, because i don't just want to run this calculation on all the nodes. 
I can use a greedy method maybe - 
    1. I will search for each node on the original route
    2. For each node, i will search for it's neighbors. 
    3. For each neighbor, I will keep searching his neighbor only
        If it produced a better result then the original search did. 
        * Of course this can lead to mistakes, but maybe it won't 

* A* Algorith - Like Djikstra's, but to every node, you add to the minimal cost of going to it it's distance from the target destenation.  
A* is obviosly the way to go.
Let's say driver is going from A to B, and i need to get from A to C.
If i want a quick POC, i can use the following -
    1. Get GSM data, populate all bust stations, ETC. 
    2. Get route (or let's say top 3 routes) with car for the drivers original destenation
        2.1 for each node, get the nodes which are 5-min driver from this node.
            2.1.a This can be optimized, i should probably use Isochrone for this. 
    3. Add all this route as a new bus line to the existing GSM data.
    4. Search for a route using "public transportation", only this will allow us to compine Tremps. 

* An interesting thing to see is how are multi-modal route serching is done, and i can just copy this insetead of theorising about stuff. options are

# The Algorithm - with a Car (18/02/2024)
* A naive approach which i can implement now is to take the fastest car route from A to B, and insert it to the timetable as some line 
* I could implement an X minute detour by using an Isochrone, and adding all the stops in the Isochrone's range to possible stops the car can stop in.
* After doing that when doing my RAPTOR search for each stop i will check if i can join the car trip now, and if so treat this as another trip to be investigated in this round.

* This method is not good however, as it only considers the faster route the car can go in.
* There could be a situation where another route is 5 min slower, but is not in the 5 min Isochrone of this route.
* In order to solve this i will do the following - 
1. search the fastest car route from A to B. set it to X. say we have an agreed deviation time of 5.
2. do a one-to-many search from A to every station, and many-to-one from every station to B.
    a. This query can be time-limited - the combined journy must be shorter than X+5, so at the least we can limit each of them by X+5.
3. Prune all of the irrelevant stations - only keep station S if A->S->B takes less than X+5 time. 
4. At the end we will remain with station that it is possible for the car to pass through.

Note that this provides a solution for the case in which the passenger either departs from A or arrives at B, and need to be picked up or dropped of.
Alas, this is not always the case. Sometimes i'd like a ride from one bus or train station to another.
E.G. i wanna get from my house in TLV to a house in BS, and someone is going form TLV to BS by car. 
But i think i can build around that and then improve it to match all scenarios 



## Steps for 7/12/2023:
 - done - Get Location data of TLV instead of berlin (for fun)
 - done -Setup IDE
   - Get GTFS data of TLV.
        This seems to be tricky. I can get the basic example kindof working, but when i try to laod israel data,
        It complains that the GTFS is broken, and it does so only after 30 min of loading...
 - Read about multi-modal routing

## Steps for 13/7/2023:
    Following yesterday, i believe that GraphHopper will not work out of the box for me, so i'll try to use Valhalla.
    Maybe i should consider trying to find something that works well for public transportaion first.

# So let's fix israels GTFS!! 
* i run the validator, sees that there are missing collumes in the translation table - it seems like it jsut not build right... 

# I wil say that GraphHopper was very easy to setup.
## Phase 2 - The App.


This is a "Beaya handasit", so i'll deal with it once i have Phase 1 down. 

I do have a dilema here - web based or native? 
I think regardless of what i decide i can develop it and run it first with GraphHopper testing. 

## Alternative for GraphHopper - 
* https://openrouteservice.org/ - doesn't seem to support public transportaion
* https://organicmaps.app/  - maybe i can use this, the code has support for GFTS but i can't get it to work locally ATM
* Valhalla - sounds like this could work... 

*  OpenTripPlanner, TripGo and Mapzen 

## 08/17/2023 
After viewing some lectures about SOTA algorithms, i've decided on the following steps 
    1. Write a parser for IS gtfs feed - should be like normal gtfs with google extensions. 
        1.2. Checkpoint - present the data from gtfs on a map, to see that i know what i'm doing. 
    2. Write a RAPTOR implementation (in CPP\python) for finding best paths using my GTFS feed
        2.2 Checkpoint - present the best found graph on a map.
        2.3 Integrate multi-modal trips - do this using  ULTRA-RAPTOR.
    3. Integrate Tremps as a transportation method using the following method - 
        a. Insert driver's original route (including departue-time)
        b. Find fastest route using A*\A* with CH.
        c. Get isotropic somthing on said route (produces entire stations in X min detour from said route)
        d. Unpack the route found on the time table - treat the driver as a new line, and for every station node it in the isotropic region, inseart a new "stop" for in that station.
            How to calculate the new stop time? might be tricky, need to see how i can unpack a fastest route, but shouldn't really be a problem i think.
        3.1 Checkpoint - present this new line in line map (practically re-do 1.2)
    4. Now when i run my RAPTOR implementation, it should consider the new line i added and give results according to it.



## 09/17/2023 
* I got israels GTFS working and parsed, and done a reduction to TLV area, so it is easier to test.
* I've built a timetable class, TODO: make sure it has everything we need for a raptor run.
* TODO: i need to build some more visualisation framework, at list a way to show a trip with arrows and stuff, 
    and maybe even show different trips with different colors. maybe just display connections, and connection color is derived from the trip.
* Next TODO after this is to implement a simple RAPTOR to see that i can handle basic stuff. 
* Then i need to decide if i tackle walking, or if i tackle adding a car as a route. 
    Right now i'm leaning towards walking, at least the basic stuff, because without it nothing will be practical. 
    GN

## 09/22/2023 
* I've worked alot on matching shapes to stops, so a single connection now holds a shape between stations.
* Now i need to do some actual programming of an algorithm i guess, let's go for a raptor!

## 09/24/2023 
* Finished RAPTOR! it works, produces the best outcome (shortest arrival time) for a start time, start_station, arrival_station
* Next steps - 
    * add walking, so i can choose starting location instead of starting station (hard)
    * add variance in depature time (leave at +- 15 min to get lower travel time or lower transfers)
* Then the actual next big step will be adding car routing, which will involve more pre-processing, algorithms, and such.
* I can simutaniusly develop the option for being given a car route, integrate it into the multi-modal algorithm.

## Integrating with pyvalhalla
I think i will start integration with pyvalhalla (python bindings for valhalla). I'll do this first for getting walk-to-station, so i can complement my RAPTOR design with it.
After that is done, i can use Valhalla to get car routes to add to my RAPTOR.
Note - pyvalhalla is GNU license, which means i can't use it without making my code opensource, bu Vallhalla is MIT.
So before moving to production i need to make python bindings myselfe, or even better - just use Native valhalla.


## 15/02/2024
* It's been a while. War and everything. Let's see what we did last time - Is the Walking raptor works?
* Seems like i was going for ULTRA - which has a preprocessing phase to create shortcuts which is expensive, followed by one-to-many queries from s and t to all stations.
* I think what i decided to do is to avoid the preprocessing for now, and only do the one-to-many. And what did i do with walking between nearby stations? Yes
* Ok so i have something which is running, but i do not think it yields optimal results. I need to examine it with mooveit.
Ok, i've verified that the walk to start stations is performed currectly. 
* I need to improve a bit my debugging - i need to get an easy way to check for timings of a certain station. - Did it.
* I suspect that my routing continues to traverse to stations which i don't have any point going to, because if time is above limit which it takes me to reach the target i shouldn't investigate more stations, but i get tons of stations still in the last raptor round.  - Did it.

## 16/02/2024
* What next? my ULTRA works fine enough i think, might find some more bugs in it later but it's good enough i can work with it.
* Two options moving forward - relax footpaths between stations, or add car as a route. i'm afraid that without relaxing the footpaths
  Adding a car won't improve much on my current results, because i won't be able to cross the road to the other side.  
* So it's decided - i need to relax them footpaths!!!
* How to do this - i should do it with the preprocessing shortcut path mentioned in the ULTRA video, i really need to reiterate it. 
* What i really need to understand is how to relax footpaths in raptor. only then it will be possible for me to do it

## 17/02/2024
* Ok, i've added precomputation to get footpath time from each station to each other station in one KM radius from it!
* Next step - use this information inside raptor to integrate walking!

## 18/02/2024
* Steps for today - implement footpath relaxiation in RAPTOR
* Ok i did it!
* Note that i came across a problem wit wrap around of 24H clock... i dealt with it in a very ugly way, TODO actually deal with it.
* Now i think i'm ready to add Car routing!



# to generate new tiles (shouldn't be done much)
1. put ISR israel-and-palestine-latest.osm.pbf in custom_files
2. docker run --rm -dt --name valhalla_gis-ops -p 8002:8002 -v %cd%/custom_files:/custom_files ghcr.io/gis-ops/docker-valhalla/valhalla:latest
https://github.com/gis-ops/docker-valhalla

# links
https://www.youtube.com/watch?v=AdArDN4E6Hg&t=1s&ab_channel=DFG-FOR2083
