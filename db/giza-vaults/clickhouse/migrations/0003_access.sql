-- Enable RBAC if not already enabled via env: CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1


-- Roles
CREATE ROLE IF NOT EXISTS etl_writer;
CREATE ROLE IF NOT EXISTS api_reader;


-- Users (no passwords here; set in ops file)
CREATE USER IF NOT EXISTS etl_svc;
CREATE USER IF NOT EXISTS api_svc;


-- Grants
GRANT INSERT, SELECT ON giza.executions TO etl_writer;
GRANT INSERT, SELECT ON giza.vaults TO etl_writer;
GRANT INSERT, SELECT ON giza.users TO etl_writer;
GRANT INSERT, SELECT ON giza.user_vaults TO etl_writer;


GRANT SELECT ON giza.v_agent_tx_history TO api_reader;
GRANT SELECT ON giza.v_user_agg_30d TO api_reader;


GRANT etl_writer TO etl_svc;
GRANT api_reader TO api_svc;