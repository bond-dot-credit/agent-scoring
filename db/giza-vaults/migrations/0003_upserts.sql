CREATE OR REPLACE FUNCTION upsert_vault(
  p_chain_id TEXT,
  p_factory_address TEXT,
  p_vault_address TEXT,
  p_created_at TIMESTAMPTZ,
  p_created_block BIGINT
) RETURNS BIGINT AS $$
DECLARE vid BIGINT;
BEGIN
  INSERT INTO vaults(chain_id, factory_address, vault_address, created_at, created_block)
  VALUES (p_chain_id, p_factory_address, p_vault_address, p_created_at, p_created_block)
  ON CONFLICT (chain_id, vault_address)
  DO UPDATE SET factory_address = EXCLUDED.factory_address,
                created_at = LEAST(vaults.created_at, EXCLUDED.created_at),
                created_block = COALESCE(vaults.created_block, EXCLUDED.created_block)
  RETURNING vault_id INTO vid;
  RETURN vid;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upsert_user(p_wallet TEXT) RETURNS BIGINT AS $$
DECLARE uid BIGINT;
BEGIN
  INSERT INTO users(wallet_address) VALUES (p_wallet)
  ON CONFLICT (wallet_address) DO NOTHING;
  SELECT user_id INTO uid FROM users WHERE wallet_address = p_wallet;
  RETURN uid;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION link_user_vault(p_vault_id BIGINT, p_user_id BIGINT) RETURNS VOID AS $$
BEGIN
  INSERT INTO user_vaults(vault_id, user_id) VALUES (p_vault_id, p_user_id)
  ON CONFLICT (vault_id, user_id) DO NOTHING;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upsert_execution(
  p_vault_id BIGINT,
  p_action action_type_enum,
  p_status status_enum,
  p_asset_symbol TEXT,
  p_asset_address TEXT,
  p_asset_decimals INT,
  p_amount_asset NUMERIC,
  p_amount_usd NUMERIC,
  p_from_protocol TEXT,
  p_to_protocol TEXT,
  p_apy NUMERIC,
  p_tx_hash TEXT,
  p_timestamp TIMESTAMPTZ,
  p_block BIGINT
) RETURNS BIGINT AS $$
DECLARE eid BIGINT;
BEGIN
  INSERT INTO executions(
    vault_id, action_type, status, asset_symbol, asset_address, asset_decimals,
    amount_asset, amount_usd, from_protocol, to_protocol, apy_at_execution,
    tx_hash, timestamp, block_number
  ) VALUES (
    p_vault_id, p_action, p_status, p_asset_symbol, p_asset_address, p_asset_decimals,
    p_amount_asset, p_amount_usd, p_from_protocol, p_to_protocol, p_apy,
    p_tx_hash, p_timestamp, p_block
  )
  ON CONFLICT (tx_hash, vault_id)
  DO UPDATE SET status = EXCLUDED.status,
                amount_usd = COALESCE(EXCLUDED.amount_usd, executions.amount_usd),
                apy_at_execution = COALESCE(EXCLUDED.apy_at_execution, executions.apy_at_execution),
                block_number = COALESCE(EXCLUDED.block_number, executions.block_number),
                timestamp = LEAST(executions.timestamp, EXCLUDED.timestamp)
  RETURNING execution_id INTO eid;
  RETURN eid;
END; $$ LANGUAGE plpgsql;
