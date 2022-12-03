# Phantom stops
## Abstract
**Phantom stop:** When a bus is supposed to arrive at the station, but just doesn't.
It's not that the bus arrives late or early, it just doesn't show up.
The ETA counter at the station gets to 0 and then back to 30 (whenever the next bus arrives), without any bus being seen.

I'd like to get meaningful statistics on when and where such a phantom stop occurs, potentially aggregating the info (e.g. Line 61 at bus stop 21614 had 21% phantom stops on 2022-03-14)  

## Dataset
https://github.com/hasadna/open-bus-stride-db/blob/main/DATA_MODEL.md
Using a data dump (https://open-bus-siri-requester.hasadna.org.il/stride_db_backup/stride_db.sql.gz) which is then loaded into an RDS instance (so I can run SQL queries by myself)

TODO more explenation here if needed

The dataset contains `siri_ride_stop` which maps a planned stop to "the nearest bus around". This field can be null, meaning no such bus is found.
I use this nullability as an indicator that this is a Phantom Stop. 

## Initial results
Raw data:
```
SELECT gtfs_route.route_short_name, gtfs_stop.code, gtfs_ride_stop.arrival_time, siri_vehicle_location.distance_from_siri_ride_stop_meters, siri_vehicle_location.recorded_at_time
FROM gtfs_stop
INNER JOIN gtfs_ride_stop ON gtfs_ride_stop.gtfs_stop_id = gtfs_stop.id
INNER JOIN gtfs_ride ON gtfs_ride.id = gtfs_ride_stop.gtfs_ride_id
INNER JOIN gtfs_route ON gtfs_route.id = gtfs_ride.gtfs_route_id
INNER JOIN siri_ride ON siri_ride.gtfs_ride_id = gtfs_ride.id 
LEFT JOIN siri_ride_stop ON gtfs_stop.id = siri_ride_stop.gtfs_stop_id AND siri_ride_stop.siri_ride_id = siri_ride.id
LEFT JOIN siri_vehicle_location ON siri_vehicle_location.id = siri_ride_stop.nearest_siri_vehicle_location_id
WHERE gtfs_stop.date='2022-03-14' AND gtfs_stop.code=21614 AND gtfs_route.date = '2022-03-14' AND gtfs_route.route_short_name='61'
ORDER BY gtfs_ride_stop.arrival_time;
```

Aggregate:
```
SELECT gtfs_route.route_short_name, gtfs_stop.code, 100*count(siri_vehicle_location.distance_from_siri_ride_stop_meters)/count(gtfs_route.*) AS showed_up_pct
FROM gtfs_stop
INNER JOIN gtfs_ride_stop ON gtfs_ride_stop.gtfs_stop_id = gtfs_stop.id
INNER JOIN gtfs_ride ON gtfs_ride.id = gtfs_ride_stop.gtfs_ride_id
INNER JOIN gtfs_route ON gtfs_route.id = gtfs_ride.gtfs_route_id
INNER JOIN siri_ride ON siri_ride.gtfs_ride_id = gtfs_ride.id 
LEFT JOIN siri_ride_stop ON gtfs_stop.id = siri_ride_stop.gtfs_stop_id AND siri_ride_stop.siri_ride_id = siri_ride.id
LEFT JOIN siri_vehicle_location ON siri_vehicle_location.id = siri_ride_stop.nearest_siri_vehicle_location_id
WHERE gtfs_stop.date='2022-03-14' AND gtfs_stop.code=21614 AND gtfs_route.date = '2022-03-14' AND gtfs_route.route_short_name='61'
GROUP BY gtfs_route.route_short_name, gtfs_stop.code;
```
```
 route_short_name | code  | showed_up_pct 
------------------+-------+---------------
 61               | 21614 |            69
```

## Followups
I'd like to see whether I can get this data via the API. I doubt this is feasable.
I'm also interested in running this on a bigger-scale DB (my current one only has 3 days of data from March 2022).
Lastly, I'm considering exporting this in a way that is more user friendly, e.g. a graph or a map.
