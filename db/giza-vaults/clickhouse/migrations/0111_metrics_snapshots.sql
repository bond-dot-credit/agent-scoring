/* Windowed rollups per agent/vault (7d/30d/90d/all) */
CREATE TABLE IF NOT EXISTS agents.metrics_snapshots
(
  chain_id      LowCardinality(String),
  agent_name    LowCardinality(String),
  vault_address String,
  as_of_date    Date,
  window        LowCardinality(String),  -- '7d' | '30d' | '90d' | 'all'

  -- performance
  success_rate                 Float64,
  historical_roi_annualized    Float64,
  performance_trend_30d        Float64,
  performance_trend_90d        Float64,
  capital_efficiency           Float64,
  protocol_lindy_age_days      Float64,
  sharpe_ratio                 Float64,
  uptime_percentage            Float64,

  -- risk & scale
  volatility_score_30d         Float64,
  lifetime_tvl_log             Float64,
  liquidity_depth_ratio        Float64,
  tvl_growth_rate              Float64,
  loss_events_weighted_90d     Float64,
  risk_adjusted_tvl_usd        Decimal(38,6),

  -- qualitative / off-chain
  community_sentiment_score_30d Float64,
  criticism_severity_30d        Float64,
  reputation_mentions_30d       UInt32,
  earnings_consistency_90d      Float64,
  asset_stability_score         Float64,

  -- convenient totals/snapshots
  total_yield_usd              Decimal(38,6),
  total_rewards_usd            Decimal(38,6),
  tvl_usd                      Decimal(38,6),

  ingest_ts    DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(ingest_ts)
PARTITION BY toYYYYMM(as_of_date)
ORDER BY (chain_id, agent_name, vault_address, as_of_date, window)
SETTINGS index_granularity = 8192;
