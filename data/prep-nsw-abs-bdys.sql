
-- DELETE FROM westcon.sa2_2011_aust WHERE state_code <> '1';
-- DELETE FROM westcon.sa3_2011_aust WHERE state_code <> '1';
-- DELETE FROM westcon.sa3_2011_aust WHERE state_code <> '1';
-- 
-- CLUSTER westcon.sa2_2011_aust USING sa2_2011_aust_geom_idx;
-- CLUSTER westcon.sa3_2011_aust USING sa3_2011_aust_geom_idx;
-- CLUSTER westcon.sa4_2011_aust USING sa4_2011_aust_geom_idx;
-- 
-- ANALYSE westcon.sa2_2011_aust;
-- ANALYSE westcon.sa3_2011_aust;
-- ANALYSE westcon.sa4_2011_aust;

-- ANALYSE westcon.sa3_2011_sydney;
-- CLUSTER westcon.sa3_2011_sydney USING sa3_2011_sydney_geom_idx;


--Create web ready tables

-- SA2
DROP TABLE IF EXISTS westcon.sa2_2011_aust_web;
CREATE TABLE westcon.sa2_2011_aust_web
(
  gid serial NOT NULL,
  sa2_main character varying(9) NOT NULL,
  sa2_name character varying(50) NOT NULL,
  state_code character varying(1) NOT NULL,
  state_name character varying(50) NOT NULL,
  area_sqkm numeric NOT NULL,
  geom geometry(MultiPolygon,4326,2) NOT NULL,
  CONSTRAINT sa2_2011_aust_web_pkey PRIMARY KEY (gid)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.sa2_2011_aust_web OWNER TO postgres;

CREATE INDEX sa2_2011_aust_web_geom_idx ON westcon.sa2_2011_aust_web USING gist (geom);
CLUSTER westcon.sa2_2011_aust_web USING sa2_2011_aust_web_geom_idx;

INSERT INTO westcon.sa2_2011_aust_web (sa2_main, sa2_name, state_code, state_name, area_sqkm, geom)
SELECT sa2_main, sa2_name, state_code, state_name, area_sqkm,
       ST_Transform(ST_Multi(ST_Buffer(ST_SnapToGrid(ST_Buffer(geom, 0.0),0.0001), 0.0)), 4326) AS geom 
  FROM westcon.sa2_2011_aust
  WHERE geom IS NOT NULL;

ANALYSE westcon.sa2_2011_aust_web;

-- SA3
DROP TABLE IF EXISTS westcon.sa3_2011_aust_web;
CREATE TABLE westcon.sa3_2011_aust_web
(
  gid serial NOT NULL,
  sa3_code character varying(9) NOT NULL,
  sa3_name character varying(50) NOT NULL,
  state_code character varying(1) NOT NULL,
  state_name character varying(50) NOT NULL,
  area_sqkm numeric NOT NULL,
  geom geometry(MultiPolygon,4326,2) NOT NULL,
  CONSTRAINT sa3_2011_aust_web_pkey PRIMARY KEY (gid)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.sa3_2011_aust_web OWNER TO postgres;

CREATE INDEX sa3_2011_aust_web_geom_idx ON westcon.sa3_2011_aust_web USING gist (geom);
CLUSTER westcon.sa3_2011_aust_web USING sa3_2011_aust_web_geom_idx;

INSERT INTO westcon.sa3_2011_aust_web (sa3_code, sa3_name, state_code, state_name, area_sqkm, geom)
SELECT sa3_code, sa3_name, state_code, state_name, area_sqkm,
       ST_Transform(ST_Multi(ST_Buffer(ST_SnapToGrid(ST_Buffer(geom, 0.0),0.0001), 0.0)), 4326) AS geom 
  FROM westcon.sa3_2011_aust
  WHERE geom IS NOT NULL;

ANALYSE westcon.sa3_2011_aust_web;

-- SA4
DROP TABLE IF EXISTS westcon.sa4_2011_aust_web;
CREATE TABLE westcon.sa4_2011_aust_web
(
  gid serial NOT NULL,
  sa4_code character varying(9) NOT NULL,
  sa4_name character varying(50) NOT NULL,
  state_code character varying(1) NOT NULL,
  state_name character varying(50) NOT NULL,
  area_sqkm numeric NOT NULL,
  geom geometry(MultiPolygon,4326,2) NOT NULL,
  CONSTRAINT sa4_2011_aust_web_pkey PRIMARY KEY (gid)
)
WITH (OIDS=FALSE);
ALTER TABLE westcon.sa4_2011_aust_web OWNER TO postgres;

CREATE INDEX sa4_2011_aust_web_geom_idx ON westcon.sa4_2011_aust_web USING gist (geom);
CLUSTER westcon.sa4_2011_aust_web USING sa4_2011_aust_web_geom_idx;

INSERT INTO westcon.sa4_2011_aust_web (sa4_code, sa4_name, state_code, state_name, area_sqkm, geom)
SELECT sa4_code, sa4_name, state_code, state_name, area_sqkm,
       ST_Transform(ST_Multi(ST_Buffer(ST_SnapToGrid(ST_Buffer(geom, 0.0),0.0001), 0.0)), 4326) AS geom 
  FROM westcon.sa4_2011_aust
  WHERE geom IS NOT NULL;

ANALYSE westcon.sa4_2011_aust_web;


