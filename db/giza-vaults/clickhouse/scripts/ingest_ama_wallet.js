import 'dotenv/config';
import { createClient } from '@clickhouse/client';

/* =========================
   ENV (safe local defaults)
   ========================= */
const CH_HOST = process.env.CH_HOST || 'localhost';
const CH_PORT = process.env.CH_HTTP_PORT || '8123';
const CH_DB   = process.env.CH_DB || 'agents';
const CH_USER = process.env.CH_USER || 'giza';
const CH_PASS = process.env.CH_PASSWORD || 'giza_pw_change_me';

const AMA_API_BASE = (process.env.AMA_API_BASE || 'https://api.arma.xyz/api/v1').replace(/\/+$/, ''); // strip trailing slash

/* =========================
   CLI ARGS (support --k=v and --k v)
   ========================= */
const argv = {};
const parts = process.argv.slice(2);
for (let i = 0; i < parts.length; i++) {
  const s = parts[i];
  if (!s.startsWith('--')) continue;
  if (s.includes('=')) {
    const [k, v] = s.slice(2).split(/=(.*)/);
    argv[k] = v;
  } else {
    const k = s.slice(2);
    const v = (i + 1 < parts.length && !parts[i + 1].startsWith('--')) ? parts[++i] : true;
    argv[k] = v;
  }
}

const chain_id = String(argv.chain ?? argv.c ?? '8453'); // Base mainnet default
const vault_address = String(argv.vault ?? argv.v ?? '');
const agent_name = String(argv.agent ?? 'giza');
const pages = Number(argv.pages ?? 1);
const limit = Number(argv.limit ?? 100);

// minimal validation (avoid 422s)
if (!/^0x[a-fA-F0-9]{40}$/.test(vault_address)) {
  console.error(`Invalid --vault address: "${vault_address}"`);
  process.exit(1);
}
if (!/^(8453|-1|84532|1|11155111)$/.test(chain_id)) {
  console.error(`Invalid --chain value: "${chain_id}" (expected one of 8453, -1, 84532, 1, 11155111)`);
  process.exit(1);
}

/* =========================
   ClickHouse client
   ========================= */
const ch = createClient({
  url: `http://${CH_HOST}:${CH_PORT}`,
  database: CH_DB,
  username: CH_USER,
  password: CH_PASS,
});

async function insertExecutions(rows) {
  if (!rows || rows.length === 0) return;
  await ch.insert({
    table: 'agents.executions',
    values: rows,
    format: 'JSONEachRow',
  });
  console.log(`Inserted ${rows.length} rows -> agents.executions`);
}

/* =========================
   Helpers
   ========================= */
const toLower0x = (v) => (v ? String(v).toLowerCase() : '');

function toISODateTime(ts) {
  // ClickHouse DateTime expects 'YYYY-MM-DD HH:MM:SS'
  const toSQL = (d) => d.toISOString().replace('T', ' ').slice(0, 19);
  if (!ts) return toSQL(new Date());
  if (typeof ts === 'number') return toSQL(new Date(ts * 1000));
  const s = String(ts);
  if (/^\d+$/.test(s)) return toSQL(new Date(Number(s) * 1000));
  return s.replace('T', ' ').slice(0, 19);
}

function toDecimalString(x) {
  if (x === null || x === undefined) return '0';
  return String(x);
}

function guessActionType(tx, vault) {
  // Prefer AMA-native "action" if present
  const a = String(tx.action ?? '').toLowerCase();
  if (a === 'deposit' || a === 'withdraw' || a === 'transfer') return a;

  // Fallback heuristic
  const from = toLower0x(tx.from);
  const to   = toLower0x(tx.to);
  const v    = toLower0x(vault);
  if (to && v && to === v) return 'deposit';
  if (from && v && from === v) return 'withdraw';
  const method = (tx.method || tx.action || '').toLowerCase();
  if (method.includes('swap') || method.includes('trade')) return 'transfer';
  return 'transfer';
}

function mapStatus(tx) {
  // AMA shows e.g. "approved" → treat as completed
  const s = (tx.status || tx.tx_status || '').toString().toLowerCase();
  if (['success', 'succeeded', 'completed', 'approved', '1', 'true'].includes(s)) return 'completed';
  if (['failed', '0', 'false', 'rejected'].includes(s)) return 'failed';
  return 'completed';
}

/*  Stablecoin decimal overrides (by SYMBOL and by ADDRESS).
    We DO NOT change asset_symbol; only fix decimals for normalization. */

// Known USDC on Base
const BASE_USDC_ADDR = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

const STABLE_DECIMALS_BY_SYMBOL = new Map([
  ['usdc', 6],
  ['usdbc', 6],   // legacy bridged symbol on Base
  ['usdc.e', 6],
]);

const DECIMALS_BY_ADDRESS = new Map([
  [BASE_USDC_ADDR, 6],
]);

function normalizeAsset(tx) {
  // Prefer AMA-native token fields. DO NOT override symbol text.
  const symbolRaw =
    tx.tokenSymbol || tx.assetSymbol || tx.symbol ||
    (tx.currency && tx.currency.symbol) || '';
  const symbol = String(symbolRaw || 'UNKNOWN');

  // Prefer token_type for address when present (as in the AMA sample)
  const addressRaw =
    tx.token_type || tx.tokenAddress || tx.assetAddress || tx.contractAddress ||
    (tx.currency && tx.currency.address) || '';
  const address = toLower0x(addressRaw);

  // decimals from API if present
  let decimals =
    tx.tokenDecimals ?? tx.assetDecimals ?? tx.decimals ??
    (tx.currency && tx.currency.decimals);

  decimals = Number.isFinite(Number(decimals)) ? Number(decimals) : undefined;

  // If decimals missing: try address map, then symbol map
  if (decimals == null && address) {
    const d = DECIMALS_BY_ADDRESS.get(address);
    if (d != null) decimals = d;
  }
  if (decimals == null) {
    const key = symbol.toLowerCase();
    if (STABLE_DECIMALS_BY_SYMBOL.has(key)) decimals = STABLE_DECIMALS_BY_SYMBOL.get(key);
  }
  if (decimals == null) decimals = 18; // final fallback

  // amount: AMA uses integer "amount" (e.g., 11028875 for USDC 6dp)
  const raw = tx.value ?? tx.amount ?? tx.quantity ?? 0;
  let amountHuman = '0';
  try {
    const rawStr = String(raw);
    if (/^\d+$/.test(rawStr)) {
      const pad = rawStr.padStart(decimals + 1, '0');
      amountHuman = pad.slice(0, -decimals) + (decimals ? '.' + pad.slice(-decimals) : '');
    } else {
      amountHuman = rawStr; // already decimal-like
    }
  } catch {
    amountHuman = '0';
  }

  return {
    symbol,
    address,
    decimals,
    amountHuman: toDecimalString(amountHuman),
  };
}

/* APY mapper: map apr/apy fields to apy_at_execution (percentage) */
function mapApy(tx) {
  const candidates = [
    ['apy', 1],
    ['apr', 1],                 // AMA sample uses "apr" as a percent number
    ['apyAtExecution', 1],
    ['aprAtExecution', 1],
    ['apy_at_execution', 1],
    ['apr_at_execution', 1],
    ['yield', 1],
    ['apyPercent', 1],
    ['aprPercent', 1],
    ['apyBps', 0.01],           // bps → %
    ['aprBps', 0.01],
  ];
  for (const [k, scale] of candidates) {
    const v = tx?.[k];
    if (v === undefined || v === null || v === '') continue;
    const num = Number(v);
    if (!Number.isFinite(num)) continue;
    return num * scale;
  }
  return 0;
}

/* =========================
   Mapper: AMA tx → agents.executions row
   Uses AMA-native fields first; seq keeps rows distinct if log index is absent.
   ========================= */
function amaTxToExecRow(tx, { chain_id, agent_name, vault_address, seq = 0 }) {
  const { symbol, address, decimals, amountHuman } = normalizeAsset(tx);

  const action_type = guessActionType(tx, vault_address);
  const status = mapStatus(tx);

  const tx_hash =
    tx.transaction_hash || tx.transactionHash || tx.hash || tx.tx_hash || '';

  // Prefer real log index; otherwise use our synthetic seq to keep rows distinct
  const log_index = Number(
    tx.logIndex ?? tx.log_index ?? tx.eventIndex ?? tx.index ?? seq ?? 0
  );

  const block_number = Number(tx.blockNumber ?? tx.block_number ?? 0);

  // Prefer AMA "date" (ISO Z) if present, else blockTimestamp/timestamp
  const timestamp = toISODateTime(tx.date ?? tx.blockTimestamp ?? tx.timestamp);

  const apy_at_execution = mapApy(tx);

  return {
    chain_id: String(chain_id),
    agent_name: String(agent_name),
    vault_address: toLower0x(vault_address),

    tx_hash,
    log_index,
    block_number,
    timestamp,
    block_timestamp: timestamp,

    action_type,
    status,

    asset_symbol: symbol,            // we do not change the symbol text
    asset_address: address,
    asset_decimals: Number(decimals) || 18,
    amount_asset: amountHuman,       // normalized using decimals (USDC → 6)
    amount_usd: '0',                 // pricing to be added later
    price_usd: '0',
    fee_usd: '0',
    realized_pnl_usd: '0',

    protocol: tx.protocol || '',
    from_protocol: tx.from_protocol || '',
    to_protocol: tx.to_protocol || '',
    exchange: tx.exchange || '',

    apy_at_execution,                // % value if present, else 0
    // ingest_ts comes from server default
  };
}

/* =========================
   AMA fetcher (robust envelope handling)
   ========================= */
async function fetchAmaPage({ chain_id, vault, page, limit }) {
  const url = `${AMA_API_BASE}/${chain_id}/wallets/${vault}/transactions?page=${page}&limit=${limit}`;
  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`AMA API ${res.status}: ${body}`);
  }
  const data = await res.json();

  let items = [];
  if (Array.isArray(data)) items = data;
  else if (Array.isArray(data.items)) items = data.items;
  else if (Array.isArray(data.results)) items = data.results;
  else if (Array.isArray(data.transactions)) items = data.transactions; // AMA sample
  else if (data.data) {
    if (Array.isArray(data.data)) items = data.data;
    else if (Array.isArray(data.data.items)) items = data.data.items;
    else if (Array.isArray(data.data.results)) items = data.data.results;
    else if (Array.isArray(data.data.transactions)) items = data.data.transactions;
  }

  if (!items.length) {
    const keys = Object.keys(data || {});
    const dataKeys = data?.data && !Array.isArray(data.data) ? Object.keys(data.data) : null;
    console.log(
      `AMA page ${page}: 0 items. Top-level keys: ${JSON.stringify(keys)}` +
      (dataKeys ? `; data.keys: ${JSON.stringify(dataKeys)}` : '')
    );
  }
  return items;
}

/* =========================
   Main
   ========================= */
async function run() {
  console.log(`Source: ${AMA_API_BASE}/${chain_id}/wallets/${vault_address}/transactions`);
  let total = 0;

  for (let p = 1; p <= pages; p++) {
    const items = await fetchAmaPage({ chain_id, vault: vault_address, page: p, limit });
    if (!items.length) {
      console.log(`Page ${p} returned 0 items. Stopping.`);
      break;
    }
    const baseSeq = (p - 1) * limit; // keeps synthetic log_index unique across pages
    const rows = items.map((tx, i) =>
      amaTxToExecRow(tx, { chain_id, agent_name, vault_address, seq: baseSeq + i })
    );
    await insertExecutions(rows);
    total += rows.length;
  }

  console.log(`Done. Inserted total: ${total}`);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
