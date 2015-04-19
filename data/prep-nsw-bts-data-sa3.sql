-- 
-- -- Import NSW BTS Journey to Work data
-- DROP TABLE IF EXISTS westcon.jtw_table2011eh07;
-- CREATE TABLE westcon.jtw_table2011eh07
-- (
--   o_tz11 character varying(10),
--   o_tz_name11 character varying(100),
--   o_lga_code11 character varying(10),
--   o_lga_name11 character varying(100),
--   o_sa2_11 integer,
--   o_sa2_name11 character varying(100),
--   o_sa3_11 integer,
--   o_sa3_name11 character varying(100),
--   o_sa4_11 integer,
--   o_sa4_name11 character varying(100),
--   o_ste_11 smallint,
--   o_ste_name11 character varying(100),
--   o_study_area_11 smallint,
--   o_study_area_name11 character varying(100),
--   o_lga_study_area_name11 character varying(100),
--   d_tz11 character varying(10),
--   d_tz_name11 character varying(100),
--   d_lga_code11 integer,
--   d_lga_name11 character varying(100),
--   d_sa2_11 integer,
--   d_sa2_name11 character varying(100),
--   d_sa3_11 integer,
--   d_sa3_name11 character varying(100),
--   d_sa4_11 integer,
--   d_sa4_name11 character varying(100),
--   d_ste_11 smallint,
--   d_ste_name11 character varying(100),
--   d_study_area_11 smallint,
--   d_study_area_name11 character varying(100),
--   d_lga_study_area_name11 character varying(100),
--   mode10 smallint,
--   mode10_name character varying(100),
--   uaicp smallint,
--   uaicp_name character varying(100),
--   employed_persons numeric(10,2)
-- )
-- WITH (OIDS=FALSE);
-- ALTER TABLE westcon.jtw_table2011eh07 OWNER TO postgres;
-- 
-- COPY westcon.jtw_table2011eh07 FROM 'C:\\minus34\\GitHub\\WestCON\\data\\nsw-bts-travel-zones\\2011JTW_TableEH07.csv' CSV HEADER; -- 783,237
-- UPDATE westcon.jtw_table2011eh07 SET o_tz11 = trim(o_tz11) WHERE o_tz11 = ' '; -- 4282
-- ANALYSE westcon.jtw_table2011eh07;


-- Create web friendly NSW Travel Zone table
DROP TABLE IF EXISTS westcon.sa3_2011_sydney_bts;
CREATE TABLE westcon.sa3_2011_sydney_bts
(
  sa3_code integer NOT NULL,
  sa3_name character varying(50) NOT NULL,
  o_motorists integer NOT NULL,
  d_motorists integer NOT NULL,
  geom geometry(MultiPolygon,4326, 2) NOT NULL,
  CONSTRAINT sa3_2011_sydney_bts_pkey PRIMARY KEY (sa3_code)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.sa3_2011_sydney_bts OWNER TO postgres;

CREATE INDEX sidx_sa3_2011_sydney_bts_geom ON westcon.sa3_2011_sydney_bts USING gist (geom);

INSERT INTO westcon.sa3_2011_sydney_bts(sa3_code, sa3_name, o_motorists, d_motorists, geom) -- 3514
SELECT sa3_code::integer,
       sa3_name,
       0,
       0,
       ST_Transform(ST_Multi(ST_Buffer(geom, 0.0)), 4326)
  FROM westcon.sa3_2011_sydney;

CLUSTER westcon.sa3_2011_sydney_bts USING sidx_sa3_2011_sydney_bts_geom;
ANALYSE westcon.sa3_2011_sydney_bts;


-- Update motorist counts for origin travel zones -- 41
UPDATE westcon.sa3_2011_sydney_bts AS sa3
  SET o_motorists = jtw.motorists
  FROM (
    SELECT o_sa3_11,
           SUM(employed_persons)::integer AS motorists
    FROM westcon.jtw_table2011eh07
    WHERE mode10 IN (4, 5)
    AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
    --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
    GROUP BY o_sa3_11
  ) AS jtw
  WHERE jtw.o_sa3_11 = sa3.sa3_code;


-- Update motorist counts for destination travel zones -- 41 
UPDATE westcon.sa3_2011_sydney_bts AS sa3
  SET d_motorists = jtw.motorists
  FROM (
    SELECT d_sa3_11,
           SUM(employed_persons)::integer AS motorists
    FROM westcon.jtw_table2011eh07
    WHERE mode10 IN (4, 5)
    AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
    --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
    GROUP BY d_sa3_11
  ) AS jtw
  WHERE jtw.d_sa3_11 = sa3.sa3_code;


SELECT * FROM westcon.sa3_2011_sydney_bts; -- 41
SELECT SUM(o_motorists), SUM(d_motorists) FROM westcon.sa3_2011_sydney_bts; -- 1,102,028; 1,099,290


--Create table of motorist counts for each combination of origin and destination SA3 -- 6966
DROP TABLE IF EXISTS westcon.sa3_2011_sydney_motorists;
CREATE TABLE westcon.sa3_2011_sydney_motorists
(
  o_sa3_code integer NOT NULL,
  d_sa3_code integer NOT NULL,
  motorists integer NOT NULL,
  o_x numeric(6,3),
  o_y numeric(5,3),
  d_x numeric(6,3),
  d_y numeric(5,3),
  CONSTRAINT sa3_2011_sydney_motorists_pnt_pkey PRIMARY KEY (o_sa3_code, d_sa3_code)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.sa3_2011_sydney_motorists OWNER TO postgres;

INSERT INTO westcon.sa3_2011_sydney_motorists (o_sa3_code, d_sa3_code, motorists)
SELECT o_sa3_11,
       d_sa3_11,
       SUM(employed_persons)::integer AS motorists
  FROM westcon.jtw_table2011eh07
  WHERE mode10 IN (4, 5)
  AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
GROUP BY o_sa3_11,
         d_sa3_11;

UPDATE westcon.sa3_2011_sydney_motorists AS mot
  SET o_x = ST_X(ST_Centroid(bdys.geom))
     ,o_y = ST_Y(ST_Centroid(bdys.geom))
  FROM westcon.sa3_2011_sydney_bts AS bdys
  WHERE mot.o_sa3_code = bdys.sa3_code;

UPDATE westcon.sa3_2011_sydney_motorists AS mot
  SET d_x = ST_X(ST_Centroid(bdys.geom))
     ,d_y = ST_Y(ST_Centroid(bdys.geom))
  FROM westcon.sa3_2011_sydney_bts AS bdys
  WHERE mot.d_sa3_code = bdys.sa3_code;

--Only keep rows that have coords (i.e. Sydney sa3's with geoms)
DELETE FROM westcon.sa3_2011_sydney_motorists
  WHERE o_x IS NULL OR d_x IS NULL;


COPY westcon.sa3_2011_sydney_motorists TO 'C:\\minus34\\GitHub\\WestCON\\sa3_2011_sydney_motorists.csv' CSV

