# Giza Agent Vaults DB

Normalized Postgres schema and views to store and query: Factory → Vaults → User mapping → Execution history. Powers `/agent/{chain_id}/giza/{vault_address}/tx_history`.

## Structure

* `migrations/` – schema as code (**run in order**: `0001_init.sql` → `0003_upserts.sql` → `0002_views.sql` → `0004_roles.sql`)
* `seeds/` – sample data (optional smoke test; uses the upsert functions)
* `scripts/` – ingest/API helpers (to be finalized with subgraph + Giza API)
* `docs/er.md` – ER diagram (Mermaid)
* `ops/SET_ROLE_PASSWORDS.sql.example` – template to set per-environment role passwords (copy, fill, run; **do not commit** the filled copy)

## Endpoints supported (via SQL views)

* `/agent/{chain_id}/giza/{vault_address}/tx_history` ⇒ `v_agent_tx_history`

**Use this query in the route handler:**

```sql
SELECT *
FROM v_agent_tx_history
WHERE chain_id = $1 AND vault_address = $2
ORDER BY timestamp DESC
LIMIT $3 OFFSET $4;
```

## Quick start (local)

```bash
# 1) copy env
cp .env.example .env   # set POSTGRES_PASSWORD etc.

# 2) run DB + pgAdmin (Postgres on localhost:5433, pgAdmin on http://localhost:8081)
docker compose up -d

# 3) apply migrations (order matters)
#    0001_init.sql -> 0003_upserts.sql -> 0002_views.sql -> 0004_roles.sql
#    (via pgAdmin Query Tool or CLI: docker cp + psql -f)

# 4) (optional) set app role passwords
#    copy ops/SET_ROLE_PASSWORDS.sql.example -> ops/SET_ROLE_PASSWORDS.sql
#    fill passwords and run it once (do NOT commit the filled file)

# 5) (optional) seed & test
#    run seeds/seed.sql, then:
#    SELECT * FROM v_agent_tx_history ORDER BY timestamp DESC LIMIT 20;
```

## Which credentials to use

* **Migrations / local admin:** `giza / <POSTGRES_PASSWORD>`
* **Ingest service (pipeline):** `etl_writer / <ETL_PASSWORD>`
* **Read API / backend:** `api_reader / <API_PASSWORD>`

> If a service runs inside the same Docker network as Postgres, use `host=db` and `port=5432`.
> From your host machine, use `host=localhost` (or `127.0.0.1`) and `port=5433`.

## Notes

* Vaults are unique on `(chain_id, vault_address)`.
* Executions are unique on `(tx_hash, vault_id)`; status can be updated safely (idempotent upserts).
* Views give a stable API shape while we evolve internals.
