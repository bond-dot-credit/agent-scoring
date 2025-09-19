/* ============================================================
   Bond.Credit — Agents scoring core schema for ClickHouse
   One big fact table (executions) + small helper tables + views
   ============================================================ */

CREATE DATABASE IF NOT EXISTS agents;
CREATE DATABASE IF NOT EXISTS giza;

/* --------- Helper/lookup tables (optional but useful) --------- */

CREATE TABLE IF NOT EXISTS agents.agents
(
  agent_id       String,                         -- e.g. 'giza' or a UUID
  agent_name     LowCardinality(String),         -- display name
  model_type     LowCardinality(String) DEFAULT '',  -- optional (llm/tooling/etc)
  owner_wallet   String DEFAULT '',
  created_at     DateTime DEFAULT now()
)
ENGINE = MergeTree
ORDER BY (agent_id);

CREATE TABLE IF NOT EXISTS agents.vaults
(
  chain_id       LowCardinality(String),
  vault_address  String,
  factory_address String DEFAULT '',
  created_at     DateTime DEFAULT now(),
  created_block  UInt64  DEFAULT 0
)
ENGINE = MergeTree
ORDER BY (chain_id, vault_address);

CREATE TABLE IF NOT EXISTS agents.wallets
(
  wallet_address String,
  first_seen_at  DateTime DEFAULT now()
)
ENGINE = MergeTree
ORDER BY (wallet_address);

CREATE TABLE IF NOT EXISTS agents.user_vaults
(
  chain_id       LowCardinality(String),
  vault_address  String,
  wallet_address String,
  role           LowCardinality(String) DEFAULT 'admin',  -- e.g. admin/viewer
  linked_at      DateTime DEFAULT now(),
  ingest_ts      DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id)
ORDER BY (chain_id, vault_address, wallet_address);


/* ---------------------- FACT: executions ----------------------
   This is the “one big table” most queries will read.
   Both AMA (ARMA) and subgraphs should insert into this.
   Use consistent column names across sources.
   ------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS agents.executions
(
  /* identity */
  chain_id            LowCardinality(String),
  agent_name          LowCardinality(String),      -- 'giza' etc.
  vault_address       String,

  /* tx identity */
  tx_hash             String,
  log_index           UInt32  DEFAULT 0,           -- synthetic fallback if source lacks logIndex
  block_number        UInt64  DEFAULT 0,
  timestamp           DateTime DEFAULT now(),      -- execution time
  block_timestamp     DateTime DEFAULT timestamp,

  /* action & status */
  action_type         LowCardinality(String),      -- deposit/withdraw/transfer
  status              LowCardinality(String),      -- completed/failed/pending

  /* asset */
  asset_symbol        LowCardinality(String),
  asset_address       String,
  asset_decimals      UInt8   DEFAULT 18,
  amount_asset        Decimal(38,18) DEFAULT 0,    -- normalized using decimals
  amount_usd          Decimal(38,6)  DEFAULT 0,
  price_usd           Decimal(38,6)  DEFAULT 0,

  /* costs & pnl (optional) */
  fee_usd             Decimal(38,6)  DEFAULT 0,
  realized_pnl_usd    Decimal(38,6)  DEFAULT 0,

  /* routing / protocol */
  protocol            LowCardinality(String) DEFAULT '',
  from_protocol       LowCardinality(String) DEFAULT '',
  to_protocol         LowCardinality(String) DEFAULT '',
  exchange            LowCardinality(String) DEFAULT '',

  /* yield point-in-time */
  apy_at_execution    Float64 DEFAULT 0,

  /* provenance */
  source              LowCardinality(String) DEFAULT 'unknown',  -- 'ama','subgraph','onchain'
  ingest_ts           DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), vault_address, tx_hash, log_index)
SETTINGS index_granularity = 8192;

/* --------------------------- Views --------------------------- */

CREATE OR REPLACE VIEW agents.v_tx_history AS
SELECT
  chain_id, agent_name, vault_address,
  tx_hash, log_index, block_number,
  timestamp, block_timestamp,
  action_type, status,
  asset_symbol, asset_address, asset_decimals,
  amount_asset, amount_usd, price_usd, fee_usd, realized_pnl_usd,
  protocol, from_protocol, to_protocol, exchange,
  apy_at_execution,
  source
FROM agents.executions;

/* Back-compat view for any legacy code that expects giza.* */
CREATE OR REPLACE VIEW giza.v_agent_tx_history AS
SELECT * FROM agents.v_tx_history;
