.PHOHY: server


serve:
	cd docs && python -m http.server

docs/stations.json:
	ssh bus-cnc.backslasher.net ./tiny-psql -t -c "\"select array_to_json(array_agg(row_to_json (r))) from (SELECT * FROM gtfs_stop WHERE date='2022-12-01') r;\"" >docs/stations.json
