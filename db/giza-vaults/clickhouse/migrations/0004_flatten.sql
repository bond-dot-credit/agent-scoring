-- 1) Target flattened table (the “one giant table” you query)
CREATE TABLE IF NOT EXISTS giza.executions_flat
(
  chain_id         LowCardinality(String),
  vault_address    String,
  wallet_address   String,                -- admin/user mapped at insert time

  tx_hash          String,
  log_index        UInt16,
  block_number     UInt64,
  timestamp        DateTime64(3, 'UTC'),

  action_type      LowCardinality(String),
  status           LowCardinality(String),-- keep as string here for simpler tooling
  asset_symbol     LowCardinality(String),
  asset_address    String,
  asset_decimals   UInt8,
  amount_asset     Decimal128(18),
  amount_usd       Decimal128(6),
  protocol         LowCardinality(String),
  from_protocol    LowCardinality(String),
  to_protocol      LowCardinality(String),
  apy_at_execution Float64,

  ingest_ts        DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY (chain_id, toYYYYMM(timestamp))
ORDER BY (chain_id, toDate(timestamp), wallet_address, vault_address, tx_hash, log_index);

-- 2) Materialized view: on every INSERT into executions, populate executions_flat
--    ANY LEFT JOIN chooses one admin if multiple exist (most vaults have few admins).
--    If you need *all* admins, we can switch to an explode approach later.
CREATE MATERIALIZED VIEW IF NOT EXISTS giza.mv_executions_to_flat
TO giza.executions_flat
AS
SELECT
  e.chain_id,
  e.vault_address,
  uv.wallet_address,

  e.tx_hash,
  e.log_index,
  e.block_number,
  e.timestamp,

  e.action_type,
  CAST(e.status AS String) AS status,
  e.asset_symbol,
  e.asset_address,
  e.asset_decimals,
  e.amount_asset,
  e.amount_usd,
  e.protocol,
  e.from_protocol,
  e.to_protocol,
  e.apy_at_execution,

  e.ingest_ts
FROM giza.executions AS e
LEFT ANY JOIN giza.user_vaults AS uv
  ON uv.chain_id = e.chain_id AND uv.vault_address = e.vault_address;

-- 3) Backfill existing data once (safe to re-run: ReplacingMergeTree dedupes on ORDER BY)
INSERT INTO giza.executions_flat
SELECT
  e.chain_id,
  e.vault_address,
  uv.wallet_address,

  e.tx_hash,
  e.log_index,
  e.block_number,
  e.timestamp,

  e.action_type,
  CAST(e.status AS String) AS status,
  e.asset_symbol,
  e.asset_address,
  e.asset_decimals,
  e.amount_asset,
  e.amount_usd,
  e.protocol,
  e.from_protocol,
  e.to_protocol,
  e.apy_at_execution,

  e.ingest_ts
FROM giza.executions AS e
LEFT ANY JOIN giza.user_vaults AS uv
  ON uv.chain_id = e.chain_id AND uv.vault_address = e.vault_address;
