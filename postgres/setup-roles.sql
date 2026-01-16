-- Supabase user migration script
-- Creates missing users required by Supabase services

-- Create roles if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'fc1c9eb6125a7f3f79d9a9681f734ad5' NOINHERIT CREATEROLE;
        RAISE NOTICE 'Created role: supabase_auth_admin';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'fc1c9eb6125a7f3f79d9a9681f734ad5' NOINHERIT;
        RAISE NOTICE 'Created role: supabase_storage_admin';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
        CREATE ROLE supabase_functions_admin WITH LOGIN PASSWORD 'fc1c9eb6125a7f3f79d9a9681f734ad5' NOINHERIT;
        RAISE NOTICE 'Created role: supabase_functions_admin';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
        CREATE ROLE authenticator WITH LOGIN PASSWORD 'fc1c9eb6125a7f3f79d9a9681f734ad5' NOINHERIT;
        RAISE NOTICE 'Created role: authenticator';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pgbouncer') THEN
        CREATE ROLE pgbouncer WITH LOGIN PASSWORD 'fc1c9eb6125a7f3f79d9a9681f734ad5';
        RAISE NOTICE 'Created role: pgbouncer';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: anon';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: authenticated';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
        RAISE NOTICE 'Created role: service_role';
    END IF;
END
$$;

-- Grant role memberships
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;
GRANT service_role TO authenticator;

-- Create schemas if not exist
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION supabase_storage_admin;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Grant schema usage
GRANT USAGE ON SCHEMA auth TO supabase_auth_admin, postgres;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin, postgres;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT USAGE ON SCHEMA extensions TO public;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

SELECT 'Supabase roles setup completed!' as status;
