// scripts/ingest_giza_api.js
import fetch from "node-fetch";
import pg from "pg";

/**
 * EDIT THESE to match your setup
 * - If running from Windows host, use localhost:5433
 * - If you run this inside a Docker container next to Postgres, use host "db" and port 5432
 */
const pool = new pg.Pool({
  host: "localhost",
  port: 5433,
  user: "etl_writer",   // from 0004_roles.sql
  password: "etl_pw",   // from 0004_roles.sql
  database: "giza_db",
});

// 🔁 Replace with your teammate’s real API endpoint and params
const GIZA_API_URL = "/agent/{chain_id}/giza/{id}/tx_history"; // placeholder

async function upsertVault(client, v) {
  // Map your API fields here
  const chainId = v.chainId || "base";
  const factory = v.factoryAddress;
  const vaultAddr = v.vaultAddress;
  const createdAt = new Date(v.createdAt * 1000); // or v.createdAt_iso if already ISO
  const createdBlock = BigInt(v.createdBlock);

  const res = await client.query(
    "SELECT upsert_vault($1,$2,$3,$4,$5) AS vault_id",
    [chainId, factory, vaultAddr, createdAt, createdBlock]
  );
  return res.rows[0].vault_id;
}

async function linkAdmins(client, vaultId, admins) {
  for (const w of admins || []) {
    const { rows } = await client.query("SELECT upsert_user($1) AS user_id", [w]);
    const userId = rows[0].user_id;
    await client.query("SELECT link_user_vault($1,$2)", [vaultId, userId]);
  }
}

function mapActionType(a) {
  const x = (a || "").toLowerCase();
  if (x.startsWith("dep")) return "deposit";
  if (x.startsWith("with")) return "withdraw";
  if (x.startsWith("tran")) return "transfer";
  return "deposit";
}
function mapStatus(s) {
  const x = (s || "").toLowerCase();
  if (x.includes("fail")) return "failed";
  if (x.includes("pend")) return "pending";
  return "completed";
}

async function upsertExecutions(client, vaultId, execs) {
  for (const e of execs || []) {
    const action = mapActionType(e.actionType);
    const status = mapStatus(e.status);
    const assetSymbol = e.asset?.symbol || null;
    const assetAddress = e.asset?.address || null;
    const assetDecimals = Number(e.asset?.decimals ?? 0);
    const amountAsset = e.amountRaw ?? e.amount_asset_raw ?? 0;  // integer/raw
    const amountUsd = e.amountUsd ?? null;
    const fromProtocol = e.fromProtocol ?? null;
    const toProtocol = e.toProtocol ?? null;
    const apy = e.apyAtExecution ?? null;
    const txHash = e.txHash;
    const timestamp = new Date((e.timestampSec ?? e.timestamp) * 1000); // adjust if ISO already
    const block = BigInt(e.blockNumber ?? 0);

    await client.query(
      `SELECT upsert_execution(
        $1, $2::action_type_enum, $3::status_enum,
        $4, $5, $6,
        $7, $8, $9, $10, $11, $12, $13, $14
      )`,
      [
        vaultId, action, status,
        assetSymbol, assetAddress, assetDecimals,
        amountAsset, amountUsd, fromProtocol, toProtocol,
        apy, txHash, timestamp, block
      ]
    );
  }
}

async function main() {
  const client = await pool.connect();
  try {
    const resp = await fetch(GIZA_API_URL);
    if (!resp.ok) throw new Error(`Giza API ${resp.status}`);
    const data = await resp.json();

    // Expecting something like: { vaults: [ { ... , admins: [...], executions: [...] } ] }
    const vaults = data.vaults || data || [];
    for (const v of vaults) {
      await client.query("BEGIN");
      try {
        const vaultId = await upsertVault(client, v);
        await linkAdmins(client, vaultId, v.admins || v.getAllAdmin || []);
        await upsertExecutions(client, vaultId, v.executions || []);
        await client.query("COMMIT");
        console.log(`Synced vault ${v.vaultAddress} → id ${vaultId}`);
      } catch (e) {
        await client.query("ROLLBACK");
        console.error("Failed vault", v.vaultAddress, e.message);
      }
    }
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
