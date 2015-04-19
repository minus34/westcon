#!/usr/bin/env python

import os
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
cur.execute(open("C:\\minus34\\GitHub\\WestCON\\data\\load-nsw-bdys.sql", "r").read())

maxvalue = 0

# for each destination electoral district id - get the motorist count from each journey origin electoral district
for i in range(1, 96):

    if i not in [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 22, 23, 24, 25, 33, 43]:  # these don't exist
        cur.execute("ALTER TABLE westcon.nsw_electoral_bdys_2013_web ADD COLUMN o_%s INTEGER" % (str(i),))

        sql = "UPDATE westcon.nsw_electoral_bdys_2013_web AS sed " \
            "SET o_%s = sqt.m " \
            "FROM ( " \
            "SELECT otz.sed_id, SUM(jtw.employed_persons)::integer AS m FROM westcon.tz_nsw_2011_pnt as dtz " \
            "INNER JOIN westcon.jtw_table2011eh07 as jtw ON jtw.d_tz11 = dtz.tz_code11 " \
            "INNER JOIN westcon.tz_nsw_2011_pnt as otz ON jtw.o_tz11 = otz.tz_code11 " \
            "WHERE jtw.mode10 IN (4, 5) AND dtz.sed_id = %s " \
            "GROUP BY otz.sed_id " \
            ") AS sqt " \
            "WHERE sed.id = sqt.sed_id;"

        cur.execute(sql % (str(i), str(i)))

        # replace NULLs
        sql = "UPDATE westcon.nsw_electoral_bdys_2013_web SET o_%s = 0 WHERE o_%s IS NULL;"
        cur.execute(sql % (str(i), str(i)))

        # get counts for qa
        cur.execute("select d_motorists from westcon.nsw_electoral_bdys_2013_web WHERE id = %s;" % (str(i),))
        destcount = cur.fetchone()[0]

        cur.execute("SELECT sum(o_%s) as motorists FROM westcon.nsw_electoral_bdys_2013_web;" % (str(i),))
        originsumcount = cur.fetchone()[0]

        # get max value (for the mapping)
        cur.execute("SELECT max(o_%s) as motorists FROM westcon.nsw_electoral_bdys_2013_web "
                    "WHERE id <> %s;" % (str(i), str(i)))
        sedmaxvalue = cur.fetchone()[0]

        if sedmaxvalue > maxvalue:
            maxvalue = sedmaxvalue

        print "ID : %s, max value = %s, delta = %s" % (str(i), str(sedmaxvalue), str(destcount - originsumcount))


print "FINISHED, overall max value is %s" % (str(maxvalue),)

