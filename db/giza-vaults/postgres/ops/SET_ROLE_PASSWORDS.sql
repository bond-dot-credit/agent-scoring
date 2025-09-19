-- TEMPLATE ONLY. Copy this to ops/SET_ROLE_PASSWORDS.sql (DO NOT COMMIT THAT COPY).
-- Replace the placeholders with real passwords and run once per environment.

ALTER ROLE etl_writer WITH PASSWORD 'bond.credit';
ALTER ROLE api_reader WITH PASSWORD 'bond.credit';
