-- Flat tx history view for API
CREATE OR REPLACE VIEW giza.v_agent_tx_history AS
SELECT
chain_id,
vault_address,
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
FROM giza.executions;


-- Example aggregates (read-mostly analytics)
CREATE OR REPLACE VIEW giza.v_user_agg_30d AS
SELECT
uv.wallet_address,
e.chain_id,
sumIf(e.amount_usd, e.action_type = 'deposit' AND e.status = 'completed' AND e.timestamp >= now() - INTERVAL 30 DAY) AS deposits_30d_usd,
sumIf(e.amount_usd, e.action_type = 'withdraw' AND e.status = 'completed' AND e.timestamp >= now() - INTERVAL 30 DAY) AS withdrawals_30d_usd,
uniqExactIf(e.tx_hash, e.status = 'failed' AND e.timestamp >= now() - INTERVAL 30 DAY) AS failed_txs_30d
FROM giza.user_vaults uv
JOIN giza.executions e
ON e.chain_id = uv.chain_id AND e.vault_address = uv.vault_address
GROUP BY uv.wallet_address, e.chain_id;