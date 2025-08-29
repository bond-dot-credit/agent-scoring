-- Create DB (idempotent)
CREATE DATABASE IF NOT EXISTS giza;

-- ============ Dimension-ish tables (natural keys) ============

CREATE TABLE IF NOT EXISTS giza.vaults
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

CREATE TABLE IF NOT EXISTS giza.users
(
  wallet_address String,
  first_seen_at  DateTime64(3, 'UTC') DEFAULT now(),
  ingest_ts      DateTime DEFAULT now()
)
ENGINE = MergeTree
ORDER BY (wallet_address);

CREATE TABLE IF NOT EXISTS giza.user_vaults
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

-- ============ Fact: executions (atomic actions) ============

CREATE TABLE IF NOT EXISTS giza.executions
(
  chain_id         LowCardinality(String),
  vault_address    String,

  -- tx identity
  tx_hash          String,
  log_index        UInt16 DEFAULT 0,
  block_number     UInt64,
  timestamp        DateTime64(3, 'UTC'),

  -- action & status
  action_type      LowCardinality(String),   -- deposit/withdraw/transfer
  status           Enum8('completed' = 1, 'failed' = 2, 'pending' = 3),

  -- asset & amounts
  asset_symbol     LowCardinality(String),
  asset_address    String,
  asset_decimals   UInt8,
  amount_asset     Decimal128(18),           -- token units
  amount_usd       Decimal128(6),            -- USD value at exec time

  -- protocols / routing
  protocol         LowCardinality(String),
  from_protocol    LowCardinality(String),
  to_protocol      LowCardinality(String),

  -- meta
  apy_at_execution Float64,
  ingest_ts        DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), vault_address, tx_hash, log_index)
SETTINGS index_granularity = 8192;
