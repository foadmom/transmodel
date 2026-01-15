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
--drop schema if exists naptan cascade;
--drop schema if exists tracking cascade;

CREATE SCHEMA network;

ALTER ROLE postgres IN DATABASE transmodel SET search_path TO network;

-- =========================================================
-- ENUM Types
-- =========================================================
CREATE TYPE TRANSPORT_MODE AS ENUM ('BUS','COACH','TRAIN');
CREATE TYPE STOP_TYPE AS ENUM ('STATION','TERMINAL','STOP');
CREATE TYPE ROUTE_DIRECTION AS ENUM ('OUTBOUND','INBOUND');
CREATE TYPE COMPASS_DIRECTION AS ENUM ('N','NE','E','SE','S','SW','W','NW');
CREATE TYPE exception_type AS ENUM ('ADDED','REMOVED');
CREATE TYPE realtime_status AS ENUM ('ON_TIME','DELAYED','CANCELLED','SKIPPED');
CREATE TYPE journey_status AS ENUM ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED');

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================

-- =========================================================
-- =========================================================
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
    country_code CHAR(2) NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_operator_network_operator_code ON network.operator_network (operator_code);
CREATE INDEX idx_operator_network_trans_mode    ON network.operator_network (trans_mode);
CREATE INDEX idx_operator_network_country_code  ON network.operator_network (country_code);
CREATE INDEX idx_operator_network_network_code  ON network.operator_network (network_code);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Lines, Routes & Infrastructure
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
-- =========================================================
CREATE TABLE network.route (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT REFERENCES network.line(id),
--    route_direction ROUTE_DIRECTION NOT NULL,
    compass_direction COMPASS_DIRECTION,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_route_line_id ON network.route (line_id);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.route_link (
    id BIGSERIAL PRIMARY KEY,
    route_id        BIGINT REFERENCES network.route(id),
    from_stop_id    BIGINT REFERENCES network.stop(id),
    to_stop_id      BIGINT REFERENCES network.stop(id),
    distance_meters INTEGER,
    sequence_order  INTEGER NOT NULL,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_routelink_route_seq ON network.route_link (route_id, sequence_order);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.journey_pattern (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT REFERENCES network.route(id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_journey_pattern_route_id ON network.journey_pattern (route_id);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.journey_pattern_stop (
    id BIGSERIAL PRIMARY KEY,
    journey_pattern_id BIGINT REFERENCES network.journey_pattern(id),
    stop_point_id BIGINT REFERENCES network.stop_point(id),
    sequence_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);
CREATE INDEX idx_jp_stop_seq ON network.journey_pattern_stop (journey_pattern_id, sequence_order);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.service_journey (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT REFERENCES network.line(id),
    journey_pattern_id BIGINT REFERENCES network.journey_pattern(id),
    planned_departure_time TIME NOT NULL,
    planned_arrival_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by TEXT DEFAULT CURRENT_USER
);

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
-- NaPTAN reference data
-- =========================================================
CREATE SCHEMA naptan;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO naptan;
CREATE TABLE naptan.stops (
	atcocode varchar NULL,
	NaptanCode varchar NULL,
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
--routes	line
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
--Route	route
--RouteLink	route_link
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



