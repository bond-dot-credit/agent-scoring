/* Latest snapshot per agent/vault (pick most recent as_of_date for each group) */
CREATE OR REPLACE VIEW agents.v_metrics_latest AS
SELECT
  chain_id, agent_name, vault_address,
  argMax(success_rate,              as_of_date) AS success_rate,
  argMax(historical_roi_annualized, as_of_date) AS historical_roi_annualized,
  argMax(performance_trend_30d,     as_of_date) AS performance_trend_30d,
  argMax(performance_trend_90d,     as_of_date) AS performance_trend_90d,
  argMax(capital_efficiency,        as_of_date) AS capital_efficiency,
  argMax(protocol_lindy_age_days,   as_of_date) AS protocol_lindy_age_days,
  argMax(sharpe_ratio,              as_of_date) AS sharpe_ratio,
  argMax(uptime_percentage,         as_of_date) AS uptime_percentage,

  argMax(volatility_score_30d,      as_of_date) AS volatility_score_30d,
  argMax(lifetime_tvl_log,          as_of_date) AS lifetime_tvl_log,
  argMax(liquidity_depth_ratio,     as_of_date) AS liquidity_depth_ratio,
  argMax(tvl_growth_rate,           as_of_date) AS tvl_growth_rate,
  argMax(loss_events_weighted_90d,  as_of_date) AS loss_events_weighted_90d,
  argMax(risk_adjusted_tvl_usd,     as_of_date) AS risk_adjusted_tvl_usd,

  argMax(community_sentiment_score_30d, as_of_date) AS community_sentiment_score_30d,
  argMax(criticism_severity_30d,        as_of_date) AS criticism_severity_30d,
  argMax(reputation_mentions_30d,       as_of_date) AS reputation_mentions_30d,
  argMax(earnings_consistency_90d,      as_of_date) AS earnings_consistency_90d,
  argMax(asset_stability_score,         as_of_date) AS asset_stability_score,

  argMax(total_yield_usd,           as_of_date) AS total_yield_usd,
  argMax(total_rewards_usd,         as_of_date) AS total_rewards_usd,
  argMax(tvl_usd,                   as_of_date) AS tvl_usd,

  max(as_of_date) AS as_of_date_latest
FROM agents.metrics_snapshots
GROUP BY chain_id, agent_name, vault_address;
