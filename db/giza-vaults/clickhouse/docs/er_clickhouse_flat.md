# ER Diagram — ClickHouse “one big table” (serving)

```mermaid
erDiagram
  EXECUTIONS_FLAT {
    string  chain_id
    string  vault_address
    string  wallet_address
    string  tx_hash
    uint16  log_index
    uint64  block_number
    datetime timestamp
    string  action_type
    string  status
    string  asset_symbol
    string  asset_address
    uint8   asset_decimals
    decimal amount_asset
    decimal amount_usd
    string  protocol
    string  from_protocol
    string  to_protocol
    float   apy_at_execution
  }
