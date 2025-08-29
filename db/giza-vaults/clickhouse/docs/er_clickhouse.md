# ER Diagram — ClickHouse (natural keys)

```mermaid
erDiagram
  USERS  ||--o{ USER_VAULTS : maps
  VAULTS ||--o{ USER_VAULTS : maps
  VAULTS ||--o{ EXECUTIONS  : records

  USERS {
    string wallet_address
    datetime first_seen_at
  }

  VAULTS {
    string chain_id
    string vault_address
    string factory_address
    datetime created_at
    uint64  created_block
  }

  USER_VAULTS {
    string chain_id
    string vault_address
    string wallet_address
    datetime linked_at
  }

  EXECUTIONS {
    string  chain_id
    string  vault_address
    string  tx_hash
    uint16  log_index
    uint64  block_number
    datetime timestamp
    string  action_type
    string  status
    string  asset_symbol
    string  asset_address
    uint8   asset_decimals
    decimal amount_asset    %% Decimal128 scale 18 in CH
    decimal amount_usd      %% Decimal128 scale 6 in CH
    string  protocol
    string  from_protocol
    string  to_protocol
    float   apy_at_execution
  }
