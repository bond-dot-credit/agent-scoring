/* ---------- Minimal schema for demo ---------- */
CREATE DATABASE IF NOT EXISTS agents;
CREATE DATABASE IF NOT EXISTS giza;

CREATE TABLE IF NOT EXISTS agents.executions
(
  chain_id LowCardinality(String),
  agent_name LowCardinality(String),
  vault_address String,

  tx_hash String,
  log_index UInt16 DEFAULT 0,
  block_number UInt64 DEFAULT 0,
  timestamp DateTime DEFAULT now(),
  block_timestamp DateTime DEFAULT timestamp,

  action_type LowCardinality(String),
  status LowCardinality(String),

  asset_symbol LowCardinality(String),
  asset_address String,
  asset_decimals UInt8 DEFAULT 18,
  amount_asset Decimal(38,18) DEFAULT 0,
  amount_usd   Decimal(38,6)  DEFAULT 0,
  price_usd    Decimal(38,6)  DEFAULT 0,
  fee_usd      Decimal(38,6)  DEFAULT 0,
  realized_pnl_usd Decimal(38,6) DEFAULT 0,

  protocol LowCardinality(String),
  from_protocol LowCardinality(String),
  to_protocol LowCardinality(String),
  exchange LowCardinality(String),

  apy_at_execution Float64 DEFAULT 0,
  ingest_ts DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), vault_address, tx_hash, log_index);

/* View the app/API will query */
CREATE OR REPLACE VIEW agents.v_tx_history AS
SELECT
  chain_id, agent_name, vault_address,
  tx_hash, log_index, block_number,
  timestamp, block_timestamp,
  action_type, status,
  asset_symbol, asset_address, asset_decimals,
  amount_asset, amount_usd, price_usd, fee_usd, realized_pnl_usd,
  protocol, from_protocol, to_protocol, exchange,
  apy_at_execution
FROM agents.executions;

/* Back-compat alias (so old code using giza.v_agent_tx_history still works) */
CREATE OR REPLACE VIEW giza.v_agent_tx_history AS
SELECT * FROM agents.v_tx_history;
