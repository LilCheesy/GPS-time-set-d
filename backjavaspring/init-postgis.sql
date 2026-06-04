-- Initialize PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Create medical_facilities table
CREATE TABLE IF NOT EXISTS medical_facilities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    facility_type VARCHAR(50),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Create index for spatial queries
CREATE INDEX IF NOT EXISTS idx_facility_location ON medical_facilities USING GIST(location);

-- Create user_home_profiles table
CREATE TABLE IF NOT EXISTS user_home_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    address_label VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    home_location GEOMETRY(Point, 4326) NOT NULL,
    floor_number VARCHAR(20),
    room_number VARCHAR(20),
    is_primary_home BOOLEAN DEFAULT true
);

-- Create indexes for user_home_profiles
CREATE INDEX IF NOT EXISTS idx_home_user ON user_home_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_home_location ON user_home_profiles USING GIST(home_location);

-- Insert sample medical facilities (around Ho Chi Minh City)
INSERT INTO medical_facilities (name, address, phone, facility_type, latitude, longitude, location, is_active)
VALUES
    ('Benh vien Tu Du', '125 Cong Quynh, Q.1', '02838400752', 'benh vien', 10.7625, 106.6825, ST_SetSRID(ST_MakePoint(106.6825, 10.7625), 4326), true),
    ('Benh vien Nhan dan Gia Dinh', '1 Tran Que Y, Q.1', '02838403322', 'benh vien', 10.7689, 106.6892, ST_SetSRID(ST_MakePoint(106.6892, 10.7689), 4326), true),
    ('Benh vien Cho Ray', '201B Nguyen Chi Thanh, Q.5', '02838355481', 'benh vien', 10.7453, 106.6659, ST_SetSRID(ST_MakePoint(106.6659, 10.7453), 4326), true),
    ('Phong kham Da Khoa Saigon', '90 Nguyen Trai, Q.1', '02843821111', 'phong kham', 10.7645, 106.6833, ST_SetSRID(ST_MakePoint(106.6833, 10.7645), 4326), true),
    ('Benh vien 115 TPHCM', '121B Dien Bien Phu, Q.1', '02837226666', 'benh vien', 10.7833, 106.6917, ST_SetSRID(ST_MakePoint(106.6917, 10.7833), 4326), true);

-- Insert sample user home profile
INSERT INTO user_home_profiles (user_id, address_label, latitude, longitude, home_location, floor_number, room_number, is_primary_home)
VALUES
    (1, 'Nha rieng', 10.776889, 106.701116, ST_SetSRID(ST_MakePoint(106.701116, 10.776889), 4326), 'Tang 5', 'Phong 501', true);
