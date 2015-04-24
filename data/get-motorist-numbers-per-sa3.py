#!/usr/bin/env python

import os
import collections
import psycopg2
import shutil
import sys
import urllib
import urllib2
import zipfile

# postgres parameters
db_user_name = "postgres"
# db_password = "<yourpassword>"
db_server = "localhost"
db_name = "abs_2011"
db_schema = "westcon"
db_port = 5432

# postgres connect string - need to use password version if trust not set on server
# db_conn_string = "host='%s' dbname='%s' user='%s' password='%s' port=%s"
db_conn_string = "host='%s' dbname='%s' user='%s' port=%s"

# connect to postgres
# need to use password version if trust not set on server
# conn = psycopg2.connect(db_conn_string % (db_server, db_name, db_user_name, db_password, db_port))
conn = psycopg2.connect(db_conn_string % (db_server, db_name, db_user_name, db_port))

conn.autocommit = True
cur = conn.cursor()

# create tables and populate them
cur.execute(open("C:\\minus34\\GitHub\\WestCON\\data\\prep-nsw-bts-data-sa3.sql", "r").read())

# Get array of sa3 codes
cur.execute("SELECT sa3_code FROM westcon.sa3_2011_sydney_bts ORDER BY sa3_code")
rows = cur.fetchall()
bdy_ids = []

for row in rows:
    bdy_ids.append(row[0])

maxvalue = 0

# for each destination sa3 - get the motorist count from each journey origin sa3
for bdy_id in bdy_ids:
    cur.execute("ALTER TABLE westcon.sa3_2011_sydney_bts ADD COLUMN o_%s INTEGER" % (bdy_id,))

    sql = "UPDATE westcon.sa3_2011_sydney_bts AS bdy " \
        "SET o_%s = jtw.motorists " \
        "FROM westcon.sa3_2011_sydney_motorists AS jtw " \
        "WHERE jtw.d_sa3_code = bdy.sa3_code " \
        "AND jtw.o_sa3_code = %s"

    # "SELECT otz.o_sa3_11, SUM(jtw.employed_persons)::integer AS motorists FROM westcon.tz_nsw_2011_pnt as dtz " \
    # "INNER JOIN westcon.jtw_table2011eh07 as jtw ON jtw.d_tz11 = dtz.tz_code11 " \
    # "INNER JOIN westcon.tz_nsw_2011_pnt as otz ON jtw.o_sa3_11 = otz.o_sa3_11 " \
    # "WHERE jtw.mode10 IN (4, 5) AND dtz.o_sa3_11 = %s " \
    # "GROUP BY otz.o_sa3_11 " \
    # ") AS sqt " \
    # "WHERE sa3.sa3_code = sqt.o_sa3_11;"

    cur.execute(sql % (bdy_id, bdy_id))

    # replace NULLs
    sql = "UPDATE westcon.sa3_2011_sydney_bts SET o_%s = 0 WHERE o_%s IS NULL;"
    cur.execute(sql % (bdy_id, bdy_id))

    # get counts for qa
    cur.execute("select o_motorists from westcon.sa3_2011_sydney_bts WHERE sa3_code = %s;" % (bdy_id,))
    destcount = cur.fetchone()[0]

    cur.execute("SELECT sum(o_%s) as motorists FROM westcon.sa3_2011_sydney_bts;" % (bdy_id,))
    originsumcount = cur.fetchone()[0]

    # get max value (for the mapping)
    cur.execute("SELECT max(o_%s) as motorists FROM westcon.sa3_2011_sydney_bts "
                "WHERE sa3_code <> %s;" % (bdy_id, bdy_id))
    sa3maxvalue = cur.fetchone()[0]

    if sa3maxvalue > maxvalue:
        maxvalue = sa3maxvalue

    print "ID : %s, max value = %s, delta = %s" % (bdy_id, str(sa3maxvalue), str(destcount - originsumcount))


print "FINISHED, overall max value is %s" % (str(maxvalue),)

