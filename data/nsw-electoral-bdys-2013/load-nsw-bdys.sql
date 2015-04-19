
CLUSTER westcon.nsw_electoral_bdys_2013 USING nsw_electoral_bdys_2013_geom_idx;
ANALYSE westcon.nsw_electoral_bdys_2013;


--Create web friendly State Electorate Boundary table
DROP TABLE IF EXISTS westcon.nsw_electoral_bdys_2013_web;
CREATE TABLE westcon.nsw_electoral_bdys_2013_web
(
  id integer not null,
  "name" character varying(40) not null,
  electors integer not null,
  --projectedp integer null,
  o_motorists integer null,
  d_motorists integer null,
  x numeric(7,4) NULL,
  y numeric(6,4) NULL,
  geom geometry(MultiPolygon,4326) not null,
  CONSTRAINT nsw_electoral_bdys_2013_web_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.nsw_electoral_bdys_2013_web OWNER TO postgres;

CREATE INDEX sidx_nsw_electoral_bdys_2013_web_geom ON westcon.nsw_electoral_bdys_2013_web USING gist (geom);

INSERT INTO westcon.nsw_electoral_bdys_2013_web (id, "name", electors, geom) -- 142
SELECT id,
       "name",
       electors,
       --projectedp,
       --(ST_Dump(ST_Multi(ST_Buffer(ST_SnapToGrid(ST_Buffer(geom, 0.0),0.0001), 0.0)))).geom as geom
       ST_Transform(ST_Multi(ST_Union(ST_Buffer(ST_SnapToGrid(ST_Buffer(geom, 0.0),0.0001), 0.0))), 4326) as geom
  FROM westcon.nsw_electoral_bdys_2013
  WHERE id NOT IN (1,2,3,5,6,7,8,9,10,11,13,14,15,16,17,18,22,23,24,25)
  GROUP BY id,
           "name",
           electors;
           --projectedp;

CLUSTER westcon.nsw_electoral_bdys_2013_web USING sidx_nsw_electoral_bdys_2013_web_geom;
ANALYSE westcon.nsw_electoral_bdys_2013_web;

UPDATE westcon.nsw_electoral_bdys_2013_web
  SET x = ST_X(ST_Centroid(geom)),
      y = ST_Y(ST_Centroid(geom));

--SELECT * FROM westcon.nsw_electoral_bdys_2013_web; -- 347


-- Create web friendly NSW Travel Zone table
DROP TABLE IF EXISTS westcon.tz_nsw_2011_pnt;
CREATE TABLE westcon.tz_nsw_2011_pnt
(
  gid serial NOT NULL,
  tz_code11 character varying(10),
  tz_name11 character varying(100),
  dzn_code11 character varying(10),
  dzn_name11 character varying(100),
  sa2_main11 integer,
  sa3_code11 integer,
  sa4_code11 integer,
  gccsa_code character varying(5),
  sed_id integer,
  sed_name character varying(40),
  o_motorists integer not null,
  d_motorists integer not null,
  shape_leng numeric,
  shape_area numeric,
  geom geometry(Point,4326) NOT NULL,
  CONSTRAINT tz_nsw_2011_pnt_pkey PRIMARY KEY (gid)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.tz_nsw_2011_pnt OWNER TO postgres;

CREATE INDEX sidx_tz_nsw_2011_pnt_geom ON westcon.tz_nsw_2011_pnt USING gist (geom);

INSERT INTO westcon.tz_nsw_2011_pnt(tz_code11, tz_name11, dzn_code11, dzn_name11, sa2_main11, sa3_code11, sa4_code11, gccsa_code, o_motorists, d_motorists, shape_leng, shape_area, geom) -- 3514
SELECT tz_code11::character varying(10),
       tz_name11,
       dzn_code11,
       dzn_name11,
       sa2_main11,
       sa3_code11,
       sa4_code11,
       gccsa_code,
       0,
       0,
       shape_leng,
       shape_area,
       ST_Centroid(ST_Transform(ST_Buffer(geom, 0.0), 4326))
  FROM westcon.tz_nsw_2011;

CLUSTER westcon.tz_nsw_2011_pnt USING sidx_tz_nsw_2011_pnt_geom;
ANALYSE westcon.tz_nsw_2011_pnt;

--SELECT Count(*) FROM westcon.tz_nsw_2011_pnt; -- 3514


-- Get the state electoral district for each travel zone -- 3514
UPDATE westcon.tz_nsw_2011_pnt as tz
  SET sed_id = sed.id,
      sed_name = sed."name"
  FROM westcon.nsw_electoral_bdys_2013_web as sed
  WHERE ST_Within(tz.geom, sed.geom);


-- Import NSW BTS Journey to Work data
DROP TABLE IF EXISTS westcon.jtw_table2011eh07;
CREATE TABLE westcon.jtw_table2011eh07
(
  o_tz11 character varying(10),
  o_tz_name11 character varying(100),
  o_lga_code11 character varying(10),
  o_lga_name11 character varying(100),
  o_sa2_11 integer,
  o_sa2_name11 character varying(100),
  o_sa3_11 integer,
  o_sa3_name11 character varying(100),
  o_sa4_11 integer,
  o_sa4_name11 character varying(100),
  o_ste_11 smallint,
  o_ste_name11 character varying(100),
  o_study_area_11 smallint,
  o_study_area_name11 character varying(100),
  o_lga_study_area_name11 character varying(100),
  d_tz11 character varying(10),
  d_tz_name11 character varying(100),
  d_lga_code11 integer,
  d_lga_name11 character varying(100),
  d_sa2_11 integer,
  d_sa2_name11 character varying(100),
  d_sa3_11 integer,
  d_sa3_name11 character varying(100),
  d_sa4_11 integer,
  d_sa4_name11 character varying(100),
  d_ste_11 smallint,
  d_ste_name11 character varying(100),
  d_study_area_11 smallint,
  d_study_area_name11 character varying(100),
  d_lga_study_area_name11 character varying(100),
  mode10 smallint,
  mode10_name character varying(100),
  uaicp smallint,
  uaicp_name character varying(100),
  employed_persons numeric(10,2)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.jtw_table2011eh07 OWNER TO postgres;

COPY westcon.jtw_table2011eh07 FROM 'C:\\minus34\\GitHub\\WestCON\\data\\nsw-bts-travel-zones\\2011JTW_TableEH07.csv' CSV HEADER; -- 783,237

UPDATE westcon.jtw_table2011eh07 SET o_tz11 = trim(o_tz11) WHERE o_tz11 = ' '; -- 4282

ANALYSE westcon.jtw_table2011eh07;


-- Update motorist counts for origin travel zones -- 3364
UPDATE westcon.tz_nsw_2011_pnt AS tz
  SET o_motorists = jtw.motorists
  FROM (
    SELECT o_tz11,
           SUM(employed_persons)::integer AS motorists
    FROM westcon.jtw_table2011eh07
    WHERE mode10 IN (4, 5)
    AND o_tz11 <> '' AND d_tz11 <> ''
    --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
    GROUP BY o_tz11
  ) AS jtw
  WHERE jtw.o_tz11 = tz.tz_code11;


-- Update motorist counts for destination travel zones -- 3505 
UPDATE westcon.tz_nsw_2011_pnt AS tz
  SET d_motorists = jtw.motorists
  FROM (
    SELECT d_tz11,
           SUM(employed_persons)::integer AS motorists
    FROM westcon.jtw_table2011eh07
    WHERE mode10 IN (4, 5)
    AND o_tz11 <> '' AND d_tz11 <> ''
    --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
    GROUP BY d_tz11
  ) AS jtw
  WHERE jtw.d_tz11 = tz.tz_code11;


-- Update motorist counts for electoral districts
UPDATE westcon.nsw_electoral_bdys_2013_web AS sed
  SET o_motorists = tz.o_motorists,
      d_motorists = tz.d_motorists
  FROM (
    SELECT sed_id,
           SUM(o_motorists) AS o_motorists,
           SUM(d_motorists) AS d_motorists
    FROM westcon.tz_nsw_2011_pnt
    GROUP BY sed_id
  ) AS tz
  WHERE sed.id = tz.sed_id;


-- -- Update motorist counts for each electoral district going to a specific one
-- UPDATE westcon.nsw_electoral_bdys_2013_web AS sed
--   SET o_motorists_91 = sqt.motorists
--   FROM (
--     SELECT otz.sed_id,
--            SUM(jtw.employed_persons)::integer AS motorists
--     FROM westcon.tz_nsw_2011_pnt as dtz
--     INNER JOIN westcon.jtw_table2011eh07 as jtw
--     ON jtw.d_tz11 = dtz.tz_code11
--     INNER JOIN westcon.tz_nsw_2011_pnt as otz
--     ON jtw.o_tz11 = otz.tz_code11
--     WHERE jtw.mode10 IN (4, 5)
--     AND dtz.sed_id = 91
--     GROUP BY otz.sed_id
--   ) AS sqt
--   WHERE sed.id = sqt.sed_id;
-- 
-- 
-- -- Update motorist counts for each electoral district going to a specific one
-- UPDATE westcon.nsw_electoral_bdys_2013_web AS sed
--   SET o_motorists_58 = sqt.m
--   FROM (
--     SELECT otz.sed_id, SUM(jtw.employed_persons)::integer AS m FROM westcon.tz_nsw_2011_pnt as dtz
--     INNER JOIN westcon.jtw_table2011eh07 as jtw ON jtw.d_tz11 = dtz.tz_code11
--     INNER JOIN westcon.tz_nsw_2011_pnt as otz ON jtw.o_tz11 = otz.tz_code11
--     WHERE jtw.mode10 IN (4, 5) AND dtz.sed_id = 58
--     GROUP BY otz.sed_id
--   ) AS sqt
--   WHERE sed.id = sqt.sed_id;
-- 
-- 
-- 
-- select d_motorists from westcon.nsw_electoral_bdys_2013_web WHERE id = 34; -- 63802 -- 12314
-- 
-- select SUM(motorists) from ( -- 63443
--   SELECT sum(o_motorists_58) as motorists FROM westcon.nsw_electoral_bdys_2013_web
-- ) as sqt;
-- 
-- select min(id) from westcon.nsw_electoral_bdys_2013
-- select max(id) from westcon.nsw_electoral_bdys_2013
-- 
-- 
-- select * from westcon.nsw_electoral_bdys_2013 WHERE id = 53
-- 
-- 
-- 
