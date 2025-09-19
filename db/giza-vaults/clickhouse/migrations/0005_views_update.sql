CREATE OR REPLACE VIEW giza.v_agent_tx_history AS
SELECT
  chain_id,
  vault_address,
  wallet_address,   -- now included
  timestamp,
  action_type,
  status,
  asset_symbol,
  asset_address,
  asset_decimals,
  amount_asset,
  amount_usd,
  protocol,
  from_protocol,
  to_protocol,
  apy_at_execution,
  tx_hash,
  block_number,
  log_index
FROM giza.executions_flat;
