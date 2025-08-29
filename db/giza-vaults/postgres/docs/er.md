# ER Diagram — Giza Agent Vaults DB

```mermaid
erDiagram
  VAULTS ||--o{ USER_VAULTS : has
  USERS  ||--o{ USER_VAULTS : has
  VAULTS ||--o{ EXECUTIONS  : records

  VAULTS {
    bigint vault_id PK
    text   chain_id
    text   factory_address
    text   vault_address
    timestamptz created_at
    bigint created_block
  }

  USERS {
    bigint user_id PK
    text   wallet_address UK
    timestamptz first_seen_at
  }

  USER_VAULTS {
    bigint id PK
    bigint vault_id FK
    bigint user_id FK
    timestamptz linked_at
  }

  EXECUTIONS {
    bigint execution_id PK
    bigint vault_id FK
    text   action_type
    text   status
    text   asset_symbol
    text   asset_address
    numeric amount_asset
    int     asset_decimals
    numeric amount_usd
    text   from_protocol
    text   to_protocol
    numeric apy_at_execution
    text   tx_hash
    timestamptz timestamp
    bigint block_number
  }
