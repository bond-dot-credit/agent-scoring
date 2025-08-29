# ER Diagram — ClickHouse (natural keys)


```mermaid
erDiagram
USERS ||--o{ USER_VAULTS : maps
VAULTS ||--o{ USER_VAULTS : maps
VAULTS ||--o{ EXECUTIONS : records


USERS {
string wallet_address PK
datetime first_seen_at
}


VAULTS {
string chain_id PK
string vault_address PK
string factory_address
datetime created_at
uint64 created_block
}


USER_VAULTS {
string chain_id FK
string vault_address FK
string wallet_address FK
datetime linked_at
}


EXECUTIONS {
string chain_id FK
string vault_address FK
string tx_hash
uint16 log_index
uint64 block_number
datetime timestamp
string action_type
enum status
string asset_symbol
string asset_address
uint8 asset_decimals
decimal amount_asset(38,18)
decimal amount_usd(38,6)
string protocol
string from_protocol
string to_protocol
float apy_at_execution
}