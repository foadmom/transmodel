-- sudo apt install postgresql-18 postgresql-client-18 postgis -y
-- sudo -u postgres psql -U postgres -f ./trans_postgres.sql 
-- ===============================================================================
\c postgres;
DROP DATABASE IF EXISTS transmodel WITH (FORCE);
--
CREATE DATABASE transmodel OWNER postgres;

\c transmodel;
DROP SCHEMA public;
CREATE SCHEMA IF NOT EXISTS common;
CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS network;
CREATE SCHEMA IF NOT EXISTS operation;
CREATE SCHEMA IF NOT EXISTS tracking;

--grant create on schema common to postgres;
--SHOW search_path;
SET search_path TO common;

CREATE TYPE TRANSPORT_MODE AS ENUM ('BUS','COACH','TRAIN');
CREATE TYPE STOP_TYPE AS ENUM ('STATION','TERMINAL','STOP');
CREATE TYPE SERVICE_DIRECTION AS ENUM ('OUTBOUND','INBOUND');
CREATE TYPE COMPASS_DIRECTION AS ENUM ('N','NE','E','SE','S','SW','W','NW');
CREATE TYPE EXCEPTION_TYPE AS ENUM ('ADDED','REMOVED');
CREATE TYPE REALTIME_STATUS AS ENUM ('ON_TIME','DELAYED','CANCELLED','SKIPPED');
CREATE TYPE JOURNEY_STATUS AS ENUM ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED');
CREATE TYPE FUEL_TYPE AS ENUM ('PETROL', 'DIESEL', 'GAS', 'ELECTRIC');


CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =========================================================
-- ENUM Types
-- =========================================================


-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
--

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;



-- =========================================================
-- =========================================================
-- reference data, not all are reference
-- =========================================================
---- DROP TABLE IF EXISTS reference.stop;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO reference;
CREATE TABLE reference.stop (
    id                     BIGSERIAL PRIMARY KEY,
    atcocode               VARCHAR (16) NULL,
    referenceCode          VARCHAR (16) NULL,
    PlateCode              VARCHAR (16) NULL,
    CleardownCode          VARCHAR (16) NULL,
    CommonName             VARCHAR (64) NULL,
    CommonNameLang         CHAR    (2) NULL,
    ShortCommonName        VARCHAR (64) NULL,
    ShortCommonNameLang    CHAR    (2) NULL,
    Landmark               VARCHAR (64) NULL,
    LandmarkLang           CHAR    (2),
    Street                 VARCHAR (64),
    StreetLang             CHAR    (2),
    Crossing               VARCHAR (64),
    CrossingLang           CHAR    (2),
    Indicator              VARCHAR (64),
    IndicatorLang          CHAR    (2),
    Bearing                CHAR    (2),
    NptgLocalityCode       VARCHAR (16),
    LocalityName           VARCHAR (64),
    ParentLocalityName     VARCHAR (64),
    GrandParentLocalityName VARCHAR (64),
    Town                   VARCHAR (64),
    TownLang               CHAR    (2),
    Suburb                 VARCHAR (64),
    SuburbLang             CHAR    (2),
    LocalityCentre         Boolean,
    GridType               VARCHAR (8),
    Easting                INT,
    Northing               INT,
    Longitude              FLOAT8,
    Latitude               FLOAT8,
    StopType               VARCHAR (8),
    BusStopType            VARCHAR (8),
    TimingStatus           VARCHAR (16),
    DefaultWaitTime        int,  -- in minutes
    Notes                  VARCHAR (128),
    NotesLang              CHAR    (2),
    AdministrativeAreaCode INT,
    CreationDateTime       TIMESTAMP,
    ModificationDateTime   TIMESTAMP,
    RevisionNumber         INT,
    Modification           VARCHAR (128),
    Status                 VARCHAR (16),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32)      DEFAULT CURRENT_USER
);
COPY reference.stop (atcocode, referenceCode, PlateCode, CleardownCode, CommonName, CommonNameLang,
	ShortCommonName, ShortCommonNameLang, Landmark, LandmarkLang, Street,
	StreetLang, Crossing, CrossingLang, Indicator, IndicatorLang, Bearing,
	NptgLocalityCode, LocalityName, ParentLocalityName, GrandParentLocalityName,
	Town, TownLang, Suburb, SuburbLang, LocalityCentre, GridType, Easting,
	Northing, Longitude, Latitude, StopType, BusStopType,
	TimingStatus, DefaultWaitTime, Notes, NotesLang, AdministrativeAreaCode,
	CreationDateTime, ModificationDateTime, RevisionNumber, Modification, Status)
FROM '/data/workspaces/go/github.com/foadmom/naptan_data/naptan_stops.csv'
DELIMITER ','
CSV HEADER;

-- =========================================================
-- 
-- =========================================================
---- DROP TABLE IF EXISTS reference.country;
CREATE TABLE reference.country (
    id        BIGSERIAL PRIMARY KEY,
    iso2      CHAR (2) NOT NULL,
    latitude  float8 NOT null ,
    longitude float8 NOT NULL,
    name      VARCHAR (64) NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
--COPY reference.country(iso2, latitude, longitude, name) 
--FROM '/home/postgres/countries.csv'
--DELIMITER ','
--CSV HEADER;
-- =========================================================
-- =========================================================
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
-- 
-- =========================================================
-- DROP TABLE IF EXISTS reference.language;
CREATE TABLE IF NOT EXISTS reference.language (
    id BIGSERIAL PRIMARY KEY,
    ISO_639_2_Code_b CHAR(3) NOT NULL,
    ISO_639_2_Code_t CHAR(3),
    ISO_639_1_Code CHAR(2),
    english_name   VARCHAR (128) NOT NULL,
    french_name    VARCHAR (128) NOT NULL,
--    german_name    VARCHAR (64) NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
--COPY reference.language(ISO_639_2_Code_b,ISO_639_2_Code_t, ISO_639_1_Code, english_name, french_name) 
--FROM '/data/workspaces/go/github.com/foadmom/naptan_data/language-codes-full.csv'
--DELIMITER ','
--CSV HEADER;
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('aar     ','   ','aa','Afar','afar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('abk     ','   ','ab','Abkhazian','abkhaze','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ace     ','   ','  ','Achinese','aceh','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ach     ','   ','  ','Acoli','acoli','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ada     ','   ','  ','Adangme','adangme','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ady     ','   ','  ','Adyghe; Adygei','adyghé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('afa     ','   ','  ','Afro-Asiatic languages','afro-asiatiques, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('afh     ','   ','  ','Afrihili','afrihili','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('afr     ','   ','af','Afrikaans','afrikaans','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ain     ','   ','  ','Ainu','aïnou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('aka     ','   ','ak','Akan','akan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('akk     ','   ','  ','Akkadian','akkadien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('alb     ','sqi','sq','Albanian','albanais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ale     ','   ','  ','Aleut','aléoute','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('alg     ','   ','  ','Algonquian languages','algonquines, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('alt     ','   ','  ','Southern Altai','altai du Sud','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('amh     ','   ','am','Amharic','amharique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ang     ','   ','  ','English, Old (ca.450-1100)','anglo-saxon (ca.450-1100)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('anp     ','   ','  ','Angika','angika','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('apa     ','   ','  ','Apache languages','apaches, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ara     ','   ','ar','Arabic','arabe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arc     ','   ','  ','Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)','araméen d''empire (700-300 BCE)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arg     ','   ','an','Aragonese','aragonais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arm     ','hye','hy','Armenian','arménien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arn     ','   ','  ','Mapudungun; Mapuche','mapudungun; mapuche; mapuce','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arp     ','   ','  ','Arapaho','arapaho','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('art     ','   ','  ','Artificial languages','artificielles, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('arw     ','   ','  ','Arawak','arawak','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('asm     ','   ','as','Assamese','assamais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ast     ','   ','  ','Asturian; Bable; Leonese; Asturleonese','asturien; bable; léonais; asturoléonais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ath     ','   ','  ','Athapascan languages','athapascanes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('aus     ','   ','  ','Australian languages','australiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ava     ','   ','av','Avaric','avar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ave     ','   ','ae','Avestan','avestique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('awa     ','   ','  ','Awadhi','awadhi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('aym     ','   ','ay','Aymara','aymara','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('aze     ','   ','az','Azerbaijani','azéri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bad     ','   ','  ','Banda languages','banda, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bai     ','   ','  ','Bamileke languages','bamiléké, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bak     ','   ','ba','Bashkir','bachkir','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('bal     ','   ','  ','Baluchi','baloutchi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bam     ','   ','bm','Bambara','bambara','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ban     ','   ','  ','Balinese','balinais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('baq     ','eus','eu','Basque','basque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bas     ','   ','  ','Basa','basa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bat     ','   ','  ','Baltic languages','baltes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bej     ','   ','  ','Beja; Bedawiyet','bedja','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bel     ','   ','be','Belarusian','biélorusse','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bem     ','   ','  ','Bemba','bemba','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ben     ','   ','bn','Bengali','bengali','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ber     ','   ','  ','Berber languages','berbères, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bho     ','   ','  ','Bhojpuri','bhojpuri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bih     ','   ','  ','Bihari languages','langues biharis','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bik     ','   ','  ','Bikol','bikol','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bin     ','   ','  ','Bini; Edo','bini; edo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bis     ','   ','bi','Bislama','bichlamar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bla     ','   ','  ','Siksika','blackfoot','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bnt     ','   ','  ','Bantu languages','bantou, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bos     ','   ','bs','Bosnian','bosniaque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bra     ','   ','  ','Braj','braj','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('bre     ','   ','br','Breton','breton','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('btk     ','   ','  ','Batak languages','batak, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bua     ','   ','  ','Buriat','bouriate','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bug     ','   ','  ','Buginese','bugi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bul     ','   ','bg','Bulgarian','bulgare','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('bur     ','mya','my','Burmese','birman','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('byn     ','   ','  ','Blin; Bilin','blin; bilen','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cad     ','   ','  ','Caddo','caddo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cai     ','   ','  ','Central American Indian languages','amérindiennes de L''Amérique centrale, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('car     ','   ','  ','Galibi Carib','karib; galibi; carib','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('cat     ','   ','ca','Catalan; Valencian','catalan; valencien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cau     ','   ','  ','Caucasian languages','caucasiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ceb     ','   ','  ','Cebuano','cebuano','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cel     ','   ','  ','Celtic languages','celtiques, langues; celtes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cha     ','   ','ch','Chamorro','chamorro','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chb     ','   ','  ','Chibcha','chibcha','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('che     ','   ','ce','Chechen','tchétchène','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chg     ','   ','  ','Chagatai','djaghataï','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chi     ','zho','zh','Chinese','chinois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chk     ','   ','  ','Chuukese','chuuk','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('chm     ','   ','  ','Mari','mari','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chn     ','   ','  ','Chinook jargon','chinook, jargon','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cho     ','   ','  ','Choctaw','choctaw','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chp     ','   ','  ','Chipewyan; Dene Suline','chipewyan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chr     ','   ','  ','Cherokee','cherokee','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chu     ','   ','cu','Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic','slavon d''église; vieux slave; slavon liturgique; vieux bulgare','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chv     ','   ','cv','Chuvash','tchouvache','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('chy     ','   ','  ','Cheyenne','cheyenne','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cmc     ','   ','  ','Chamic languages','chames, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cnr     ','   ','  ','Montenegrin','monténégrin','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('cop     ','   ','  ','Coptic','copte','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cor     ','   ','kw','Cornish','cornique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cos     ','   ','co','Corsican','corse','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cpe     ','   ','  ','Creoles and pidgins, English based','créoles et pidgins basés sur l''anglais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cpf     ','   ','  ','Creoles and pidgins, French-based','créoles et pidgins basés sur le français','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cpp     ','   ','  ','Creoles and pidgins, Portuguese-based','créoles et pidgins basés sur le portugais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cre     ','   ','cr','Cree','cree','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('crh     ','   ','  ','Crimean Tatar; Crimean Turkish','tatar de Crimé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('crp     ','   ','  ','Creoles and pidgins','créoles et pidgins','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('csb     ','   ','  ','Kashubian','kachoube','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('cus     ','   ','  ','Cushitic languages','couchitiques, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('cze     ','ces','cs','Czech','tchèque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dak     ','   ','  ','Dakota','dakota','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dan     ','   ','da','Danish','danois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dar     ','   ','  ','Dargwa','dargwa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('day     ','   ','  ','Land Dayak languages','dayak, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('del     ','   ','  ','Delaware','delaware','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('den     ','   ','  ','Slave (Athapascan)','esclave (athapascan)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dgr     ','   ','  ','Tlicho; Dogrib','tlicho; dogrib','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('din     ','   ','  ','Dinka','dinka','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('div     ','   ','dv','Divehi; Dhivehi; Maldivian','maldivien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('doi     ','   ','  ','Dogri','dogri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dra     ','   ','  ','Dravidian languages','dravidiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dsb     ','   ','  ','Lower Sorbian','bas-sorabe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dua     ','   ','  ','Duala','douala','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dum     ','   ','  ','Dutch, Middle (ca.1050-1350)','néerlandais moyen (ca. 1050-1350)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dut     ','nld','nl','Dutch; Flemish','néerlandais; flamand','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dyu     ','   ','  ','Dyula','dioula','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('dzo     ','   ','dz','Dzongkha','dzongkha','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('efi     ','   ','  ','Efik','efik','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('egy     ','   ','  ','Egyptian (Ancient)','égyptien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('eka     ','   ','  ','Ekajuk','ekajuk','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('elx     ','   ','  ','Elamite','élamite','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('eng     ','   ','en','English','anglais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('enm     ','   ','  ','English, Middle (1100-1500)','anglais moyen (1100-1500)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('epo     ','   ','eo','Esperanto','espéranto','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('est     ','   ','et','Estonian','estonien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ewe     ','   ','ee','Ewe','éwé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ewo     ','   ','  ','Ewondo','éwondo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fan     ','   ','  ','Fang','fang','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('fao     ','   ','fo','Faroese','féroïen','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fat     ','   ','  ','Fanti','fanti','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fij     ','   ','fj','Fijian','fidjien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fil     ','   ','  ','Filipino; Pilipino','filipino; pilipino','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fin     ','   ','fi','Finnish','finnois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fiu     ','   ','  ','Finno-Ugrian languages','finno-ougriennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fon     ','   ','  ','Fon','fon','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fre     ','fra','fr','French','français','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('frm     ','   ','  ','French, Middle (ca.1400-1600)','français moyen (1400-1600)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fro     ','   ','  ','French, Old (842-ca.1400)','français ancien (842-ca.1400)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('frr     ','   ','  ','Northern Frisian','frison septentrional','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('frs     ','   ','  ','Eastern Frisian','frison oriental','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fry     ','   ','fy','Western Frisian','frison occidental','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ful     ','   ','ff','Fulah','peul','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('fur     ','   ','  ','Friulian','frioulan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gaa     ','   ','  ','Ga','ga','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gay     ','   ','  ','Gayo','gayo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gba     ','   ','  ','Gbaya','gbaya','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gem     ','   ','  ','Germanic languages','germaniques, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('geo     ','kat','ka','Georgian','géorgien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ger     ','deu','de','German','allemand','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gez     ','   ','  ','Geez','guèze','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gil     ','   ','  ','Gilbertese','kiribati','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gla     ','   ','gd','Gaelic; Scottish Gaelic','gaélique; gaélique écossais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gle     ','   ','ga','Irish','irlandais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('glg     ','   ','gl','Galician','galicien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('glv     ','   ','gv','Manx','manx; mannois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gmh     ','   ','  ','German, Middle High (ca.1050-1500)','allemand, moyen haut (ca. 1050-1500)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('goh     ','   ','  ','German, Old High (ca.750-1050)','allemand, vieux haut (ca. 750-1050)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gon     ','   ','  ','Gondi','gond','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('gor     ','   ','  ','Gorontalo','gorontalo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('got     ','   ','  ','Gothic','gothique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('grb     ','   ','  ','Grebo','grebo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('grc     ','   ','  ','Greek, Ancient (to 1453)','grec ancien (jusqu''à 1453)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gre     ','ell','el','Greek, Modern (1453-)','grec moderne (après 1453)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('grn     ','   ','gn','Guarani','guarani','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gsw     ','   ','  ','Swiss German; Alemannic; Alsatian','suisse alémanique; alémanique; alsacien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('guj     ','   ','gu','Gujarati','goudjrati','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('gwi     ','   ','  ','Gwich''in','gwich''in','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hai     ','   ','  ','Haida','haida','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('hat     ','   ','ht','Haitian; Haitian Creole','haïtien; créole haïtien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hau     ','   ','ha','Hausa','haoussa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('haw     ','   ','  ','Hawaiian','hawaïen','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('heb     ','   ','he','Hebrew','hébreu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('her     ','   ','hz','Herero','herero','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hil     ','   ','  ','Hiligaynon','hiligaynon','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('him     ','   ','  ','Himachali languages; Western Pahari languages','langues himachalis; langues paharis occidentales','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hin     ','   ','hi','Hindi','hindi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hit     ','   ','  ','Hittite','hittite','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hmn     ','   ','  ','Hmong; Mong','hmong','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('hmo     ','   ','ho','Hiri Motu','hiri motu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hrv     ','   ','hr','Croatian','croate','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hsb     ','   ','  ','Upper Sorbian','haut-sorabe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hun     ','   ','hu','Hungarian','hongrois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('hup     ','   ','  ','Hupa','hupa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('iba     ','   ','  ','Iban','iban','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ibo     ','   ','ig','Igbo','igbo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ice     ','isl','is','Icelandic','islandais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ido     ','   ','io','Ido','ido','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('iii     ','   ','ii','Sichuan Yi; Nuosu','yi de Sichuan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ijo     ','   ','  ','Ijo languages','ijo, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('iku     ','   ','iu','Inuktitut','inuktitut','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ile     ','   ','ie','Interlingue; Occidental','interlingue','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ilo     ','   ','  ','Iloko','ilocano','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ina     ','   ','ia','Interlingua (International Auxiliary Language Association)','interlingua (langue auxiliaire internationale)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('inc     ','   ','  ','Indic languages','indo-aryennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ind     ','   ','id','Indonesian','indonésien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ine     ','   ','  ','Indo-European languages','indo-européennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('inh     ','   ','  ','Ingush','ingouche','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ipk     ','   ','ik','Inupiaq','inupiaq','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('ira     ','   ','  ','Iranian languages','iraniennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('iro     ','   ','  ','Iroquoian languages','iroquoises, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ita     ','   ','it','Italian','italien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('jav     ','   ','jv','Javanese','javanais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('jbo     ','   ','  ','Lojban','lojban','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('jpn     ','   ','ja','Japanese','japonais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('jpr     ','   ','  ','Judeo-Persian','judéo-persan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('jrb     ','   ','  ','Judeo-Arabic','judéo-arabe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kaa     ','   ','  ','Kara-Kalpak','karakalpak','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kab     ','   ','  ','Kabyle','kabyle','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('kac     ','   ','  ','Kachin; Jingpho','kachin; jingpho','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kal     ','   ','kl','Kalaallisut; Greenlandic','groenlandais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kam     ','   ','  ','Kamba','kamba','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kan     ','   ','kn','Kannada','kannada','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kar     ','   ','  ','Karen languages','karen, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kas     ','   ','ks','Kashmiri','kashmiri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kau     ','   ','kr','Kanuri','kanouri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kaw     ','   ','  ','Kawi','kawi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kaz     ','   ','kk','Kazakh','kazakh','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kbd     ','   ','  ','Kabardian','kabardien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('kha     ','   ','  ','Khasi','khasi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('khi     ','   ','  ','Khoisan languages','khoïsan, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('khm     ','   ','km','Central Khmer','khmer central','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kho     ','   ','  ','Khotanese; Sakan','khotanais; sakan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kik     ','   ','ki','Kikuyu; Gikuyu','kikuyu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kin     ','   ','rw','Kinyarwanda','rwanda','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kir     ','   ','ky','Kirghiz; Kyrgyz','kirghiz','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kmb     ','   ','  ','Kimbundu','kimbundu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kok     ','   ','  ','Konkani','konkani','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kom     ','   ','kv','Komi','kom','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('kon     ','   ','kg','Kongo','kongo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kor     ','   ','ko','Korean','coréen','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kos     ','   ','  ','Kosraean','kosrae','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kpe     ','   ','  ','Kpelle','kpellé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('krc     ','   ','  ','Karachay-Balkar','karatchai balkar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('krl     ','   ','  ','Karelian','carélien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kro     ','   ','  ','Kru languages','krou, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kru     ','   ','  ','Kurukh','kurukh','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kua     ','   ','kj','Kuanyama; Kwanyama','kuanyama; kwanyama','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kum     ','   ','  ','Kumyk','koumyk','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('kur     ','   ','ku','Kurdish','kurde','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('kut     ','   ','  ','Kutenai','kutenai','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lad     ','   ','  ','Ladino','judéo-espagnol','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lah     ','   ','  ','Lahnda','lahnda','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lam     ','   ','  ','Lamba','lamba','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lao     ','   ','lo','Lao','lao','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lat     ','   ','la','Latin','latin','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lav     ','   ','lv','Latvian','letton','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lez     ','   ','  ','Lezghian','lezghien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lim     ','   ','li','Limburgan; Limburger; Limburgish','limbourgeois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('lin     ','   ','ln','Lingala','lingala','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lit     ','   ','lt','Lithuanian','lituanien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lol     ','   ','  ','Mongo','mongo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('loz     ','   ','  ','Lozi','lozi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ltz     ','   ','lb','Luxembourgish; Letzeburgesch','luxembourgeois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lua     ','   ','  ','Luba-Lulua','luba-lulua','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lub     ','   ','lu','Luba-Katanga','luba-katanga','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lug     ','   ','lg','Ganda','ganda','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lui     ','   ','  ','Luiseno','luiseno','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lun     ','   ','  ','Lunda','lunda','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('luo     ','   ','  ','Luo (Kenya and Tanzania)','luo (Kenya et Tanzanie)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('lus     ','   ','  ','Lushai','lushai','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mac     ','mkd','mk','Macedonian','macédonien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mad     ','   ','  ','Madurese','madourais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mag     ','   ','  ','Magahi','magahi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mah     ','   ','mh','Marshallese','marshall','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mai     ','   ','  ','Maithili','maithili','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mak     ','   ','  ','Makasar','makassar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mal     ','   ','ml','Malayalam','malayalam','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('man     ','   ','  ','Mandingo','mandingue','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('mao     ','mri','mi','Maori','maori','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('map     ','   ','  ','Austronesian languages','austronésiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mar     ','   ','mr','Marathi','marathe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mas     ','   ','  ','Masai','massaï','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('may     ','msa','ms','Malay','malais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mdf     ','   ','  ','Moksha','moksa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mdr     ','   ','  ','Mandar','mandar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('men     ','   ','  ','Mende','mendé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mga     ','   ','  ','Irish, Middle (900-1200)','irlandais moyen (900-1200)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mic     ','   ','  ','Mi''kmaq; Micmac','mi''kmaq; micmac','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('min     ','   ','  ','Minangkabau','minangkabau','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mis     ','   ','  ','Uncoded languages','langues non codées','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mkh     ','   ','  ','Mon-Khmer languages','môn-khmer, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mlg     ','   ','mg','Malagasy','malgache','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mlt     ','   ','mt','Maltese','maltais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mnc     ','   ','  ','Manchu','mandchou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mni     ','   ','  ','Manipuri','manipuri','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mno     ','   ','  ','Manobo languages','manobo, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('moh     ','   ','  ','Mohawk','mohawk','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mon     ','   ','mn','Mongolian','mongol','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('mos     ','   ','  ','Mossi','moré','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mul     ','   ','  ','Multiple languages','multilingue','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mun     ','   ','  ','Munda languages','mounda, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mus     ','   ','  ','Creek','muskogee','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mwl     ','   ','  ','Mirandese','mirandais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('mwr     ','   ','  ','Marwari','marvari','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('myn     ','   ','  ','Mayan languages','maya, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('myv     ','   ','  ','Erzya','erza','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nah     ','   ','  ','Nahuatl languages','nahuatl, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nai     ','   ','  ','North American Indian languages','nord-amérindiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('nap     ','   ','  ','Neapolitan','napolitain','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nau     ','   ','na','Nauru','nauruan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nav     ','   ','nv','Navajo; Navaho','navaho','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nbl     ','   ','nr','Ndebele, South; South Ndebele','ndébélé du Sud','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nde     ','   ','nd','Ndebele, North; North Ndebele','ndébélé du Nord','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ndo     ','   ','ng','Ndonga','ndonga','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nds     ','   ','  ','Low German; Low Saxon; German, Low; Saxon, Low','bas allemand; bas saxon; allemand, bas; saxon, bas','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nep     ','   ','ne','Nepali','népalais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('new     ','   ','  ','Nepal Bhasa; Newari','nepal bhasa; newari','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nia     ','   ','  ','Nias','nias','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('nic     ','   ','  ','Niger-Kordofanian languages','nigéro-kordofaniennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('niu     ','   ','  ','Niuean','niué','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nno     ','   ','nn','Norwegian Nynorsk; Nynorsk, Norwegian','norvégien nynorsk; nynorsk, norvégien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nob     ','   ','nb','Bokmål, Norwegian; Norwegian Bokmål','norvégien bokmål','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nog     ','   ','  ','Nogai','nogaï; nogay','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('non     ','   ','  ','Norse, Old','norrois, vieux','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nor     ','   ','no','Norwegian','norvégien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nqo     ','   ','  ','N''Ko','n''ko','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nso     ','   ','  ','Pedi; Sepedi; Northern Sotho','pedi; sepedi; sotho du Nord','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nub     ','   ','  ','Nubian languages','nubiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('nwc     ','   ','  ','Classical Newari; Old Newari; Classical Nepal Bhasa','newari classique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nya     ','   ','ny','Chichewa; Chewa; Nyanja','chichewa; chewa; nyanja','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nym     ','   ','  ','Nyamwezi','nyamwezi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nyn     ','   ','  ','Nyankole','nyankolé','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nyo     ','   ','  ','Nyoro','nyoro','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('nzi     ','   ','  ','Nzima','nzema','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('oci     ','   ','oc','Occitan (post 1500)','occitan (après 1500)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('oji     ','   ','oj','Ojibwa','ojibwa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ori     ','   ','or','Oriya','oriya','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('orm     ','   ','om','Oromo','galla','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('osa     ','   ','  ','Osage','osage','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('oss     ','   ','os','Ossetian; Ossetic','ossète','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ota     ','   ','  ','Turkish, Ottoman (1500-1928)','turc ottoman (1500-1928)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('oto     ','   ','  ','Otomian languages','otomi, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('paa     ','   ','  ','Papuan languages','papoues, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pag     ','   ','  ','Pangasinan','pangasinan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pal     ','   ','  ','Pahlavi','pahlavi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pam     ','   ','  ','Pampanga; Kapampangan','pampangan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pan     ','   ','pa','Panjabi; Punjabi','pendjabi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pap     ','   ','  ','Papiamento','papiamento','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('pau     ','   ','  ','Palauan','palau','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('peo     ','   ','  ','Persian, Old (ca.600-400 B.C.)','perse, vieux (ca. 600-400 av. J.-C.)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('per     ','fas','fa','Persian','persan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('phi     ','   ','  ','Philippine languages','philippines, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('phn     ','   ','  ','Phoenician','phénicien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pli     ','   ','pi','Pali','pali','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pol     ','   ','pl','Polish','polonais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pon     ','   ','  ','Pohnpeian','pohnpei','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('por     ','   ','pt','Portuguese','portugais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pra     ','   ','  ','Prakrit languages','prâkrit, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('pro     ','   ','  ','Provençal, Old (to 1500); Occitan, Old (to 1500)','provençal ancien (jusqu''à 1500); occitan ancien (jusqu''à 1500)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('pus     ','   ','ps','Pushto; Pashto','pachto','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
--	 ('qaa-qtz ','   ','  ','Reserved for local use','réservée à l''usage local','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('que     ','   ','qu','Quechua','quechua','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('raj     ','   ','  ','Rajasthani','rajasthani','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('rap     ','   ','  ','Rapanui','rapanui','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('rar     ','   ','  ','Rarotongan; Cook Islands Maori','rarotonga; maori des îles Cook','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('roa     ','   ','  ','Romance languages','romanes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('roh     ','   ','rm','Romansh','romanche','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('rom     ','   ','  ','Romany','tsigane','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('rum     ','ron','ro','Romanian; Moldavian; Moldovan','roumain; moldave','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('run     ','   ','rn','Rundi','rundi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('rup     ','   ','  ','Aromanian; Arumanian; Macedo-Romanian','aroumain; macédo-roumain','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('rus     ','   ','ru','Russian','russe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sad     ','   ','  ','Sandawe','sandawe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sag     ','   ','sg','Sango','sango','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sah     ','   ','  ','Yakut','iakoute','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sai     ','   ','  ','South American Indian languages','sud-amérindiennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sal     ','   ','  ','Salishan languages','salishennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sam     ','   ','  ','Samaritan Aramaic','samaritain','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('san     ','   ','sa','Sanskrit','sanskrit','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sas     ','   ','  ','Sasak','sasak','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sat     ','   ','  ','Santali','santal','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('scn     ','   ','  ','Sicilian','sicilien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sco     ','   ','  ','Scots','écossais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sel     ','   ','  ','Selkup','selkoupe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sem     ','   ','  ','Semitic languages','sémitiques, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sga     ','   ','  ','Irish, Old (to 900)','irlandais ancien (jusqu''à 900)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sgn     ','   ','  ','Sign Languages','langues des signes','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('shn     ','   ','  ','Shan','chan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('sid     ','   ','  ','Sidamo','sidamo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sin     ','   ','si','Sinhala; Sinhalese','singhalais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sio     ','   ','  ','Siouan languages','sioux, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sit     ','   ','  ','Sino-Tibetan languages','sino-tibétaines, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sla     ','   ','  ','Slavic languages','slaves, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('slo     ','slk','sk','Slovak','slovaque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('slv     ','   ','sl','Slovenian','slovène','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sma     ','   ','  ','Southern Sami','sami du Sud','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sme     ','   ','se','Northern Sami','sami du Nord','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('smi     ','   ','  ','Sami languages','sames, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('smj     ','   ','  ','Lule Sami','sami de Lule','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('smn     ','   ','  ','Inari Sami','sami d''Inari','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('smo     ','   ','sm','Samoan','samoan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sms     ','   ','  ','Skolt Sami','sami skolt','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sna     ','   ','sn','Shona','shona','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('snd     ','   ','sd','Sindhi','sindhi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('snk     ','   ','  ','Soninke','soninké','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sog     ','   ','  ','Sogdian','sogdien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('som     ','   ','so','Somali','somali','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('son     ','   ','  ','Songhai languages','songhai, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('sot     ','   ','st','Sotho, Southern','sotho du Sud','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('spa     ','   ','es','Spanish; Castilian','espagnol; castillan','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('srd     ','   ','sc','Sardinian','sarde','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('srn     ','   ','  ','Sranan Tongo','sranan tongo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('srp     ','   ','sr','Serbian','serbe','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('srr     ','   ','  ','Serer','sérère','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ssa     ','   ','  ','Nilo-Saharan languages','nilo-sahariennes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ssw     ','   ','ss','Swati','swati','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('suk     ','   ','  ','Sukuma','sukuma','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sun     ','   ','su','Sundanese','soundanais','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('sus     ','   ','  ','Susu','soussou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('sux     ','   ','  ','Sumerian','sumérien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('swa     ','   ','sw','Swahili','swahili','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('swe     ','   ','sv','Swedish','suédois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('syc     ','   ','  ','Classical Syriac','syriaque classique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('syr     ','   ','  ','Syriac','syriaque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tah     ','   ','ty','Tahitian','tahitien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tai     ','   ','  ','Tai languages','tai, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tam     ','   ','ta','Tamil','tamoul','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tat     ','   ','tt','Tatar','tatar','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('tel     ','   ','te','Telugu','télougou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tem     ','   ','  ','Timne','temne','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ter     ','   ','  ','Tereno','tereno','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tet     ','   ','  ','Tetum','tetum','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tgk     ','   ','tg','Tajik','tadjik','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tgl     ','   ','tl','Tagalog','tagalog','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tha     ','   ','th','Thai','thaï','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tib     ','bod','bo','Tibetan','tibétain','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tig     ','   ','  ','Tigre','tigré','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tir     ','   ','ti','Tigrinya','tigrigna','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('tiv     ','   ','  ','Tiv','tiv','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tkl     ','   ','  ','Tokelau','tokelau','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tlh     ','   ','  ','Klingon; tlhIngan-Hol','klingon','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tli     ','   ','  ','Tlingit','tlingit','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tmh     ','   ','  ','Tamashek','tamacheq','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tog     ','   ','  ','Tonga (Nyasa)','tonga (Nyasa)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ton     ','   ','to','Tonga (Tonga Islands)','tongan (Îles Tonga)','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tpi     ','   ','  ','Tok Pisin','tok pisin','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tsi     ','   ','  ','Tsimshian','tsimshian','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tsn     ','   ','tn','Tswana','tswana','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('tso     ','   ','ts','Tsonga','tsonga','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tuk     ','   ','tk','Turkmen','turkmène','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tum     ','   ','  ','Tumbuka','tumbuka','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tup     ','   ','  ','Tupi languages','tupi, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tur     ','   ','tr','Turkish','turc','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tut     ','   ','  ','Altaic languages','altaïques, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tvl     ','   ','  ','Tuvalu','tuvalu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('twi     ','   ','tw','Twi','twi','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('tyv     ','   ','  ','Tuvinian','touva','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('udm     ','   ','  ','Udmurt','oudmourte','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('uga     ','   ','  ','Ugaritic','ougaritique','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('uig     ','   ','ug','Uighur; Uyghur','ouïgour','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ukr     ','   ','uk','Ukrainian','ukrainien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('umb     ','   ','  ','Umbundu','umbundu','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('und     ','   ','  ','Undetermined','indéterminée','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('urd     ','   ','ur','Urdu','ourdou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('uzb     ','   ','uz','Uzbek','ouszbek','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('vai     ','   ','  ','Vai','vaï','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ven     ','   ','ve','Venda','venda','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('vie     ','   ','vi','Vietnamese','vietnamien','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('vol     ','   ','vo','Volapük','volapük','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('vot     ','   ','  ','Votic','vote','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wak     ','   ','  ','Wakashan languages','wakashanes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wal     ','   ','  ','Wolaitta; Wolaytta','wolaitta; wolaytta','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('war     ','   ','  ','Waray','waray','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('was     ','   ','  ','Washo','washo','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wel     ','cym','cy','Welsh','gallois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wen     ','   ','  ','Sorbian languages','sorabes, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wln     ','   ','wa','Walloon','wallon','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('wol     ','   ','wo','Wolof','wolof','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('xal     ','   ','  ','Kalmyk; Oirat','kalmouk; oïrat','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('xho     ','   ','xh','Xhosa','xhosa','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('yao     ','   ','  ','Yao','yao','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('yap     ','   ','  ','Yapese','yapois','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('yid     ','   ','yi','Yiddish','yiddish','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('yor     ','   ','yo','Yoruba','yoruba','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('ypk     ','   ','  ','Yupik languages','yupik, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zap     ','   ','  ','Zapotec','zapotèque','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zbl     ','   ','  ','Blissymbols; Blissymbolics; Bliss','symboles Bliss; Bliss','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zen     ','   ','  ','Zenaga','zenaga','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');
INSERT INTO reference."language" (iso_639_2_code_b,iso_639_2_code_t,iso_639_1_code,english_name,french_name,created_at,updated_at,updated_by) VALUES
	 ('zgh     ','   ','  ','Standard Moroccan Tamazight','amazighe standard marocain','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zha     ','   ','za','Zhuang; Chuang','zhuang; chuang','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('znd     ','   ','  ','Zande languages','zandé, langues','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zul     ','   ','zu','Zulu','zoulou','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zun     ','   ','  ','Zuni','zuni','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zxx     ','   ','  ','No linguistic content; Not applicable','pas de contenu linguistique; non applicable','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres'),
	 ('zza     ','   ','  ','Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki','zaza; dimili; dimli; kirdki; kirmanjki; zazaki','2026-01-21 10:58:05.583799','2026-01-21 10:58:05.583799','postgres');


-- =========================================================
-- 
-- =========================================================
-- DROP TABLE IF EXISTS reference.city;
CREATE TABLE IF NOT EXISTS reference.city (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR (64) NOT NULL,
    latitude   FLOAT,
    longitude  FLOAT,
    country_id BIGINT , -- NOT NULL REFERENCES reference.country (id),
    zone       VARCHAR (64),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
--COPY reference.cities(name,latitude, longitude, country, iso2,zone,capital,population, population_proper) 
--FROM '/data/workspaces/go/github.com/foadmom/naptan_data/UK_cities.csv'
--DELIMITER ','
--CSV HEADER;

INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('London',51.5072,-0.1275,74),
	 ('Birmingham',52.48,-1.9025,74),
	 ('Portsmouth',50.8058,-1.0872,74),
	 ('Southampton',50.9025,-1.4042,74),
	 ('Nottingham',52.9561,-1.1512,74),
	 ('Bristol',51.4536,-2.5975,74),
	 ('Manchester',53.479,-2.2452,74),
	 ('Liverpool',53.4094,-2.9785,74),
	 ('Leicester',52.6344,-1.1319,74),
	 ('Worthing',50.8147,-0.3714,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Coventry',52.4081,-1.5106,74),
	 ('Belfast',54.5964,-5.93,74),
	 ('Bradford',53.8,-1.75,74),
	 ('Derby',52.9247,-1.478,74),
	 ('Plymouth',50.3714,-4.1422,74),
	 ('Westminster',51.4947,-0.1353,74),
	 ('Wolverhampton',52.5833,-2.1333,74),
	 ('Northampton',52.2304,-0.8938,74),
	 ('Norwich',52.6286,1.2928,74),
	 ('Luton',51.8783,-0.4147,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Solihull',52.413,-1.778,74),
	 ('Islington',51.544,-0.1027,74),
	 ('Aberdeen',57.15,-2.11,74),
	 ('Croydon',51.3727,-0.1099,74),
	 ('Bournemouth',50.72,-1.88,74),
	 ('Basildon',51.58,0.49,74),
	 ('Maidstone',51.272,0.529,74),
	 ('Ilford',51.5575,0.0858,74),
	 ('Warrington',53.39,-2.59,74),
	 ('Oxford',51.75,-1.25,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Harrow',51.5836,-0.3464,74),
	 ('West Bromwich',52.519,-1.995,74),
	 ('Gloucester',51.8667,-2.25,74),
	 ('York',53.96,-1.08,74),
	 ('Blackpool',53.8142,-3.0503,74),
	 ('Stockport',53.4083,-2.1494,74),
	 ('Sale',53.424,-2.322,74),
	 ('Tottenham',51.5975,-0.0681,74),
	 ('Cambridge',52.2053,0.1192,74),
	 ('Romford',51.5768,0.1801,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Colchester',51.8917,0.903,74),
	 ('High Wycombe',51.6287,-0.7482,74),
	 ('Gateshead',54.9556,-1.6,74),
	 ('Slough',51.5084,-0.5881,74),
	 ('Blackburn',53.748,-2.482,74),
	 ('Chelmsford',51.73,0.48,74),
	 ('Rochdale',53.61,-2.16,74),
	 ('Rotherham',53.43,-1.357,74),
	 ('Walthamstow',51.584,-0.021,74),
	 ('Basingstoke',51.2667,-1.0876,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Salford',53.483,-2.2931,74),
	 ('Hounslow',51.4668,-0.375,74),
	 ('Wembley',51.5528,-0.2979,74),
	 ('Worcester',52.1911,-2.2206,74),
	 ('Hammersmith',51.4928,-0.2229,74),
	 ('Rayleigh',51.5864,0.6049,74),
	 ('Hemel Hempstead',51.7526,-0.4692,74),
	 ('Bath',51.38,-2.36,74),
	 ('Hayes',51.5127,-0.4211,74),
	 ('Darlington',54.527,-1.5526,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Hove',50.8352,-0.1758,74),
	 ('Hastings',50.85,0.57,74),
	 ('Watford',51.655,-0.3957,74),
	 ('Stevenage',51.9017,-0.2019,74),
	 ('Hartlepool',54.69,-1.21,74),
	 ('Chester',53.19,-2.89,74),
	 ('Fulham',51.4828,-0.195,74),
	 ('Nuneaton',52.523,-1.468,74),
	 ('Ealing',51.5175,-0.2988,74),
	 ('Aylesbury',51.8168,-0.8124,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Edmonton',51.6154,-0.0708,74),
	 ('Saint Albans',51.755,-0.336,74),
	 ('Burnley',53.789,-2.248,74),
	 ('Batley',53.7167,-1.6356,74),
	 ('Scunthorpe',53.5809,-0.6502,74),
	 ('Dudley',52.508,-2.089,74),
	 ('Brixton',51.4575,-0.1175,74),
	 ('Southall',51.5111,-0.3756,74),
	 ('Paisley',55.8456,-4.4239,74),
	 ('Chatham',51.37,0.52,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('East Ham',51.5323,0.0554,74),
	 ('Weston-super-Mare',51.346,-2.977,74),
	 ('Carlisle',54.8947,-2.9364,74),
	 ('South Shields',54.995,-1.43,74),
	 ('East Kilbride',55.7644,-4.1769,74),
	 ('Burton upon Trent',52.8019,-1.6367,74),
	 ('Harrogate',53.9919,-1.5378,74),
	 ('Crewe',53.099,-2.44,74),
	 ('Lowestoft',52.48,1.75,74),
	 ('Rugby',52.37,-1.26,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Chingford',51.623,0.009,74),
	 ('Uxbridge',51.5404,-0.4778,74),
	 ('Walsall',52.58,-1.98,74),
	 ('Grays',51.475,0.33,74),
	 ('Walton upon Thames',51.3868,-0.4133,74),
	 ('Thornton Heath',51.4002,-0.1086,74),
	 ('Finchley',51.599,-0.187,74),
	 ('Kensington',51.5,-0.19,74),
	 ('Boston',52.974,-0.0214,74),
	 ('Paignton',50.4353,-3.5625,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Waterlooville',50.88,-1.03,74),
	 ('Guiseley',53.875,-1.706,74),
	 ('Hornchurch',51.5565,0.2128,74),
	 ('Mitcham',51.4009,-0.1517,74),
	 ('Feltham',51.4496,-0.4089,74),
	 ('Stourbridge',52.4575,-2.1479,74),
	 ('Rochester',51.375,0.5,74),
	 ('Dewsbury',53.691,-1.633,74),
	 ('Acton',51.5135,-0.2707,74),
	 ('Twickenham',51.449,-0.337,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Wrecsam',53.046,-2.993,74),
	 ('Ellesmere Port',53.279,-2.897,74),
	 ('Bangor',54.66,-5.67,74),
	 ('Taunton',51.019,-3.1,74),
	 ('Loughborough',52.7725,-1.2078,74),
	 ('Barking',51.54,0.08,74),
	 ('Edgware',51.6185,-0.2729,74),
	 ('Littlehampton',50.8094,-0.5409,74),
	 ('Ruislip',51.576,-0.433,74),
	 ('Streatham',51.4279,-0.1235,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Royal Tunbridge Wells',51.132,0.263,74),
	 ('Bebington',53.35,-3.003,74),
	 ('Macclesfield',53.25,-2.13,74),
	 ('Wellingborough',52.3028,-0.6944,74),
	 ('Kettering',52.3931,-0.7229,74),
	 ('Braintree',51.878,0.55,74),
	 ('Royal Leamington Spa',52.2919,-1.5358,74),
	 ('Barrow in Furness',54.1108,-3.2261,74),
	 ('Dunfermline',56.0719,-3.4393,74),
	 ('Altrincham',53.3838,-2.3547,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Lancaster',54.0489,-2.8014,74),
	 ('Crosby',53.4872,-3.0343,74),
	 ('Bootle',53.4457,-2.9891,74),
	 ('Stratford',51.5423,-0.0026,74),
	 ('Folkestone',51.0792,1.1794,74),
	 ('Cumbernauld',55.945,-3.994,74),
	 ('Andover',51.208,-1.48,74),
	 ('Neath',51.66,-3.81,74),
	 ('Rowley Regis',52.488,-2.05,74),
	 ('Scarborough',54.2825,-0.4,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Leith',55.98,-3.17,74),
	 ('Yeovil',50.9452,-2.637,74),
	 ('Eltham',51.451,0.052,74),
	 ('Hampstead',51.5541,-0.1744,74),
	 ('Sutton in Ashfield',53.125,-1.261,74),
	 ('Morden',51.4015,-0.1949,74),
	 ('Barnet',51.6444,-0.1997,74),
	 ('Stretford',53.4466,-2.3086,74),
	 ('Beckenham',51.408,-0.022,74),
	 ('Greenford',51.5299,-0.3488,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Cheshunt',51.702,-0.035,74),
	 ('Kirkby',53.48,-2.89,74),
	 ('Salisbury',51.07,-1.79,74),
	 ('Ashton',53.4897,-2.0952,74),
	 ('Surbiton',51.394,-0.307,74),
	 ('Castleford',53.716,-1.356,74),
	 ('Catford',51.4452,-0.0207,74),
	 ('Worksop',53.3042,-1.1244,74),
	 ('Morley',53.7492,-1.6023,74),
	 ('Merthyr Tudful',51.743,-3.378,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Middleton',53.555,-2.187,74),
	 ('Fleet',51.2834,-0.8456,74),
	 ('Fareham',50.85,-1.18,74),
	 ('Urmston',53.4487,-2.3747,74),
	 ('Sutton',51.3656,-0.1963,74),
	 ('Caerphilly',51.578,-3.218,74),
	 ('Bridgwater',51.128,-2.993,74),
	 ('Newbury',51.401,-1.323,74),
	 ('Welling',51.4594,0.1097,74),
	 ('Kingswood',51.46,-2.505,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Dunstable',51.886,-0.521,74),
	 ('Ramsgate',51.336,1.416,74),
	 ('Strood',51.393,0.478,74),
	 ('Cleethorpes',53.5533,-0.0215,74),
	 ('Pinner',51.5932,-0.3894,74),
	 ('Great Yarmouth',52.606,1.729,74),
	 ('Ilkeston',52.9711,-1.3092,74),
	 ('Chorley',53.653,-2.632,74),
	 ('Herne Bay',51.37,1.13,74),
	 ('Bishops Stortford',51.872,0.1725,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Arnold',53.005,-1.127,74),
	 ('Coalville',52.724,-1.369,74),
	 ('Bletchley',51.994,-0.732,74),
	 ('Leighton Buzzard',51.9165,-0.6617,74),
	 ('Airdrie',55.86,-3.98,74),
	 ('Blyth',55.126,-1.514,74),
	 ('Laindon',51.574,0.4181,74),
	 ('Llanelli',51.684,-4.163,74),
	 ('Beeston',52.927,-1.215,74),
	 ('Small Heath',52.4629,-1.8542,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Whitley Bay',55.0456,-1.4443,74),
	 ('Denton',53.4554,-2.1122,74),
	 ('West Bridgford',52.932,-1.127,74),
	 ('Borehamwood',51.6578,-0.2722,74),
	 ('Falkirk',56.0011,-3.7835,74),
	 ('Walkden',53.5239,-2.3991,74),
	 ('Kenton',51.5878,-0.3086,74),
	 ('Bridlington',54.0819,-0.1923,74),
	 ('Billingham',54.61,-1.27,74),
	 ('Grantham',52.918,-0.638,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('North Shields',55.0097,-1.4448,74),
	 ('Hitchin',51.947,-0.283,74),
	 ('Spalding',52.7858,-0.1529,74),
	 ('Rainham',51.36,0.61,74),
	 ('Letchworth',51.978,-0.23,74),
	 ('Wickford',51.6114,0.5207,74),
	 ('Huyton',53.4111,-2.8403,74),
	 ('Abingdon',51.6717,-1.2783,74),
	 ('Trowbridge',51.32,-2.208,74),
	 ('Wigston Magna',52.5812,-1.093,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Didcot',51.606,-1.241,74),
	 ('Earley',51.433,-0.933,74),
	 ('Bexleyheath',51.459,0.138,74),
	 ('Ecclesfield',53.4429,-1.4698,74),
	 ('Darwen',53.698,-2.461,74),
	 ('Prestwich',53.5333,-2.2833,74),
	 ('Pontypridd',51.602,-3.342,74),
	 ('Rutherglen',55.828,-4.214,74),
	 ('Dover',51.1295,1.3089,74),
	 ('Chichester',50.8365,-0.7792,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Deal',51.2226,1.4006,74),
	 ('Bicester',51.9,-1.15,74),
	 ('Northolt',51.5467,-0.37,74),
	 ('Wishaw',55.7742,-3.9183,74),
	 ('Carshalton',51.3652,-0.1676,74),
	 ('Bulwell',53.001,-1.197,74),
	 ('Newtownards',54.591,-5.68,74),
	 ('Kendal',54.326,-2.745,74),
	 ('Cramlington',55.082,-1.585,74),
	 ('Bromsgrove',52.3353,-2.0579,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Pont-y-pŵl',51.703,-3.041,74),
	 ('Hanwell',51.509,-0.338,74),
	 ('Frome',51.2279,-2.3215,74),
	 ('Wood Green',51.5981,-0.1149,74),
	 ('Darlaston',52.5708,-2.0457,74),
	 ('Ashington',55.181,-1.568,74),
	 ('Longton',52.9877,-2.1327,74),
	 ('Melton Mowbray',52.7661,-0.886,74),
	 ('Aldridge',52.606,-1.9179,74),
	 ('Farnworth',53.5452,-2.3999,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Highbury',51.552,-0.097,74),
	 ('Cheadle Hulme',53.3761,-2.1897,74),
	 ('Newton Aycliffe',54.62,-1.58,74),
	 ('Bournville',52.4299,-1.9355,74),
	 ('Shenley Brook End',52.009,-0.789,74),
	 ('Consett',54.85,-1.83,74),
	 ('Coulsdon',51.3211,-0.1386,74),
	 ('Bilston',52.566,-2.0728,74),
	 ('Wellington',52.7001,-2.5157,74),
	 ('Bishop Auckland',54.663,-1.676,74);
INSERT INTO reference.city ("name",latitude,longitude,country_id) VALUES
	 ('Longbridge',52.395,-1.979,74),
	 ('Bloxwich',52.614,-2.004,74),
	 ('Upminster',51.5557,0.2512,74),
	 ('Rhyl',53.321,-3.48,74),
	 ('Droitwich',52.267,-2.153,74),
	 ('Hindley',53.5355,-2.5658,74),
	 ('Westhoughton',53.549,-2.529,74),
	 ('Broadstairs',51.3589,1.4394,74);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
--DROP SCHEMA IF EXISTS network CASCADE;
--CREATE SCHEMA IF NOT EXISTS network;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO network;


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
-- zone can be an area, city, town, state, county or .....
-- In it's simplest form it would be big towns and cities, 
--   eg London, Madrid
-- =========================================================
CREATE TABLE network.zone (
    id   BIGSERIAL PRIMARY KEY,
    code VARCHAR (16),		-- not sure who would set this
    name VARCHAR (64) NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_zone_code ON network.zone (code);
CREATE INDEX idx_zone_name ON network.zone (name);


-- =========================================================
-- stop (Transmodel compliant)
-- the Geo position is in stop rather than stop-point.
--   this means we do not get pin point accuracy of different
--   eg platforms within a large stop like Victoria station
-- =========================================================
-- DROP TABLE IF EXISTS network.stop;
CREATE TABLE IF NOT EXISTS network.stop (
    id              BIGSERIAL PRIMARY KEY,
    code            VARCHAR (8) NOT NULL,
    name            VARCHAR (64),
    type            common.STOP_TYPE NOT NULL,
    zone_id         BIGINT NOT NULL , 
    post_code       VARCHAR (16),
    geo             common.geography,
    additional_info VARCHAR (256),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_stop_stop_code ON network.stop (code);
CREATE INDEX idx_stop_post_code ON network.stop (post_code);
CREATE INDEX idx_stop_zone_id ON network.stop (zone_id);
--CREATE INDEX idx_stop_geo_position ON network.stop USING GIST (geo_position);
CREATE INDEX idx_stop_name ON network.stop (name);


-- =========================================================
-- I assume this applies to eg which platform/bay the stop is
-- planned for.
-- =========================================================
CREATE TABLE network.stop_point (
    id              BIGSERIAL PRIMARY KEY,
    platform        VARCHAR (8),
    direction       VARCHAR (32), -- like North-East corner of Victoria station
    additional_info VARCHAR (256),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);

-- =========================================================
-- created when a service is scheduled. needs to be linked
-- to a particular service/flight instance
-- I think we need both stop_id and stop_point_id because 
-- stop_point should be optional for a stop
-- =========================================================
-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.facility (
    id              BIGSERIAL PRIMARY KEY,
	code            VARCHAR (8) UNIQUE NOT NULL,
	name            VARCHAR (64) NOT NULL,
	additional_info VARCHAR (256),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
    
-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.stop_facilities (
    id               BIGSERIAL PRIMARY KEY,
    stop_id          BIGINT REFERENCES network.stop(id),
    stop_facility_id BIGINT REFERENCES network.facility (id),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
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
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR (8) UNIQUE NOT NULL, 
    name       VARCHAR (64),                   -- long name or company name
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_operator_code ON network.operator (code);
CREATE INDEX idx_operator_name ON network.operator (name);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.network (
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR (8) UNIQUE NOT NULL,
    name       VARCHAR (64) NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_network_code ON network.network (code);
CREATE INDEX idx_network_name ON network.network (name);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.operator_network (
    id            BIGSERIAL PRIMARY KEY,
	operator_id   BIGINT REFERENCES network.operator (id),
	network_id    BIGINT REFERENCES network.network (id),
    trans_mode    common.TRANSPORT_MODE NOT NULL,
    country_id    BIGINT  NOT NULL REFERENCES reference.country (id),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_operator_network_operator_id ON network.operator_network (operator_id);
CREATE INDEX idx_operator_network_trans_mode  ON network.operator_network (trans_mode);
CREATE INDEX idx_operator_network_country_id  ON network.operator_network (country_id);
CREATE INDEX idx_operator_network_network_id  ON network.operator_network (network_id);


-- =========================================================
-- =========================================================
-- =========================================================
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
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR (128) NOT NULL,
    public_code VARCHAR (8),
    trans_mode  common.TRANSPORT_MODE NOT NULL,
    operator_id BIGINT  NOT NULL REFERENCES network.operator(id),
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
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
    id                BIGSERIAL PRIMARY KEY,
    line_id           BIGINT REFERENCES network.line(id),
    code              VARCHAR (8) NOT NULL,		-- eg FLX-241
--    service_direction SERVICE_DIRECTION NOT NULL,
    compass_direction common.COMPASS_DIRECTION,
    from_stop_id      BIGINT REFERENCES network.stop(id),
    to_stop_id        BIGINT REFERENCES network.stop(id),
    distance_meters   INTEGER,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_service_line_id ON network.service (line_id);
CREATE INDEX idx_service_code ON network.service (code);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.service_link (
    id              BIGSERIAL PRIMARY KEY,
    service_id      BIGINT REFERENCES network.service(id),
    from_stop_id    BIGINT REFERENCES network.stop(id),
    to_stop_id      BIGINT REFERENCES network.stop(id),
    distance_meters INTEGER,
    sequence_order  INTEGER NOT NULL,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_servicelink_service_seq ON network.service_link (service_id, sequence_order);


-- =========================================================
-- This is a service instance on a particular date and time.
-- eg. If a service runs 5 times a day for 3 months, then
-- there should be 5x90 rows of the the following created.
-- The departure and arrival times are for the end to end
-- journey and not for a particular stop. This makes the 
-- search faster, but not needed as we can get this from
-- the linked service_link_instance s.
-- =========================================================
CREATE TABLE network.service_instance (
    id              BIGSERIAL PRIMARY KEY,
    service_id      BIGINT REFERENCES network.service(id),
--    departure_time  TIMESTAMP NOT NULL,
--    arrival_time    TIMESTAMP NOT NULL,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_service_instance_service_id ON network.service_instance (service_id);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE network.scheduled_stop (
    id                 BIGSERIAL PRIMARY KEY,
    stop_id            BIGINT    NOT NULL REFERENCES network.stop(id), 
    stop_point_id      BIGINT             REFERENCES network.stop_point(id),
    service_instance_id BIGINT   NOT NULL REFERENCES network.service_instance (id),
    sequence_order     INTEGER   NOT NULL,
    scheduled_time     TIMESTAMP NOT NULL,
    actual_time        TIMESTAMP,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32)      DEFAULT CURRENT_USER
);

-- =========================================================
-- There is a row created for every departure from a stop
-- for every service instance.
-- =========================================================
CREATE TABLE network.service_link_instance (
    id                  BIGSERIAL PRIMARY KEY,
    service_instance_id BIGINT REFERENCES network.service_instance(id),
    service_link_id     BIGINT REFERENCES network.service_link (id),
    departure_time      TIMESTAMP NOT NULL,
    arrival_time        TIMESTAMP NOT NULL,
    --
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_service_link_instance_service_link_id ON network.service_link_instance (service_link_id);


-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.journey_pattern (
--    id BIGSERIAL PRIMARY KEY,
--    service_id BIGINT REFERENCES network.service(id),
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by VARCHAR (32) DEFAULT CURRENT_USER
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
--    updated_by VARCHAR (32) DEFAULT CURRENT_USER
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
--    updated_by VARCHAR (32) DEFAULT CURRENT_USER
--);

-- =========================================================
-- Calendar & Exceptions
-- =========================================================

CREATE TABLE network.service_calendar (
    id BIGSERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date   DATE,			-- assuming we can have a opendated calendar
    monday     BOOLEAN NOT NULL,
    tuesday    BOOLEAN NOT NULL,
    wednesday  BOOLEAN NOT NULL,
    thursday   BOOLEAN NOT NULL,
    friday     BOOLEAN NOT NULL,
    saturday   BOOLEAN NOT NULL,
    sunday     BOOLEAN NOT NULL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Operational side of the data
-- =========================================================
-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.service_journey_calendar (
--    service_journey_id BIGINT REFERENCES network.service_journey(id),
--    service_calendar_id BIGINT REFERENCES network.service_calendar(id),
--    PRIMARY KEY (service_journey_id, service_calendar_id),
--    -- 
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by VARCHAR (32) DEFAULT CURRENT_USER
--);
--
-- =========================================================
-- 
-- =========================================================
--CREATE TABLE network.service_exception (
--    id                  BIGSERIAL PRIMARY KEY,
--    service_calendar_id BIGINT REFERENCES network.service_calendar(id),
--    date                DATE NOT NULL,
--    type                EXCEPTION_TYPE NOT NULL,
--    -- 
--    created_at TIMESTAMP DEFAULT now(),
--    updated_at TIMESTAMP DEFAULT now(),
--    updated_by VARCHAR (32) DEFAULT CURRENT_USER
--);
--CREATE INDEX idx_calendar_range ON network.service_calendar USING GIST (daterange(start_date, end_date, '[]') );
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Real-Time Data (Optimized)
-- =========================================================
-- DROP SCHEMA IF EXISTS operation cascade;
-- CREATE SCHEMA IF NOT EXISTS operation;
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO operation;

-- =========================================================
--  Vehicle
-- =========================================================
CREATE TABLE IF NOT EXISTS operation.vehicle (
    id BIGSERIAL PRIMARY KEY,
    code        VARCHAR(8) NOT NULL, -- This may vary between different operators
    registration VARCHAR (20) NOT NULL,
    vehicle_type VARCHAR (20),
    capacity     INT NOT NULL,
    seat_layout  BIGINT, -- REFERENCES coach_seats_layout(id),
    fuel         common.FUEL_TYPE NOT NULL,
    operator_id  BIGINT REFERENCES network.operator(id),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_vehicle_code ON operation.vehicle(code);
CREATE INDEX idx_vehicle_capacity ON operation.vehicle(capacity);
CREATE INDEX idx_vehicle_operator_id ON operation.vehicle(operator_id);
CREATE INDEX idx_vehicle_seat_layout ON operation.vehicle(seat_layout);
CREATE INDEX idx_vehicle_registration ON operation.vehicle(registration);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE operation.vehicle_service_assignment (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES operation.vehicle(id),
    service_instance_id BIGINT REFERENCES network.service_instance(id),
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE operation.service_journey_status (
    service_journey_id BIGINT PRIMARY KEY REFERENCES network.service_instance(id),
    status             common.JOURNEY_STATUS,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- 
-- =========================================================
-- CREATE SCHEMA IF NOT EXISTS tracking;
CREATE TABLE tracking.vehicle_position (
    vehicle_id    BIGINT REFERENCES operation.vehicle(id),
    recorded_at   TIMESTAMP NOT NULL,
    geo           common.geography,
    speed         REAL,
    bearing       REAL,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER,
    PRIMARY KEY (vehicle_id, recorded_at)
) PARTITION BY RANGE (recorded_at);
-- Recommended: daily partitions + retention policy.
--CREATE INDEX idx_vehicle_position_geo_position ON tracking.vehicle_position USING GIST (geo_position);

-- =========================================================
-- 
-- =========================================================
CREATE TABLE tracking.realtime_stop_update (
    id BIGSERIAL PRIMARY KEY,
    service_instance_id BIGINT REFERENCES network.service_instance(id),
    stop_point_id       BIGINT REFERENCES network.stop_point(id),
    delay_seconds       INTEGER,
    predicted_arrival_time   TIMESTAMP,
    predicted_departure_time TIMESTAMP,
    status                   common.REALTIME_STATUS,
    -- 
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    updated_by VARCHAR (32) DEFAULT CURRENT_USER
);
CREATE INDEX idx_rt_update_lookup ON tracking.realtime_stop_update (service_instance_id, stop_point_id);
CREATE INDEX idx_rt_update_recent ON tracking.realtime_stop_update (service_instance_id, updated_at DESC);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
--{
--    "response":
--    {
--        "rc" : ["OK", "ERROR"]    // if rc == "OK" move on to "result" else go to "error"
--        "result" : ""             // a single text field in json
--
--        "errors":
--        {
--            // these fields are for postgres and will/may be different for a different database
--            "returned_sqlstate"     : "",
--            "column_name"           : "",
--            "constraint_name"       : "",
--            "pg_datatype_name"      : "",
--            "message_text"          : "",
--            "table_name"            : "",
--            "schema_name"           : "",
--            "pg_exception_detail"   : "",
--            "pg_exception_hint"     : "",
--            "pg_exception_context"  : ""
--        }
--    }
--}
-- =========================================================
-- =========================================================
-- 
-- =========================================================
-- CREATE SCHEMA IF NOT EXISTS common;

-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION common.create_ok_response (rc TEXT, result json) RETURNS TEXT
AS $$
    DECLARE
        _output TEXT;
    BEGIN
        SELECT INTO _output CONCAT ('{"RESPONSE": {"rc" :"', rc, '","result":', result, ',"errors":', '"N/A"}}');
        RETURN _output;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION common.create_error_response (rc TEXT, errors json) RETURNS TEXT
AS $$
    DECLARE
        _output TEXT;
    BEGIN
        SELECT INTO _output CONCAT ('{"response": {"rc" :"', rc, '","result": "N/A", "errors":', errors, '}}');
--        SELECT INTO _output CONCAT ('{"response": {"rc" :"', rc, '","errors":', errors, '}}');
        RETURN _output;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION common.function_wrapper (functionName text, input json) RETURNS TEXT 
AS $$
    DECLARE
        v_RETURNED_SQLSTATE     text;   -- the SQLSTATE error code of the exception
        v_COLUMN_NAME           text;   -- the name of the column related to exception
        v_CONSTRAINT_NAME       text;   -- the name of the constraint related to exception
        v_PG_DATATYPE_NAME      text;   -- the name of the data type related to exception
        v_MESSAGE_TEXT          text;   -- the text of the exception's primary message
        v_TABLE_NAME            text;   -- the name of the table related to exception
        v_SCHEMA_NAME           text;   -- the name of the schema related to exception
        v_PG_EXCEPTION_DETAIL   text;   -- the text of the exception's detail message, if any
        v_PG_EXCEPTION_HINT     text;   -- the text of the exception's hint message, if any
        v_PG_EXCEPTION_CONTEXT  text;   -- line(s) of text describing the call stack at the time of the exception (see Section 41.6.9)

		_result TEXT;
        _errors json;
        _query  TEXT;
        
        BEGIN
			IF input IS NULL THEN
            	_query = 'SELECT ' || $1::regproc || ' ()';
			ELSE
            	_query = 'SELECT ' || $1::regproc || ' (''' || $2::json || ''')';
			END IF;
            EXECUTE  _query INTO _result;
            SELECT common.create_ok_response ('OK'::TEXT, _result::json) INTO _result;
            RETURN _result;

            EXCEPTION WHEN OTHERS THEN
                  GET STACKED DIAGNOSTICS 
                        v_RETURNED_SQLSTATE   = RETURNED_SQLSTATE,
                        v_COLUMN_NAME         = COLUMN_NAME,
                        v_CONSTRAINT_NAME     = CONSTRAINT_NAME,
                        v_PG_DATATYPE_NAME    = PG_DATATYPE_NAME,
                        v_MESSAGE_TEXT        = MESSAGE_TEXT,
                        v_TABLE_NAME          = TABLE_NAME,
                        v_SCHEMA_NAME         = SCHEMA_NAME,
                        v_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                        v_PG_EXCEPTION_HINT   = PG_EXCEPTION_HINT,
                        v_PG_EXCEPTION_CONTEXT= PG_EXCEPTION_CONTEXT;
                
--                    SELECT INTO _errors json_build_object('errors', 
                    SELECT  INTO _errors json_build_object( 
                            'RETURNED_SQLSTATE' ,    v_RETURNED_SQLSTATE,
                            'COLUMN_NAME'       ,    v_COLUMN_NAME,
                            'CONSTRAINT_NAME'   ,    v_CONSTRAINT_NAME,
                            'PG_DATATYPE_NAME'  ,    v_PG_DATATYPE_NAME,
                            'MESSAGE_TEXT'      ,    v_MESSAGE_TEXT,
                            'TABLE_NAME'        ,    v_TABLE_NAME,
                            'SCHEMA_NAME'       ,    v_SCHEMA_NAME,
                            'PG_EXCEPTION_DETAI',    v_PG_EXCEPTION_DETAIL,
                            'PG_EXCEPTION_HINT' ,    v_PG_EXCEPTION_HINT,
                            'PG_EXCEPTION_CONTEXT' , v_PG_EXCEPTION_CONTEXT);
                    SELECT common.create_error_response ('error', _errors) INTO _result;
                    RETURN _result;
        END;
$$ LANGUAGE plpgsql;

select common.function_wrapper ('network.operator_get_all', NULL);

-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION network.network_insert (input json) RETURNS json AS $$
    DECLARE
        _code TEXT := (input::json->>'code');
        _name TEXT := (input::json->>'name');
        _result json;
        _id   BIGINT;
    BEGIN
        INSERT INTO network.network (code, name) VALUES (_code, _name) RETURNING id INTO _id;
        _result = json_build_object('id', _id);
        return _result;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- =========================================================
-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION network.operator_insert (input json) RETURNS json AS $$
    DECLARE
        _code TEXT := (input::json->>'code');
        _name TEXT := (input::json->>'name');
        _result json;
        _id   BIGINT;
    BEGIN
        INSERT INTO network.operator (code, name) VALUES (_code, _name) RETURNING id INTO _id;
        _result = json_build_object('id', _id);
        return _result;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- 
-- =========================================================
CREATE OR REPLACE FUNCTION network.operator_get_all () RETURNS json AS $$
    DECLARE
        _result json;
    BEGIN
        SELECT json_agg(t) FROM (select * from network.operator) t INTO _result;
        RETURN _result;
    END;
$$ LANGUAGE plpgsql;

--select network.operator_get_all ();
--select common.function_wrapper ('network.operator_get_all', '{}'::json);

-- =========================================================
-- =========================================================
-- =========================================================
-- example of the input:
--   {"operator_code": "NEX", "network_code": "EN", "trans_mode":"COACH", "country_iso2":"GB"} 
-- =========================================================
CREATE OR REPLACE FUNCTION network.operator_network_insert (input json) RETURNS json AS $$
    DECLARE
        v_trans_mode TEXT := input::json->>'trans_mode';
        v_country_iso2 TEXT := input::json->>'country_iso2';
        v_operator_code TEXT := input::json->>'operator_code';
        v_network_code TEXT := input::json->>'network_code';
        _id BIGINT;
        _result json;
    BEGIN
        -- function body here
	    INSERT INTO network.operator_network (operator_id, network_id, trans_mode, country_id) 
          VALUES     ((SELECT id FROM network.operator WHERE code=v_operator_code),
                     (SELECT id FROM network.network WHERE code=v_network_code), 
                     v_trans_mode::common.TRANSPORT_MODE, 
                     (SELECT id FROM reference.country WHERE iso2=v_country_iso2)) RETURNING id INTO _id;
        _result = json_build_object('id', _id);

        RETURN _result;
    END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- =========================================================
-- =========================================================
-- '{"name": "London Bristol", "public_code": "LBRRIS", "trans_mode": "COACH", "operator_code": "NEX"}'
-- =========================================================
CREATE OR REPLACE FUNCTION network.line_insert (input json) RETURNS text AS $$
    DECLARE
        v_name TEXT := input::json->>'name';
        v_public_code TEXT := input::json->>'public_code';
        v_trans_mode TEXT := input::json->>'trans_mode';
        v_operator_code TEXT := input::json->>'operator_code';
        _id BIGINT;
        _result json;
    BEGIN
        -- function body here
        INSERT INTO network.line (name, public_code, trans_mode, operator_id )
            VALUES (v_name, v_public_code, v_trans_mode::common.TRANSPORT_MODE, 
                    (SELECT id FROM network.operator WHERE code=v_operator_code)) RETURNING id INTO _id;
        _result = json_build_object('id', _id);

        RETURN _result;
    END;
$$ LANGUAGE plpgsql;

SELECT id FROM network.operator WHERE code='NEX';
-- =========================================================
-- =========================================================
-- =========================================================
-- {"code": "WMID", "name": "West Midlands"}'
-- =========================================================
CREATE OR REPLACE FUNCTION network.zone_insert (input json) RETURNS json AS $$
    DECLARE
        v_code TEXT := (input::json->>'code');
        v_name TEXT := (input::json->>'name');
        _result json;
        _id   BIGINT;
    BEGIN
        INSERT INTO network.zone (code, name) VALUES (v_code, v_name) RETURNING id INTO _id;
        _result = json_build_object('id', _id);
        return _result;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- =========================================================
-- =========================================================
-- {"code": "DGBT", "name": "Digbeth Coach Station", "type": "STATION", 
--  "zone_code":"WMID", "post_code":"B5 6DD", "geo": "POINT(-1.888361  52.475453)"}
-- =========================================================
CREATE OR REPLACE FUNCTION network.insert_stop (input json) RETURNS text AS $$
    DECLARE
        v_code TEXT := input::json->>'code';
        v_name TEXT := input::json->>'name';
        v_type TEXT := input::json->>'type';
        v_zone_code TEXT := input::json->>'zone_code';
        v_post_code TEXT := input::json->>'post_code';
        v_geo TEXT := input::json->>'geo';
        _result json;
        _id   BIGINT;
    BEGIN
        -- function body here
        INSERT INTO network.stop (code, name, type, zone_id, post_code, geo) 
            VALUES (v_code, v_name, v_type::common.STOP_TYPE, 
                   (SELECT id FROM network.zone WHERE code=v_zone_code),
                   v_post_code, v_geo::common.geography) RETURNING id INTO _id;
        _result = json_build_object('id', _id);
        return _result;
    END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- =========================================================
-- =========================================================
-- {"line_public_code":  "LONBIR", "code": "BRLO", "compass_direction": "S", 
--  "from_stop_code": "DGBT", "to_stop_code": "LOVC"}
-- =========================================================
CREATE OR REPLACE FUNCTION network.service_insert (input json) RETURNS text AS $$
    DECLARE
        v_line_public_code TEXT := input::json->>'line_public_code';
        v_code TEXT := input::json->>'code';
        v_compass_direction TEXT := input::json->>'compass_direction';
        v_from_stop_code TEXT := input::json->>'from_stop_code';
        v_to_stop_code TEXT := input::json->>'to_stop_code';
        _result json;
        _id   BIGINT;
    BEGIN
        -- function body here
        INSERT INTO network.service (line_id, code, compass_direction, from_stop_id, to_stop_id)
                VALUES ( (SELECT id FROM network.line WHERE public_code=v_line_public_code),
                        v_code, v_compass_direction::common.COMPASS_DIRECTION,
                        (select  id FROM network.stop WHERE code=v_from_stop_code),
                        (select  id FROM network.stop WHERE code=v_to_stop_code)) RETURNING id INTO _id;

        _result = json_build_object('id', _id);
        return _result;
    END;
$$ LANGUAGE plpgsql;


-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- some test data
-- =========================================================
ALTER ROLE postgres IN DATABASE transmodel SET search_path TO common;

SELECT common.function_wrapper ('network.network_insert', '{"code": "EN", "name": "England"}'::json);
SELECT common.function_wrapper ('network.network_insert', '{"code": "SC", "name": "Scotland"}'::json);

SELECT common.function_wrapper ('network.operator_insert', '{"code": "NEX", "name": "National Express"}'::json);
SELECT common.function_wrapper ('network.operator_insert', '{"code": "FLB", "name": "Flixbus"}'::json);
SELECT common.function_wrapper ('network.operator_insert', '{"code": "EXL", "name": "Express Leisure Coaches"}'::json);

SELECT common.function_wrapper ('network.operator_network_insert', 
        '{"operator_code": "NEX", "network_code": "EN", "trans_mode":"COACH", "country_iso2":"GB"}'::json);

SELECT common.function_wrapper ('network.line_insert', 
        '{"name": "London Bristol", "public_code": "LODBRS", "trans_mode": "COACH", "operator_code": "NEX"}'::json);
SELECT common.function_wrapper ('network.line_insert', 
        '{"name": "London Birmingham", "public_code": "LONBIR", "trans_mode": "COACH", "operator_code": "NEX"}'::json);


SELECT common.function_wrapper ('network.zone_insert', '{"code": "WMID", "name": "West Midlands"}'::json);
SELECT common.function_wrapper ('network.zone_insert', '{"code": "LON",  "name": "London"}'::json);

SELECT common.function_wrapper ('network.insert_stop', 
    '{"code": "DGBT", "name": "Digbeth Coach Station", "type": "STATION", "zone_code":"WMID", "post_code":"B5 6DD", "geo": "POINT(-1.888361  52.475453)"}'::json);
SELECT common.function_wrapper ('network.insert_stop', 
    '{"code": "LOVC", "name": "London Victoria Coach Station", "type": "STATION", "zone_code":"LON", "post_code":"SW1W 9TP", "geo": "POINT(-0.147694 51.492419)"}'::json);


SELECT common.function_wrapper ('network.service_insert', 
        '{"line_public_code":  "LONBIR", "code": "BRLO", "compass_direction": "S", "from_stop_code": "DGBT", "to_stop_code": "LOVC"}');
SELECT common.function_wrapper ('network.service_insert', 
        '{"line_public_code":  "LONBIR", "code": "BRLO", "compass_direction": "N", "from_stop_code": "LOVC", "to_stop_code": "DGBT"}');


-- =========================================================
-- =========================================================


-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- =========================================================
-- Mapping to GTFS & NeTEx
--GTFS Mapping
--GTFS Table	This Schema
--agency	operator
--stop	stop_place
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
--D. Nearest stop (PostGIS)
--sql
--Copy code
--SELECT id, name
--FROM stop_place
--ORDER BY geo_position <-> ST_MakePoint(:lon, :lat)::common.geography
--LIMIT 5;



