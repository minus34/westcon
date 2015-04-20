import collections
import json
# import math
# import os
import psycopg2


# Table to query
schema_name = "westcon"
table_name = "sa3_2011_sydney_bts"

# Set the number of decimal places for the output GeoJSON coordinate to reduce response size and to speed up rendering
places = 3
grid_string = 0.001

# Try to connect to Postgres
try:
    conn = psycopg2.connect("dbname='abs_2011' user='postgres' password='password'")
except:
    print "Unable to connect to the database."

cur = conn.cursor()

# The query
sql = "SELECT *, ST_AsGeoJSON(ST_SnapToGrid(geom, %s), %s, 0) AS geojson FROM %s.%s"
# sql = "SELECT sa3_code, sa3_name, o_motorists, d_motorists, ST_AsGeoJSON(ST_SnapToGrid(geom, %s), %s, 0) FROM %s.%s"
# "WHERE ST_Intersects(ST_SetSRID(ST_MakeBox2D(ST_Point(%s, %s), ST_Point(%s, %s)), 4283),geom)"

try:
    cur.execute(sql % (float(grid_string), places, schema_name, table_name))
except psycopg2.Error:
    print "I can't SELECT"
    print sql

# Get column names
col_names = [desc[0] for desc in cur.description]

# Create the GeoJSON output with an array of dictionaries containing the field names and values
rows = cur.fetchall()
dicts = []

for row in rows:
    rec = collections.OrderedDict()
    rec['type'] = 'Feature'

    props = collections.OrderedDict()
    props['id'] = row[3]
    props['name'] = row[4]

    num_cols = len(col_names) - 1

    # Loop through remaining columns of non-geo data and add to dictionary
    for i in range(5, num_cols):
        props[col_names[i]] = row[i]

    rec['properties'] = json.dumps(props)
    rec['geometry'] = row[num_cols]  # the GeoJSON, aka the last column

    dicts.append(rec)

gj = json.dumps(dicts).replace("\\", "").replace('"{', '{').replace('}"', '}')

# Output
print ''.join(['{"type":"FeatureCollection","features":', gj, '}'])
