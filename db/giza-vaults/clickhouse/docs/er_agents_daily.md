```md
# ER Diagram — Agents (daily rollups)

```mermaid
erDiagram
  %% Daily rollups share keys: asof_date (+ chain_id / agent_id / agent_name)

  AGENTS ||--o{ AGENT_IDENTITY_DAILY : identity
  AGENTS ||--o{ AGENT_CONTRACTS_DAILY : contracts
  AGENTS ||--o{ AGENT_USERS_DAILY : users
  AGENTS ||--o{ STRATEGIES_DAILY : strategies
  AGENTS ||--o{ ASSET_DAILY : tvl
  AGENTS ||--o{ EXEC_STATS_DAILY : execstats
  AGENTS ||--o{ RETURNS_DAILY : returns
  AGENTS ||--o{ TVL_LEDGER_DAILY : tvl_ledger
  AGENTS ||--o{ HOLDINGS_DAILY : holdings

  CHAIN_TOTAL_TVL_DAILY ||--o{ RISKFREE_DAILY : market
  DEPLOYED_AGENTS_ON_PROJECT_DAILY ||--o{ CHAIN_TOTAL_DEPLOYED_AGENTS_DAILY : counts
  POOLS_DEPTH_DAILY ||--o{ SENTIMENT_DAILY : context

  AGENT_IDENTITY_DAILY {
    string  agent_id
    string  agent_name
    date    asof_date
    datetime block_timestamp
    decimal asset_under_management
    string  website
    string  category
    string[] tags
    string  status
    string[] chain_ids
  }

  AGENT_CONTRACTS_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    string[] primary_contracts
    string  share_token
    string[] underlying_tokens
    uint8   is_erc4626
    string  proxy_address
    string  implementation_address
    uint64  start_block
    datetime first_deploy_ts
  }

  AGENT_USERS_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    uint64  unique_depositors_cumulative
    uint64  unique_depositors_30d
    uint64  active_wallets_30d
  }

  STRATEGIES_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    string  strategy_id
    string  protocol_name
    string[] asset_pairs
    string  status
  }

  ASSET_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    decimal tvl_usd
    decimal total_shares
    decimal total_assets
  }

  EXEC_STATS_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    uint64  success_calls
    uint64  failed_calls
  }

  RETURNS_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    float   ret_pct
  }

  RISKFREE_DAILY {
    string  chain_id
    date    asof_date
    datetime block_timestamp
    float   rf_rate_daily
  }

  LOSS_EVENTS {
    string  agent_id
    string  agent_name
    string  chain_id
    datetime ts
    date    asof_date
    decimal value_before_usd
    decimal value_after_usd
    float   loss_pct
    string  tx_hash
  }

  TVL_LEDGER_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    decimal tvl_usd_today
    decimal lifetime_deposits_usd
  }

  HOLDINGS_DAILY {
    string  agent_id
    string  agent_name
    string  chain_id
    date    asof_date
    datetime block_timestamp
    string  token_address
    string  token_symbol
    uint8   token_decimals
    decimal balance
    decimal usd_value
  }

  CHAIN_TOTAL_TVL_DAILY {
    string  chain_id
    date    asof_date
    datetime block_timestamp
    decimal tvl_usd
  }

  CHAIN_TOTAL_DEPLOYED_AGENTS_DAILY {
    string  chain_id
    date    asof_date
    datetime block_timestamp
    uint64  total_agents
  }

  DEPLOYED_AGENTS_ON_PROJECT_DAILY {
    string  chain_id
    string  agent_name
    date    asof_date
    datetime block_timestamp
    uint64  deployed_agents_count
  }

  POOLS_DEPTH_DAILY {
    string  chain_id
    date    asof_date
    datetime block_timestamp
    string  pool_address
    string  token0
    string  token1
    decimal reserve0
    decimal reserve1
    decimal depth_1pct_usd
  }

  SENTIMENT_DAILY {
    date    asof_date
    datetime block_timestamp
    string[] project_handles
    string[] contract_addresses
    float   sentiment_avg
    float   volume
    float   criticism_severity
    uint64  reputation_mentions
  }