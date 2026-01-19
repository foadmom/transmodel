-- sudo apt install postgresql-18 postgresql-client-18 postgis -y
-- sudo -u postgres psql -U postgres -f ./trans_postgres.sql 
-- ===============================================================================
--\c postgres;
DROP DATABASE IF EXISTS transmodel WITH (FORCE);

CREATE DATABASE transmodel OWNER postgres;
\c transmodel

-- DROP SCHEMA IF EXISTS public;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

--drop schema if exists network cascade;
--drop schema if exists tracking cascade;

CREATE SCHEMA network;

ALTER ROLE postgres IN DATABASE transmodel SET search_path TO network;

-- =========================================================
-- ENUM Types
-- =========================================================
CREATE TYPE TRANSPORT_MODE AS ENUM ('BUS','COACH','TRAIN');
CREATE TYPE STOP_TYPE AS ENUM ('STATION','TERMINAL','STOP');
CREATE TYPE SERVICE_DIRECTION AS ENUM ('OUTBOUND','INBOUND');
CREATE TYPE COMPASS_DIRECTION AS ENUM ('N','NE','E','SE','S','SW','W','NW');
CREATE TYPE exception_type AS ENUM ('ADDED','REMOVED');
CREATE TYPE realtime_status AS ENUM ('ON_TIME','DELAYED','CANCELLED','SKIPPED');
CREATE TYPE journey_status AS ENUM ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED');

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Assumptions:
--   - There concept of outbound is attached to the first leg
--       of a journey and nothing to do the starting position.
--       In some designs, everything out of Paris is OUTBOUND,
--       any journey into Paris is INBOUND
--       This is not true of this design
--   - 
-- =========================================================
-- =========================================================

-- =========================================================
-- zone can be an area, city, town, state, county or .....
-- In it's simplest form it would be big towns and cities, 
--   eg London, Madrid
-- =========================================================
CREATE TABLE network.zone (
    id BIGSERIAL PRIMARY KEY,
    code TEXT,		-- not sure who would set this
    name TEXT NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_zone_code ON network.zone (code);
CREATE INDEX idx_zone_name ON network.zone (name);


-- =========================================================
-- Stops (Transmodel compliant)
-- the Geo position is in stop rather than stop-point.
--   this means we do not get pin point accuracy of different
--   eg platforms within a large stop like Victoria station
-- =========================================================
CREATE TABLE network.stop (
    id BIGSERIAL PRIMARY KEY,
    stop_code TEXT NOT NULL,
    name TEXT,
    type STOP_TYPE NOT NULL,
    zone_id BIGINT NOT null , 
    post_code TEXT,
    geo_position GEOGRAPHY (POINT, 4326) NOT NULL,
    additional_info TEXT,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_stop_stop_code ON network.stop (stop_code);
CREATE INDEX idx_stop_post_code ON network.stop (post_code);
CREATE INDEX idx_stop_zone_id ON network.stop (zone_id);
CREATE INDEX idx_stop_geo_position ON network.stop USING GIST (geo_position);
CREATE INDEX idx_stop_name ON network.stop (name);

-- =========================================================
-- I assume this applies to eg which platform/bay the stop is
-- planned for.
-- =========================================================
CREATE TABLE network.stop_point (
    id BIGSERIAL PRIMARY KEY,
    platform TEXT,
    direction COMPASS_DIRECTION, -- like North-East corner of Victoria station
    additional_info TEXT,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

-- =========================================================
-- created when a service is scheduled. needs to be linked
-- to a particular service/flight instance
-- I think we need both stop_id and stop_point_id because 
-- stop_point should be optional for a stop
-- =========================================================
CREATE TABLE network.scheduled_stop (
    id                 BIGSERIAL PRIMARY KEY,
    stop_id            BIGINT    NOT NULL REFERENCES network.stop(id), 
    stop_point_id      BIGINT             REFERENCES network.stop_point(id),
    flight_instance_id BIGINT    NOT NULL REFERENCES network.flight_instance (id),
    sequence_order     INTEGER   NOT NULL,
    scheduled_time     TIMESTAMP NOT NULL,
    actual_time        TIMESTAMP,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT      DEFAULT CURRENT_USER
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.facility (
    id BIGSERIAL PRIMARY KEY,
	code TEXT UNIQUE NOT NULL,
	name TEXT NOT NULL,
	additional_info TEXT,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
    
-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.stop_facilities (
    id BIGSERIAL PRIMARY KEY,
    stop_id BIGINT REFERENCES network.stop(id),
    stop_facility_id BIGINT REFERENCES network.stop_facility (id),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
    

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Operator & Network
-- =========================================================
-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.operator (
    id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL, 
    name TEXT,                   -- long name or company name
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_operator_code ON network.operator (code);
CREATE INDEX idx_operator_name ON network.operator (name);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.network (
    id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_network_code ON network.network (code);
CREATE INDEX idx_network_name ON network.network (name);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.operator_network (
    id BIGSERIAL PRIMARY KEY,
	operator_code TEXT REFERENCES network.operator (code),
	network_code  TEXT REFERENCES network.network (code),
    trans_mode TRANSPORT_MODE NOT NULL,
    country_id BIGINT  NOT NULL REFERENCES reference.country (id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_operator_network_operator_code ON network.operator_network (operator_code);
CREATE INDEX idx_operator_network_trans_mode    ON network.operator_network (trans_mode);
CREATE INDEX idx_operator_network_country_id  ON network.operator_network (country_id);
CREATE INDEX idx_operator_network_network_code  ON network.operator_network (network_code);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Lines, services & Infrastructure
-- =========================================================
-- ?????? not sure how this is used
-- 
-- I am assuming a Line is like Birmingham to London which
--   may have different routes, services with a single 
--   mode and operator
-- =========================================================
CREATE TABLE network.line (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    public_code TEXT,
    trans_mode  TRANSPORT_MODE NOT NULL,
    operator_id BIGINT  NOT NULL REFERENCES network.operator(id),
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_line_name        ON network.line (name);
CREATE INDEX idx_line_public_code ON network.line (public_code);
CREATE INDEX idx_line_trans_mode  ON network.line (trans_mode);
CREATE INDEX idx_line_operator_id ON network.line (operator_id);

-- =========================================================
-- This is equivalent of a Service or Flight.
-- eg:
--    flight RK 3226 
--    line, Manchester to Sandefjord, Norway ??
--    operated by RyanAir
--    compass_direction, NE
-- The Service is the end to end dfinition, of one service in a line,
-- eg Bristol to London. The service here is for a single 
--    direction and return service would be a differenc service_code
-- not sure what value 'line' adds.
-- =========================================================
CREATE TABLE network.service (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT REFERENCES network.line(id),
    code TEXT UNIQUE NOT NULL,		-- eg FLX-241
--    service_direction SERVICE_DIRECTION NOT NULL,
    compass_direction COMPASS_DIRECTION,
    from_stop_id    BIGINT REFERENCES network.stop(id),
    to_stop_id      BIGINT REFERENCES network.stop(id),
    distance_meters INTEGER,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_service_line_id ON network.service (line_id);
CREATE INDEX idx_service_code ON network.service (code);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.service_link (
    id BIGSERIAL PRIMARY KEY,
    service_id      BIGINT REFERENCES network.service(id),
    from_stop_id    BIGINT REFERENCES network.stop(id),
    to_stop_id      BIGINT REFERENCES network.stop(id),
    distance_meters INTEGER,
    sequence_order  INTEGER NOT NULL,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_servicelink_service_seq ON network.service_link (service_id, sequence_order);

-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.journey_pattern (
--    id BIGSERIAL PRIMARY KEY,
--    service_id BIGINT REFERENCES network.service(id),
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by TEXT DEFAULT CURRENT_USER
--);
--CREATE INDEX idx_journey_pattern_service_id ON network.journey_pattern (service_id);

-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.journey_pattern_stop (
--    id BIGSERIAL PRIMARY KEY,
--    journey_pattern_id BIGINT REFERENCES network.journey_pattern(id),
--    stop_point_id BIGINT REFERENCES network.stop_point(id),
--    sequence_order INTEGER NOT NULL,
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by TEXT DEFAULT CURRENT_USER
--);
--CREATE INDEX idx_jp_stop_seq ON network.journey_pattern_stop (journey_pattern_id, sequence_order);

-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.service_journey (
--    id BIGSERIAL PRIMARY KEY,
--    line_id BIGINT REFERENCES network.line(id),
--    journey_pattern_id BIGINT REFERENCES network.journey_pattern(id),
--    planned_departure_time TIME NOT NULL,
--    planned_arrival_time TIME NOT NULL,
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by TEXT DEFAULT CURRENT_USER
--);

-- =========================================================
-- Calendar & Exceptions
-- =========================================================

CREATE TABLE network.service_calendar (
    id BIGSERIAL PRIMARY KEY,
    start_date DATE,
    end_date DATE,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.service_journey_calendar (
    service_journey_id BIGINT REFERENCES network.service_journey(id),
    service_calendar_id BIGINT REFERENCES network.service_calendar(id),
    PRIMARY KEY (service_journey_id, service_calendar_id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.service_exception (
    id BIGSERIAL PRIMARY KEY,
    service_calendar_id BIGINT REFERENCES network.service_calendar(id),
    date DATE NOT NULL,
    type exception_type NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_calendar_range ON network.service_calendar USING GIST (daterange(start_date, end_date, '[]') );

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- reference data, not all are reference
-- =========================================================
CREATE SCHEMA reference;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO reference;
CREATE TABLE reference.stops (
	atcocode varchar NULL,
	referenceCode varchar NULL,
	PlateCode varchar NULL,
	CleardownCode varchar NULL,
	CommonName varchar NULL,
	CommonNameLang varchar NULL,
	ShortCommonName varchar NULL,
	ShortCommonNameLang varchar NULL,
	Landmark varchar NULL,
	LandmarkLang varchar,
	Street varchar,
	StreetLang varchar,
	Crossing varchar,
	CrossingLang varchar,
	Indicator varchar,
	IndicatorLang varchar,
	Bearing varchar,
	NptgLocalityCode varchar,
	LocalityName varchar,
	ParentLocalityName varchar,
	GrandParentLocalityName varchar,
	Town varchar,
	TownLang varchar,
	Suburb varchar,
	SuburbLang varchar,
	LocalityCentre Boolean,
	GridType varchar,
	Easting int,
	Northing int,
	Longitude float8,
	Latitude float8,
	StopType varchar,
	BusStopType varchar,
	TimingStatus varchar,
	DefaultWaitTime varchar,
	Notes varchar,
	NotesLang varchar,
	AdministrativeAreaCode int,
	CreationDateTime TIMESTAMP,
	ModificationDateTime TIMESTAMP,
	RevisionNumber int,
	Modification varchar,
	Status varchar
);

DROP TABLE reference.uk_cities;
CREATE TABLE reference.uk_cities (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    latitude FLOAT,
    longitude FLOAT,
    country_id BIGINT NOT NULL REFERENCES reference.country (id),
    iso2 TEXT NOT NULL,
    zone TEXT,
    capital TEXT,  -- not needed
    population int,
    population_proper int,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
--COPY reference.uk_cities(name,latitude, longitude, country, iso2,zone,capital,population, population_proper) 
--FROM '/home/postgres/UK_cities.csv'
--DELIMITER ','
--CSV HEADER;

DROP TABLE reference.country;
CREATE TABLE reference.country (
    id BIGSERIAL PRIMARY KEY,
    iso2 TEXT NOT NULL,
    latitude float8 NOT null ,
    longitude float8 NOT NULL,
    name TEXT NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
--COPY reference.country(iso2, latitude, longitude, name) 
--FROM '/home/postgres/countries.csv'
--DELIMITER ','
--CSV HEADER;


INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('AD',42.546245,1.601554,'Andorra','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AE',23.424076,53.847818,'United Arab Emirates','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AF',33.93911,67.709953,'Afghanistan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AG',17.060816,-61.796428,'Antigua and Barbuda','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AI',18.220554,-63.068615,'Anguilla','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AL',41.153332,20.168331,'Albania','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AM',40.069099,45.038189,'Armenia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AN',12.226079,-69.060087,'Netherlands Antilles','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AO',-11.202692,17.873887,'Angola','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AQ',-75.250973,-0.071389,'Antarctica','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('AR',-38.416097,-63.616672,'Argentina','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AS',-14.270972,-170.132217,'American Samoa','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AT',47.516231,14.550072,'Austria','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AU',-25.274398,133.775136,'Australia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AW',12.52111,-69.968338,'Aruba','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('AZ',40.143105,47.576927,'Azerbaijan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BA',43.915886,17.679076,'Bosnia and Herzegovina','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BB',13.193887,-59.543198,'Barbados','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BD',23.684994,90.356331,'Bangladesh','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BE',50.503887,4.469936,'Belgium','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('BF',12.238333,-1.561593,'Burkina Faso','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BG',42.733883,25.48583,'Bulgaria','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BH',25.930414,50.637772,'Bahrain','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BI',-3.373056,29.918886,'Burundi','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BJ',9.30769,2.315834,'Benin','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BM',32.321384,-64.75737,'Bermuda','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BN',4.535277,114.727669,'Brunei','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BO',-16.290154,-63.588653,'Bolivia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BR',-14.235004,-51.92528,'Brazil','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BS',25.03428,-77.39628,'Bahamas','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('BT',27.514162,90.433601,'Bhutan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BV',-54.423199,3.413194,'Bouvet Island','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BW',-22.328474,24.684866,'Botswana','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BY',53.709807,27.953389,'Belarus','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('BZ',17.189877,-88.49765,'Belize','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CA',56.130366,-106.346771,'Canada','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CC',-12.164165,96.870956,'Cocos [Keeling] Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CD',-4.038333,21.758664,'Congo [DRC]','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CF',6.611111,20.939444,'Central African Republic','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CG',-0.228021,15.827659,'Congo [Republic]','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('CH',46.818188,8.227512,'Switzerland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CI',7.539989,-5.54708,'Côte d''Ivoire','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CK',-21.236736,-159.777671,'Cook Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CL',-35.675147,-71.542969,'Chile','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CM',7.369722,12.354722,'Cameroon','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CN',35.86166,104.195397,'China','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CO',4.570868,-74.297333,'Colombia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CR',9.748917,-83.753428,'Costa Rica','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CU',21.521757,-77.781167,'Cuba','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CV',16.002082,-24.013197,'Cape Verde','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('CX',-10.447525,105.690449,'Christmas Island','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CY',35.126413,33.429859,'Cyprus','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('CZ',49.817492,15.472962,'Czech Republic','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DE',51.165691,10.451526,'Germany','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DJ',11.825138,42.590275,'Djibouti','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DK',56.26392,9.501785,'Denmark','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DM',15.414999,-61.370976,'Dominica','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DO',18.735693,-70.162651,'Dominican Republic','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('DZ',28.033886,1.659626,'Algeria','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('EC',-1.831239,-78.183406,'Ecuador','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('EE',58.595272,25.013607,'Estonia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('EG',26.820553,30.802498,'Egypt','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('EH',24.215527,-12.885834,'Western Sahara','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ER',15.179384,39.782334,'Eritrea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ES',40.463667,-3.74922,'Spain','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ET',9.145,40.489673,'Ethiopia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('FI',61.92411,25.748151,'Finland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('FJ',-16.578193,179.414413,'Fiji','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('FK',-51.796253,-59.523613,'Falkland Islands [Islas Malvinas]','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('FM',7.425554,150.550812,'Micronesia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('FO',61.892635,-6.911806,'Faroe Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('FR',46.227638,2.213749,'France','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GA',-0.803689,11.609444,'Gabon','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GB',55.378051,-3.435973,'United Kingdom','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GD',12.262776,-61.604171,'Grenada','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GE',42.315407,43.356892,'Georgia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GF',3.933889,-53.125782,'French Guiana','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GG',49.465691,-2.585278,'Guernsey','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GH',7.946527,-1.023194,'Ghana','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GI',36.137741,-5.345374,'Gibraltar','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('GL',71.706936,-42.604303,'Greenland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GM',13.443182,-15.310139,'Gambia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GN',9.945587,-9.696645,'Guinea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GP',16.995971,-62.067641,'Guadeloupe','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GQ',1.650801,10.267895,'Equatorial Guinea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GR',39.074208,21.824312,'Greece','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GS',-54.429579,-36.587909,'South Georgia and the South Sandwich Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GT',15.783471,-90.230759,'Guatemala','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GU',13.444304,144.793731,'Guam','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GW',11.803749,-15.180413,'Guinea-Bissau','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('GY',4.860416,-58.93018,'Guyana','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('GZ',31.354676,34.308825,'Gaza Strip','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HK',22.396428,114.109497,'Hong Kong','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HM',-53.08181,73.504158,'Heard Island and McDonald Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HN',15.199999,-86.241905,'Honduras','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HR',45.1,15.2,'Croatia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HT',18.971187,-72.285215,'Haiti','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('HU',47.162494,19.503304,'Hungary','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ID',-0.789275,113.921327,'Indonesia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IE',53.41291,-8.24389,'Ireland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('IL',31.046051,34.851612,'Israel','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IM',54.236107,-4.548056,'Isle of Man','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IN',20.593684,78.96288,'India','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IO',-6.343194,71.876519,'British Indian Ocean Territory','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IQ',33.223191,43.679291,'Iraq','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IR',32.427908,53.688046,'Iran','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IS',64.963051,-19.020835,'Iceland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('IT',41.87194,12.56738,'Italy','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('JE',49.214439,-2.13125,'Jersey','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('JM',18.109581,-77.297508,'Jamaica','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('JO',30.585164,36.238414,'Jordan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('JP',36.204824,138.252924,'Japan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KE',-0.023559,37.906193,'Kenya','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KG',41.20438,74.766098,'Kyrgyzstan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KH',12.565679,104.990963,'Cambodia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KI',-3.370417,-168.734039,'Kiribati','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KM',-11.875001,43.872219,'Comoros','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KN',17.357822,-62.782998,'Saint Kitts and Nevis','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KP',40.339852,127.510093,'North Korea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KR',35.907757,127.766922,'South Korea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('KW',29.31166,47.481766,'Kuwait','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KY',19.513469,-80.566956,'Cayman Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('KZ',48.019573,66.923684,'Kazakhstan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LA',19.85627,102.495496,'Laos','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LB',33.854721,35.862285,'Lebanon','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LC',13.909444,-60.978893,'Saint Lucia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LI',47.166,9.555373,'Liechtenstein','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LK',7.873054,80.771797,'Sri Lanka','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LR',6.428055,-9.429499,'Liberia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LS',-29.609988,28.233608,'Lesotho','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('LT',55.169438,23.881275,'Lithuania','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LU',49.815273,6.129583,'Luxembourg','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LV',56.879635,24.603189,'Latvia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('LY',26.3351,17.228331,'Libya','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MA',31.791702,-7.09262,'Morocco','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MC',43.750298,7.412841,'Monaco','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MD',47.411631,28.369885,'Moldova','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ME',42.708678,19.37439,'Montenegro','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MG',-18.766947,46.869107,'Madagascar','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MH',7.131474,171.184478,'Marshall Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('MK',41.608635,21.745275,'Macedonia [FYROM]','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ML',17.570692,-3.996166,'Mali','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MM',21.913965,95.956223,'Myanmar [Burma]','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MN',46.862496,103.846656,'Mongolia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MO',22.198745,113.543873,'Macau','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MP',17.33083,145.38469,'Northern Mariana Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MQ',14.641528,-61.024174,'Martinique','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MR',21.00789,-10.940835,'Mauritania','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MS',16.742498,-62.187366,'Montserrat','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MT',35.937496,14.375416,'Malta','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('MU',-20.348404,57.552152,'Mauritius','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MV',3.202778,73.22068,'Maldives','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MW',-13.254308,34.301525,'Malawi','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MX',23.634501,-102.552784,'Mexico','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MY',4.210484,101.975766,'Malaysia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('MZ',-18.665695,35.529562,'Mozambique','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NA',-22.95764,18.49041,'Namibia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NC',-20.904305,165.618042,'New Caledonia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NE',17.607789,8.081666,'Niger','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NF',-29.040835,167.954712,'Norfolk Island','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('NG',9.081999,8.675277,'Nigeria','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NI',12.865416,-85.207229,'Nicaragua','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NL',52.132633,5.291266,'Netherlands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NO',60.472024,8.468946,'Norway','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NP',28.394857,84.124008,'Nepal','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NR',-0.522778,166.931503,'Nauru','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NU',-19.054445,-169.867233,'Niue','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('NZ',-40.900557,174.885971,'New Zealand','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('OM',21.512583,55.923255,'Oman','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PA',8.537981,-80.782127,'Panama','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('PE',-9.189967,-75.015152,'Peru','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PF',-17.679742,-149.406843,'French Polynesia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PG',-6.314993,143.95555,'Papua New Guinea','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PH',12.879721,121.774017,'Philippines','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PK',30.375321,69.345116,'Pakistan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PL',51.919438,19.145136,'Poland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PM',46.941936,-56.27111,'Saint Pierre and Miquelon','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PN',-24.703615,-127.439308,'Pitcairn Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PR',18.220833,-66.590149,'Puerto Rico','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PS',31.952162,35.233154,'Palestinian Territories','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('PT',39.399872,-8.224454,'Portugal','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PW',7.51498,134.58252,'Palau','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('PY',-23.442503,-58.443832,'Paraguay','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('QA',25.354826,51.183884,'Qatar','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('RE',-21.115141,55.536384,'Réunion','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('RO',45.943161,24.96676,'Romania','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('RS',44.016521,21.005859,'Serbia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('RU',61.52401,105.318756,'Russia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('RW',-1.940278,29.873888,'Rwanda','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SA',23.885942,45.079162,'Saudi Arabia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('SB',-9.64571,160.156194,'Solomon Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SC',-4.679574,55.491977,'Seychelles','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SD',12.862807,30.217636,'Sudan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SE',60.128161,18.643501,'Sweden','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SG',1.352083,103.819836,'Singapore','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SH',-24.143474,-10.030696,'Saint Helena','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SI',46.151241,14.995463,'Slovenia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SJ',77.553604,23.670272,'Svalbard and Jan Mayen','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SK',48.669026,19.699024,'Slovakia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SL',8.460555,-11.779889,'Sierra Leone','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('SM',43.94236,12.457777,'San Marino','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SN',14.497401,-14.452362,'Senegal','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SO',5.152149,46.199616,'Somalia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SR',3.919305,-56.027783,'Suriname','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ST',0.18636,6.613081,'São Tomé and Príncipe','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SV',13.794185,-88.89653,'El Salvador','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SY',34.802075,38.996815,'Syria','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('SZ',-26.522503,31.465866,'Swaziland','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TC',21.694025,-71.797928,'Turks and Caicos Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TD',15.454166,18.732207,'Chad','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('TF',-49.280366,69.348557,'French Southern Territories','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TG',8.619543,0.824782,'Togo','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TH',15.870032,100.992541,'Thailand','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TJ',38.861034,71.276093,'Tajikistan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TK',-8.967363,-171.855881,'Tokelau','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TL',-8.874217,125.727539,'Timor-Leste','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TM',38.969719,59.556278,'Turkmenistan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TN',33.886917,9.537499,'Tunisia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TO',-21.178986,-175.198242,'Tonga','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TR',38.963745,35.243322,'Turkey','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('TT',10.691803,-61.222503,'Trinidad and Tobago','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TV',-7.109535,177.64933,'Tuvalu','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TW',23.69781,120.960515,'Taiwan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('TZ',-6.369028,34.888822,'Tanzania','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('UA',48.379433,31.16558,'Ukraine','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('UG',1.373333,32.290275,'Uganda','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('US',37.09024,-95.712891,'United States','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('UY',-32.522779,-55.765835,'Uruguay','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('UZ',41.377491,64.585262,'Uzbekistan','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VA',41.902916,12.453389,'Vatican City','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('VC',12.984305,-61.287228,'Saint Vincent and the Grenadines','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VE',6.42375,-66.58973,'Venezuela','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VG',18.420695,-64.639968,'British Virgin Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VI',18.335765,-64.896335,'U.S. Virgin Islands','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VN',14.058324,108.277199,'Vietnam','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('VU',-15.376706,166.959158,'Vanuatu','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('WF',-13.768752,-177.156097,'Wallis and Futuna','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('WS',-13.759029,-172.104629,'Samoa','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('XK',42.602636,20.902977,'Kosovo','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('YE',15.552727,48.516388,'Yemen','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');
INSERT INTO reference.country (iso2,latitude,longitude,"name",created_at,updated_at,updated_by) VALUES
	 ('YT',-12.8275,45.166244,'Mayotte','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ZA',-30.559482,22.937506,'South Africa','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ZM',-13.133897,27.849332,'Zambia','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres'),
	 ('ZW',-19.015438,29.154857,'Zimbabwe','2026-01-19 12:11:48.641194','2026-01-19 12:11:48.641194','postgres');

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Real-Time Data (Optimized)
-- =========================================================

CREATE SCHEMA tracking;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO tracking;

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.vehicle (
    id BIGSERIAL PRIMARY KEY,
    operator_id BIGINT REFERENCES network.operator(id),
    vehicle_type TEXT,
    capacity INTEGER,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.vehicle_journey_assignment (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES tracking.vehicle(id),
    service_journey_id BIGINT REFERENCES network.service_journey(id),
    assigned_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.vehicle_position (
    vehicle_id BIGINT REFERENCES tracking.vehicle(id),
    recorded_at TIMESTAMP NOT NULL,
    geo_position  GEOGRAPHY (POINT, 4326),
    speed REAL,
    bearing REAL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER,
    PRIMARY KEY (vehicle_id, recorded_at)
) PARTITION BY RANGE (recorded_at);
-- Recommended: daily partitions + retention policy.
CREATE INDEX idx_vehicle_position_geo_position ON tracking.vehicle_position USING GIST (geo_position);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.realtime_stop_update (
    id BIGSERIAL PRIMARY KEY,
    service_journey_id BIGINT REFERENCES network.service_journey(id),
    stop_point_id BIGINT REFERENCES network.stop_point(id),
    delay_seconds INTEGER,
    predicted_arrival_time TIME,
    predicted_departure_time TIME,
    status realtime_status,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_rt_update_lookup ON tracking.realtime_stop_update (service_journey_id, stop_point_id);
CREATE INDEX idx_rt_update_recent ON tracking.realtime_stop_update (service_journey_id, updated_at DESC);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.service_journey_status (
    service_journey_id BIGINT PRIMARY KEY REFERENCES network.service_journey(id),
    status journey_status,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

 
-- =========================================================
-- =========================================================

-- Mapping to GTFS & NeTEx
--GTFS Mapping
--GTFS Table	This Schema
--agency	operator
--stops	stop_place
--stop_times	stop_time
--services	line
--trips	service_journey
--calendar	service_calendar
--calendar_dates	service_exception
--vehicle_positions (RT)	vehicle_position
--trip_updates (RT)	realtime_stop_update
--
--NeTEx Mapping
--NeTEx Concept	Table
--StopPlace	stop_place
--ScheduledStopPoint	stop_point
--Line	line
--service	service
--serviceLink	service_link
--JourneyPattern	journey_pattern
--ServiceJourney	service_journey
--TimetabledPassingTime	stop_time
--DayType / OperatingPeriod	service_calendar
--
---- =========================================================
--Query Cookbook (Journey Search)
--A. Departures from a Stop (with real-time)
--sql
--Copy code
--SELECT
--    sj.id AS journey_id,
--    l.name AS line,
--    st.departure_time,
--    COALESCE(rtu.predicted_departure_time, st.departure_time) AS expected_departure,
--    rtu.delay_seconds
--FROM stop_time st
--JOIN service_journey sj ON sj.id = st.service_journey_id
--JOIN line l ON l.id = sj.line_id
--LEFT JOIN realtime_stop_update rtu
--    ON rtu.service_journey_id = sj.id
-- AND rtu.stop_point_id = st.stop_point_id
--WHERE st.stop_point_id = :stop_id
--    AND st.departure_time >= :from_time
--ORDER BY expected_departure
--LIMIT 20;
--B. Direct Journey A → B (No Transfers)
--sql
--Copy code
--SELECT sj.id
--FROM stop_time a
--JOIN stop_time b
--    ON a.service_journey_id = b.service_journey_id
--JOIN service_journey sj ON sj.id = a.service_journey_id
--WHERE a.stop_point_id = :origin
--    AND b.stop_point_id = :destination
--    AND a.sequence_order < b.sequence_order
--    AND a.departure_time >= :time;
--C. One-Transfer Journey
--sql
--Copy code
--SELECT
--    sj1.id AS first_leg,
--    sj2.id AS second_leg
--FROM stop_time a
--JOIN stop_time x1 ON x1.service_journey_id = a.service_journey_id
--JOIN stop_time x2 ON x2.stop_point_id = x1.stop_point_id
--JOIN stop_time b ON b.service_journey_id = x2.service_journey_id
--JOIN service_journey sj1 ON sj1.id = a.service_journey_id
--JOIN service_journey sj2 ON sj2.id = b.service_journey_id
--WHERE a.stop_point_id = :origin
--    AND b.stop_point_id = :destination
--    AND a.sequence_order < x1.sequence_order
--    AND x2.sequence_order < b.sequence_order
--    AND x2.departure_time >= x1.arrival_time;
--D. Nearest Stops (PostGIS)
--sql
--Copy code
--SELECT id, name
--FROM stop_place
--ORDER BY geo_position <-> ST_MakePoint(:lon, :lat)::geography
--LIMIT 5;



