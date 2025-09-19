/* 1) Create generic namespace */
CREATE DATABASE IF NOT EXISTS agents;

/* ---------- Core tables (agent-agnostic) ---------- */
CREATE TABLE IF NOT EXISTS agents.agents
(
  agent_id        String,
  agent_name      String,
  model_type      LowCardinality(String),
  owner_address   String,
  deployment_date Date,
  website         String,
  category        LowCardinality(String),
  tags            Array(String),
  status          LowCardinality(String),
  chain_ids       Array(String),
  ingest_ts       DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
ORDER BY (agent_id);

CREATE TABLE IF NOT EXISTS agents.vaults
(
  chain_id        LowCardinality(String),
  factory_address String,
  vault_address   String,
  created_at      DateTime64(3, 'UTC'),
  created_block   UInt64,
  ingest_ts       DateTime DEFAULT now()
)
ENGINE = MergeTree
PARTITION BY (chain_id)
ORDER BY (chain_id, vault_address);

CREATE TABLE IF NOT EXISTS agents.user_vaults
(
  chain_id       LowCardinality(String),
  vault_address  String,
  wallet_address String,
  linked_at      DateTime64(3, 'UTC') DEFAULT now(),
  ingest_ts      DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id)
ORDER BY (chain_id, vault_address, wallet_address);

CREATE TABLE IF NOT EXISTS agents.agent_vaults
(
  chain_id      LowCardinality(String),
  vault_address String,
  agent_id      String,
  agent_name    String,
  linked_at     DateTime64(3, 'UTC') DEFAULT now(),
  ingest_ts     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id)
ORDER BY (chain_id, vault_address, agent_id);

/* Canonical events (already extended for trading & “every record” fields) */
CREATE TABLE IF NOT EXISTS agents.executions
(
  chain_id         LowCardinality(String),
  agent_name       LowCardinality(String),
  vault_address    String,

  tx_hash          String,
  log_index        UInt16 DEFAULT 0,
  block_number     UInt64,
  timestamp        DateTime64(3, 'UTC'),
  block_timestamp  DateTime64(3, 'UTC') DEFAULT timestamp,

  action_type      LowCardinality(String),
  status           Enum8('completed' = 1, 'failed' = 2, 'pending' = 3),

  asset_symbol     LowCardinality(String),
  asset_address    String,
  asset_decimals   UInt8,
  amount_asset     Decimal128(18),
  amount_usd       Decimal128(6),
  price_usd        Decimal128(6) DEFAULT 0,
  fee_usd          Decimal128(6) DEFAULT 0,
  realized_pnl_usd Decimal128(6) DEFAULT 0,

  protocol         LowCardinality(String),
  from_protocol    LowCardinality(String),
  to_protocol      LowCardinality(String),
  exchange         LowCardinality(String) DEFAULT '',

  apy_at_execution Float64,
  ingest_ts        DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), vault_address, tx_hash, log_index)
SETTINGS index_granularity = 8192;

/* Flattened serving table (“one big table” reads) */
CREATE TABLE IF NOT EXISTS agents.executions_flat
(
  chain_id         LowCardinality(String),
  agent_name       LowCardinality(String),
  vault_address    String,
  wallet_address   String,

  tx_hash          String,
  log_index        UInt16,
  block_number     UInt64,
  timestamp        DateTime64(3, 'UTC'),
  block_timestamp  DateTime64(3, 'UTC'),

  action_type      LowCardinality(String),
  status           LowCardinality(String),
  asset_symbol     LowCardinality(String),
  asset_address    String,
  asset_decimals   UInt8,
  amount_asset     Decimal128(18),
  amount_usd       Decimal128(6),
  price_usd        Decimal128(6),
  fee_usd          Decimal128(6),
  realized_pnl_usd Decimal128(6),
  protocol         LowCardinality(String),
  from_protocol    LowCardinality(String),
  to_protocol      LowCardinality(String),
  exchange         LowCardinality(String),
  apy_at_execution Float64,

  ingest_ts        DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), wallet_address, vault_address, tx_hash, log_index);

/* Materialized view in the new namespace */
CREATE MATERIALIZED VIEW IF NOT EXISTS agents.mv_executions_to_flat
TO agents.executions_flat
AS
SELECT
  e.chain_id,
  av.agent_name,
  e.vault_address,
  uv.wallet_address,

  e.tx_hash,
  e.log_index,
  e.block_number,
  e.timestamp,
  e.block_timestamp,

  e.action_type,
  CAST(e.status AS String) AS status,
  e.asset_symbol,
  e.asset_address,
  e.asset_decimals,
  e.amount_asset,
  e.amount_usd,
  e.price_usd,
  e.fee_usd,
  e.realized_pnl_usd,
  e.protocol,
  e.from_protocol,
  e.to_protocol,
  e.exchange,
  e.apy_at_execution,

  e.ingest_ts
FROM agents.executions AS e
LEFT ANY JOIN agents.user_vaults AS uv
  ON uv.chain_id = e.chain_id AND uv.vault_address = e.vault_address
LEFT ANY JOIN agents.agent_vaults AS av
  ON av.chain_id = e.chain_id AND av.vault_address = e.vault_address;

/* Generic API view */
CREATE OR REPLACE VIEW agents.v_tx_history AS
SELECT
  chain_id,
  agent_name,
  vault_address,
  wallet_address,
  timestamp,
  block_timestamp,
  action_type,
  status,
  asset_symbol,
  asset_address,
  asset_decimals,
  amount_asset,
  amount_usd,
  price_usd,
  fee_usd,
  realized_pnl_usd,
  protocol,
  from_protocol,
  to_protocol,
  exchange,
  apy_at_execution,
  tx_hash,
  block_number,
  log_index
FROM agents.executions_flat;

/* ---------- Daily rollup tables (agent-agnostic) ---------- */
CREATE TABLE IF NOT EXISTS agents.agent_identity_daily
(
  agent_id      String,
  agent_name    String,
  asof_date     Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  asset_under_management Decimal128(6) DEFAULT 0,
  website       String,
  category      LowCardinality(String),
  tags          Array(String),
  status        LowCardinality(String),
  chain_ids     Array(String),
  ingest_ts     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.agent_contracts_daily
(
  agent_id      String,
  agent_name    String,
  chain_id      LowCardinality(String),
  asof_date     Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  primary_contracts  Array(String),
  share_token        String,
  underlying_tokens  Array(String),
  is_erc4626         UInt8,
  proxy_address      String,
  implementation_address String,
  start_block        UInt64,
  first_deploy_ts    DateTime64(3, 'UTC'),
  ingest_ts          DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.agent_users_daily
(
  agent_id      String,
  agent_name    String,
  chain_id      LowCardinality(String),
  asof_date     Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  unique_depositors_cumulative UInt64,
  unique_depositors_30d        UInt64,
  active_wallets_30d           UInt64,
  ingest_ts     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.strategies_daily
(
  agent_id      String,
  agent_name    String,
  chain_id      LowCardinality(String),
  asof_date     Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  strategy_id   String,
  protocol_name LowCardinality(String),
  asset_pairs   Array(String),
  status        LowCardinality(String),
  ingest_ts     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id, strategy_id);

CREATE TABLE IF NOT EXISTS agents.asset_daily
(
  agent_id    String,
  agent_name  String,
  chain_id    LowCardinality(String),
  asof_date   Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  tvl_usd     Decimal128(6),
  total_shares Decimal128(18),
  total_assets Decimal128(18),
  ingest_ts   DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.chain_total_tvl_daily
(
  chain_id  LowCardinality(String),
  asof_date Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  tvl_usd   Decimal128(6),
  ingest_ts DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date, chain_id);

CREATE TABLE IF NOT EXISTS agents.chain_total_deployed_agents_daily
(
  chain_id  LowCardinality(String),
  asof_date Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  total_agents UInt64,
  ingest_ts DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date, chain_id);

CREATE TABLE IF NOT EXISTS agents.deployed_agents_on_project_daily
(
  chain_id  LowCardinality(String),
  agent_name String,
  asof_date Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  deployed_agents_count UInt64,
  ingest_ts DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date, chain_id, agent_name);

CREATE TABLE IF NOT EXISTS agents.exec_stats_daily
(
  agent_id   String,
  agent_name String,
  chain_id   LowCardinality(String),
  asof_date  Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  success_calls UInt64,
  failed_calls  UInt64,
  ingest_ts  DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.returns_daily
(
  agent_id   String,
  agent_name String,
  chain_id   LowCardinality(String),
  asof_date  Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  ret_pct    Float64,
  ingest_ts  DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.riskfree_daily
(
  chain_id   LowCardinality(String),
  asof_date  Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  rf_rate_daily Float64,
  ingest_ts  DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date, chain_id);

CREATE TABLE IF NOT EXISTS agents.loss_events
(
  agent_id   String,
  agent_name String,
  chain_id   LowCardinality(String),
  ts         DateTime64(3, 'UTC'),
  asof_date  Date DEFAULT toDate(ts, 'UTC'),
  value_before_usd Decimal128(6),
  value_after_usd  Decimal128(6),
  loss_pct   Float64,
  tx_hash    String DEFAULT '',
  ingest_ts  DateTime DEFAULT now()
)
ENGINE = MergeTree
PARTITION BY (chain_id, toYYYYMM(ts))
ORDER BY (chain_id, toDate(ts), agent_id, ts);

CREATE TABLE IF NOT EXISTS agents.tvl_ledger_daily
(
  agent_id   String,
  agent_name String,
  chain_id   LowCardinality(String),
  asof_date  Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  tvl_usd_today         Decimal128(6),
  lifetime_deposits_usd Decimal128(6),
  ingest_ts  DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id);

CREATE TABLE IF NOT EXISTS agents.holdings_daily
(
  agent_id     String,
  agent_name   String,
  chain_id     LowCardinality(String),
  asof_date    Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  token_address String,
  token_symbol  LowCardinality(String) DEFAULT '',
  token_decimals UInt8 DEFAULT 18,
  balance       Decimal128(18),
  usd_value     Decimal128(6),
  ingest_ts     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, agent_id, token_address);

CREATE TABLE IF NOT EXISTS agents.pools_depth_daily
(
  chain_id     LowCardinality(String),
  asof_date    Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  pool_address String,
  token0       String,
  token1       String,
  reserve0     Decimal128(18),
  reserve1     Decimal128(18),
  depth_1pct_usd Decimal128(6),
  ingest_ts    DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(asof_date))
ORDER BY (chain_id, asof_date, pool_address);

CREATE TABLE IF NOT EXISTS agents.sentiment_daily
(
  asof_date    Date,
  block_timestamp DateTime64(3, 'UTC') DEFAULT now(),
  project_handles Array(String),
  contract_addresses Array(String),
  sentiment_avg  Float64,
  volume         Float64,
  criticism_severity Float64,
  reputation_mentions UInt64,
  ingest_ts      DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(asof_date)
ORDER BY (asof_date);

/* ---------- Copy data from old namespace (if present) ---------- */
INSERT INTO agents.vaults        SELECT * FROM giza.vaults;
INSERT INTO agents.user_vaults   SELECT * FROM giza.user_vaults;
INSERT INTO agents.agent_vaults  SELECT * FROM giza.agent_vaults;
INSERT INTO agents.executions    SELECT * FROM giza.executions;
INSERT INTO agents.executions_flat SELECT * FROM giza.executions_flat;

INSERT INTO agents.agent_identity_daily            SELECT * FROM giza.agent_identity_daily;
INSERT INTO agents.agent_contracts_daily           SELECT * FROM giza.agent_contracts_daily;
INSERT INTO agents.agent_users_daily               SELECT * FROM giza.agent_users_daily;
INSERT INTO agents.strategies_daily                SELECT * FROM giza.strategies_daily;
INSERT INTO agents.asset_daily                     SELECT * FROM giza.asset_daily;
INSERT INTO agents.chain_total_tvl_daily           SELECT * FROM giza.chain_total_tvl_daily;
INSERT INTO agents.chain_total_deployed_agents_daily SELECT * FROM giza.chain_total_deployed_agents_daily;
INSERT INTO agents.deployed_agents_on_project_daily  SELECT * FROM giza.deployed_agents_on_project_daily;
INSERT INTO agents.exec_stats_daily                SELECT * FROM giza.exec_stats_daily;
INSERT INTO agents.returns_daily                   SELECT * FROM giza.returns_daily;
INSERT INTO agents.riskfree_daily                  SELECT * FROM giza.riskfree_daily;
INSERT INTO agents.loss_events                     SELECT * FROM giza.loss_events;
INSERT INTO agents.tvl_ledger_daily                SELECT * FROM giza.tvl_ledger_daily;
INSERT INTO agents.holdings_daily                  SELECT * FROM giza.holdings_daily;
INSERT INTO agents.pools_depth_daily               SELECT * FROM giza.pools_depth_daily;
INSERT INTO agents.sentiment_daily                 SELECT * FROM giza.sentiment_daily;

/* ---------- Generic API view alias for convenience ---------- */
CREATE OR REPLACE VIEW agents.v_agent_tx_history AS
SELECT * FROM agents.v_tx_history;
