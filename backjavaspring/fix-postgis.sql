-- Fix: Enable PostGIS extension on Windows PostgreSQL
-- Run this in pgAdmin or psql against database: gps_demo

-- Enable PostGIS (required for geometry type)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify installation
SELECT PostGIS_Version();

-- Expected output: e.g. "3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1"


