-- sudo apt install postgresql-18 postgresql-client-18 postgis -y
-- ===============================================================
DROP DATABASE IF EXISTS transmodel;

CREATE DATABASE transmodel OWNER postgres;
\c transmodel

-- DROP SCHEMA IF EXISTS public;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE SCHEMA network;

ALTER ROLE postgres IN DATABASE transmodel SET search_path TO network;



-- =========================================
-- ENUM Types
-- =========================================
CREATE TYPE transport_mode AS ENUM ('BUS','COACH','TRAIN');
CREATE TYPE stop_place_type AS ENUM ('STATION','TERMINAL','STOP');
CREATE TYPE route_direction AS ENUM ('OUTBOUND','INBOUND');
CREATE TYPE exception_type AS ENUM ('ADDED','REMOVED');
CREATE TYPE realtime_status AS ENUM ('ON_TIME','DELAYED','CANCELLED','SKIPPED');
CREATE TYPE journey_status AS ENUM ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED');

-- =========================================
-- Operator & Network
-- =========================================
CREATE TABLE operator (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    short_name TEXT,
    transport_mode transport_mode NOT NULL,
    country_code CHAR(2),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
--    
-- =========================================
CREATE TABLE network (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    operator_id BIGINT REFERENCES operator(id)
);

-- =========================================
-- Stops (Transmodel compliant)
-- =========================================
CREATE TABLE stop_place (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    type stop_place_type NOT NULL,
    timezone TEXT NOT NULL,
    geom GEOGRAPHY(Point, 4326) NOT NULL
);
CREATE INDEX idx_stopplace_geom ON stop_place USING GIST (geom);
CREATE INDEX idx_stopplace_name_trgm ON stop_place USING GIN (name gin_trgm_ops);

-- =========================================
-- 
-- =========================================
CREATE TABLE scheduled_stop_point (
    id BIGSERIAL PRIMARY KEY,
    stop_place_id BIGINT NOT NULL REFERENCES stop_place(id),
    code TEXT,
    platform TEXT
);

-- =========================================
-- Lines, Routes & Infrastructure
-- =========================================
CREATE TABLE line (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    public_code TEXT,
    transport_mode transport_mode NOT NULL,
    operator_id BIGINT REFERENCES operator(id)
);

-- =========================================
-- 
-- =========================================
CREATE TABLE route (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT REFERENCES line(id),
    direction route_direction NOT NULL
);

-- =========================================
-- 
-- =========================================
CREATE TABLE route_link (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT REFERENCES route(id),
    from_stop_point_id BIGINT REFERENCES scheduled_stop_point(id),
    to_stop_point_id BIGINT REFERENCES scheduled_stop_point(id),
    distance_meters INTEGER,
    sequence_order INTEGER NOT NULL
);

-- =========================================
-- 
-- =========================================
CREATE INDEX idx_routelink_route_seq ON route_link (route_id, sequence_order);

-- =========================================
-- 
-- =========================================
CREATE TABLE journey_pattern (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT REFERENCES route(id)
);

-- =========================================
-- 
-- =========================================
CREATE TABLE journey_pattern_stop (
    id BIGSERIAL PRIMARY KEY,
    journey_pattern_id BIGINT REFERENCES journey_pattern(id),
    scheduled_stop_point_id BIGINT REFERENCES scheduled_stop_point(id),
    sequence_order INTEGER NOT NULL
);
CREATE INDEX idx_jp_stop_seq ON journey_pattern_stop (journey_pattern_id, sequence_order);

-- =========================================
-- 
-- =========================================
CREATE TABLE service_journey (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT REFERENCES line(id),
    journey_pattern_id BIGINT REFERENCES journey_pattern(id),
    planned_departure_time TIME NOT NULL,
    planned_arrival_time TIME NOT NULL
);

-- =========================================
-- 
-- =========================================
CREATE TABLE stop_time (
    id BIGSERIAL PRIMARY KEY,
    service_journey_id BIGINT REFERENCES service_journey(id),
    scheduled_stop_point_id BIGINT REFERENCES scheduled_stop_point(id),
    arrival_time TIME,
    departure_time TIME,
    sequence_order INTEGER NOT NULL
);
CREATE INDEX idx_stoptime_journey_seq ON stop_time (service_journey_id, sequence_order);
CREATE INDEX idx_stoptime_stop_departure ON stop_time (scheduled_stop_point_id, departure_time);
CREATE INDEX idx_stoptime_stop_time ON stop_time (scheduled_stop_point_id, departure_time, service_journey_id);

-- =========================================
-- Calendar & Exceptions
-- =========================================

CREATE TABLE service_calendar (
    id BIGSERIAL PRIMARY KEY,
    start_date DATE,
    end_date DATE,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN
);

-- =========================================
-- 
-- =========================================
CREATE TABLE service_journey_calendar (
    service_journey_id BIGINT REFERENCES service_journey(id),
    service_calendar_id BIGINT REFERENCES service_calendar(id),
    PRIMARY KEY (service_journey_id, service_calendar_id)
);

-- =========================================
-- 
-- =========================================
CREATE TABLE service_exception (
    id BIGSERIAL PRIMARY KEY,
    service_calendar_id BIGINT REFERENCES service_calendar(id),
    date DATE NOT NULL,
    type exception_type NOT NULL
);
CREATE INDEX idx_calendar_range ON service_calendar USING GIST (daterange(start_date, end_date, '[]') );



-- =========================================
-- =========================================
-- =========================================
-- Real-Time Data (Optimized)
-- =========================================

CREATE SCHEMA tracking;

ALTER ROLE postgres IN DATABASE transmodel SET search_path TO tracking;

-- =========================================
-- 
-- =========================================
CREATE TABLE vehicle (
    id BIGSERIAL PRIMARY KEY,
    operator_id BIGINT REFERENCES operator(id),
    vehicle_type TEXT,
    capacity INTEGER
);

-- =========================================
-- 
-- =========================================
CREATE TABLE vehicle_journey_assignment (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES vehicle(id),
    service_journey_id BIGINT REFERENCES service_journey(id),
    assigned_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- 
-- =========================================
CREATE TABLE vehicle_position (
    vehicle_id BIGINT REFERENCES vehicle(id),
    recorded_at TIMESTAMPTZ NOT NULL,
    geom GEOGRAPHY(Point, 4326),
    speed REAL,
    bearing REAL,
    PRIMARY KEY (vehicle_id, recorded_at)
) PARTITION BY RANGE (recorded_at);
-- Recommended: daily partitions + retention policy.
CREATE INDEX idx_vehicle_position_geom
    ON vehicle_position USING GIST (geom);

-- =========================================
-- 
-- =========================================
CREATE TABLE realtime_stop_update (
    id BIGSERIAL PRIMARY KEY,
    service_journey_id BIGINT REFERENCES service_journey(id),
    scheduled_stop_point_id BIGINT REFERENCES scheduled_stop_point(id),
    delay_seconds INTEGER,
    predicted_arrival_time TIME,
    predicted_departure_time TIME,
    status realtime_status,
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_rt_update_lookup ON realtime_stop_update (service_journey_id, scheduled_stop_point_id);
CREATE INDEX idx_rt_update_recent ON realtime_stop_update (service_journey_id, updated_at DESC);

-- =========================================
-- 
--
CREATE TABLE service_journey_status (
    service_journey_id BIGINT PRIMARY KEY REFERENCES service_journey(id),
    status journey_status,
    last_updated TIMESTAMPTZ
);

-- =========================================
-- =========================================

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
--ScheduledStopPoint	scheduled_stop_point
--Line	line
--Route	route
--RouteLink	route_link
--JourneyPattern	journey_pattern
--ServiceJourney	service_journey
--TimetabledPassingTime	stop_time
--DayType / OperatingPeriod	service_calendar
--
---- =========================================
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
-- AND rtu.scheduled_stop_point_id = st.scheduled_stop_point_id
--WHERE st.scheduled_stop_point_id = :stop_id
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
--WHERE a.scheduled_stop_point_id = :origin
--    AND b.scheduled_stop_point_id = :destination
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
--JOIN stop_time x2 ON x2.scheduled_stop_point_id = x1.scheduled_stop_point_id
--JOIN stop_time b ON b.service_journey_id = x2.service_journey_id
--JOIN service_journey sj1 ON sj1.id = a.service_journey_id
--JOIN service_journey sj2 ON sj2.id = b.service_journey_id
--WHERE a.scheduled_stop_point_id = :origin
--    AND b.scheduled_stop_point_id = :destination
--    AND a.sequence_order < x1.sequence_order
--    AND x2.sequence_order < b.sequence_order
--    AND x2.departure_time >= x1.arrival_time;
--D. Nearest Stops (PostGIS)
--sql
--Copy code
--SELECT id, name
--FROM stop_place
--ORDER BY geom <-> ST_MakePoint(:lon, :lat)::geography
--LIMIT 5;

