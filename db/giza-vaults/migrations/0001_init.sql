DO $$ BEGIN
  CREATE TYPE action_type_enum AS ENUM ('deposit','withdraw','transfer');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_enum AS ENUM ('pending','completed','failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS vaults (
  vault_id         BIGSERIAL PRIMARY KEY,
  chain_id         TEXT NOT NULL,
  factory_address  TEXT NOT NULL,
  vault_address    TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL,
  created_block    BIGINT,
  CONSTRAINT uq_vault UNIQUE (chain_id, vault_address)
);

CREATE TABLE IF NOT EXISTS users (
  user_id        BIGSERIAL PRIMARY KEY,
  wallet_address TEXT NOT NULL UNIQUE,
  first_seen_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_vaults (
  id         BIGSERIAL PRIMARY KEY,
  vault_id   BIGINT NOT NULL REFERENCES vaults(vault_id) ON DELETE CASCADE,
  user_id    BIGINT NOT NULL REFERENCES users(user_id)  ON DELETE CASCADE,
  linked_at  TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT uq_user_vault UNIQUE (vault_id, user_id)
);

CREATE TABLE IF NOT EXISTS executions (
  execution_id       BIGSERIAL PRIMARY KEY,
  vault_id           BIGINT NOT NULL REFERENCES vaults(vault_id) ON DELETE CASCADE,
  action_type        action_type_enum NOT NULL,
  status             status_enum NOT NULL,
  asset_symbol       TEXT,
  asset_address      TEXT,
  asset_decimals     INT,
  amount_asset       NUMERIC(78, 0),          -- raw units (no decimals)
  amount_usd         NUMERIC(38, 10),         -- normalized USD value
  from_protocol      TEXT,
  to_protocol        TEXT,
  apy_at_execution   NUMERIC(10, 6),
  tx_hash            TEXT NOT NULL,
  timestamp          TIMESTAMPTZ NOT NULL,
  block_number       BIGINT,
  CONSTRAINT uq_tx UNIQUE (tx_hash, vault_id),
  CONSTRAINT ck_transfer_requires_to CHECK (
    (action_type <> 'transfer') OR (to_protocol IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS ix_vaults_factory ON vaults(factory_address);
CREATE INDEX IF NOT EXISTS ix_vaults_chain_addr ON vaults(chain_id, vault_address);
CREATE INDEX IF NOT EXISTS ix_uv_user ON user_vaults(user_id);
CREATE INDEX IF NOT EXISTS ix_uv_vault ON user_vaults(vault_id);
CREATE INDEX IF NOT EXISTS ix_exec_vault_time ON executions(vault_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS ix_exec_status ON executions(status);
CREATE INDEX IF NOT EXISTS ix_exec_protocol ON executions((COALESCE(to_protocol, from_protocol)));
CREATE INDEX IF NOT EXISTS ix_exec_asset ON executions(asset_symbol);
