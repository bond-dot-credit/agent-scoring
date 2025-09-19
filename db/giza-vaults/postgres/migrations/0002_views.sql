CREATE OR REPLACE VIEW v_vaults_from_factory AS
SELECT chain_id, factory_address, vault_address, created_at, created_block, vault_id
FROM vaults;

CREATE OR REPLACE VIEW v_vault_user_associations AS
SELECT v.vault_id, v.chain_id, v.vault_address, u.user_id, u.wallet_address, uv.linked_at
FROM user_vaults uv
JOIN users u  ON u.user_id  = uv.user_id
JOIN vaults v ON v.vault_id = uv.vault_id;

CREATE OR REPLACE VIEW v_execution_history AS
SELECT
  e.execution_id, e.vault_id, v.chain_id, v.vault_address,
  e.action_type, e.status,
  e.asset_symbol, e.asset_address, e.asset_decimals,
  e.amount_asset, e.amount_usd,
  COALESCE(e.to_protocol, e.from_protocol) AS protocol,
  e.apy_at_execution, e.tx_hash, e.timestamp, e.block_number
FROM executions e
JOIN vaults v ON v.vault_id = e.vault_id;

CREATE OR REPLACE VIEW v_agent_tx_history AS
SELECT
  v.chain_id,
  v.vault_address,
  e.tx_hash,
  e.action_type,
  e.status,
  e.asset_symbol,
  e.amount_usd,
  COALESCE(e.to_protocol, e.from_protocol) AS protocol,
  e.apy_at_execution,
  e.timestamp
FROM executions e
JOIN vaults v ON v.vault_id = e.vault_id;
