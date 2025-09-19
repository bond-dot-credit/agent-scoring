# Giza Vaults DB — ClickHouse


This folder provides a ClickHouse setup for the Giza Vaults analytics DB.


## Why ClickHouse (changes from Postgres)
- Columnar storage, vectorized execution, and MergeTree engines provide very fast analytics.
- We use **natural keys** (e.g., `chain_id + vault_address`) instead of surrogate `vault_id`.
- Dedup & updates use **ReplacingMergeTree(version)** instead of `UPSERT`.
- Pre-computed views use **Materialized Views**.


## Quick start (Windows / PowerShell)
```powershell
cd db/giza-vaults/clickhouse
cp .env.example .env # then edit CH_PASSWORD
# Start DB
docker compose up -d
# (If init scripts didn’t run) run migrations manually
pwsh ./scripts/ch_migrate.ps1
# Smoke test
pwsh ./scripts/ch_smoke.ps1