// Minimal demo: insert 2 executions and a mapping
// Usage: node scripts/ingest_ch_sample.js
import { createClient } from '@clickhouse/client'
import fs from 'node:fs'
import path from 'node:path'
import 'dotenv/config'


const host = process.env.CH_HOST || 'localhost'
const port = process.env.CH_HTTP_PORT || '8123'
const db = process.env.CH_DB || 'giza'
const user = process.env.CH_USER || 'giza'
const password = process.env.CH_PASSWORD || 'giza_pw_change_me'


const client = createClient({
host: `http://${host}:${port}`,
database: db,
username: user,
password,
})


async function main(){
// map a user to a vault
await client.command({
query: `INSERT INTO giza.user_vaults (chain_id, vault_address, wallet_address, linked_at) VALUES`,
values: [
['base', '0xVaultA', '0xAdmin1', new Date()],
],
clickhouse_settings: { async_insert: 1 }
})


// insert 2 executions (ReplacingMergeTree will dedup per ORDER BY key keeping latest by ingest_ts)
const now = new Date()
const rows = [
['base','0xVaultA','0xTx1',0,123n, now,'deposit','completed','USDC','0xA0b86991',6,'100.000000000000000000','100.000000','AaveV3','',null,0.05],
['base','0xVaultA','0xTx2',0,124n, now,'withdraw','failed','USDC','0xA0b86991',6,'50.000000000000000000','50.000000','AaveV3','',null,0.00]
]
await client.insert({
table: 'giza.executions',
values: rows,
format: 'JSONEachRow',
// map to named columns
columns: [
'chain_id','vault_address','tx_hash','log_index','block_number','timestamp','action_type','status',
'asset_symbol','asset_address','asset_decimals','amount_asset','amount_usd','protocol','from_protocol','to_protocol','apy_at_execution'
]
})


// read back from the API view
const rs = await client.query({
query: `SELECT chain_id, vault_address, tx_hash, action_type, status, amount_usd, timestamp FROM giza.v_agent_tx_history ORDER BY timestamp DESC LIMIT 10`,
format: 'JSONEachRow',
})
const data = await rs.json()
console.log(data)
}


main().then(()=> process.exit(0)).catch(e=>{ console.error(e); process.exit(1) })