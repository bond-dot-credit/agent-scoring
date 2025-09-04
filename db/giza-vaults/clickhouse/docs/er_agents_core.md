# ER Diagram — Agents (core ingest + serving)

```mermaid
erDiagram
  %% Core relationships (agent-agnostic)
  AGENTS        ||--o{ AGENT_VAULTS     : has
  VAULTS        ||--o{ AGENT_VAULTS     : maps
  VAULTS        ||--o{ USER_VAULTS      : links
  VAULTS        ||--o{ EXECUTIONS       : records
  USER_VAULTS   ||--o{ EXECUTIONS_FLAT  : enriches
  EXECUTIONS    ||--o{ EXECUTIONS_FLAT  : materializes

  AGENTS {
    string  agent_id
    string  agent_name
    string  model_type
    string  owner_address
    date    deployment_date
    string  website
    string  category
    string[] tags
    string  status
    string[] chain_ids
  }

  VAULTS {
    string  chain_id
    string  factory_address
    string  vault_address
    datetime created_at
    uint64  created_block
  }

  AGENT_VAULTS {
    string  chain_id
    string  vault_address
    string  agent_id
    string  agent_name
    datetime linked_at
  }

  USER_VAULTS {
    string  chain_id
    string  vault_address
    string  wallet_address
    datetime linked_at
  }

  EXECUTIONS {
    string  chain_id
    string  agent_name
    string  vault_address
    string  tx_hash
    uint16  log_index
    uint64  block_number
    datetime timestamp
    datetime block_timestamp
    string  action_type
    string  status
    string  asset_symbol
    string  asset_address
    uint8   asset_decimals
    decimal amount_asset
    decimal amount_usd
    decimal price_usd
    decimal fee_usd
    decimal realized_pnl_usd
    string  protocol
    string  from_protocol
    string  to_protocol
    string  exchange
    float   apy_at_execution
  }

  EXECUTIONS_FLAT {
    string  chain_id
    string  agent_name
    string  vault_address
    string  wallet_address
    string  tx_hash
    uint16  log_index
    uint64  block_number
    datetime timestamp
    datetime block_timestamp
    string  action_type
    string  status
    string  asset_symbol
    string  asset_address
    uint8   asset_decimals
    decimal amount_asset
    decimal amount_usd
    decimal price_usd
    decimal fee_usd
    decimal realized_pnl_usd
    string  protocol
    string  from_protocol
    string  to_protocol
    string  exchange
    float   apy_at_execution
  }
