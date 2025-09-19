/* Add point-in-time (at execution) metrics & running totals to the wide table.
   These default to 0/NULL until your pipelines populate them. */

ALTER TABLE agents.executions
    ADD COLUMN IF NOT EXISTS roi_annualized_at_exec       Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS capital_efficiency_at_exec    Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS protocol_lindy_age_days       Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sharpe_ratio_at_exec          Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS uptime_pct_30d                Float64 DEFAULT 0,

    -- risk & scale
    ADD COLUMN IF NOT EXISTS volatility_score_30d          Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lifetime_tvl_log              Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS liquidity_depth_ratio         Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS tvl_growth_rate               Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS loss_events_weighted_90d      Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS risk_adjusted_tvl_usd         Decimal(38,6) DEFAULT 0,

    -- qualitative / off-chain
    ADD COLUMN IF NOT EXISTS community_sentiment_score_30d Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS criticism_severity_30d        Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reputation_mentions_30d       UInt32  DEFAULT 0,
    ADD COLUMN IF NOT EXISTS earnings_consistency_90d      Float64 DEFAULT 0,
    ADD COLUMN IF NOT EXISTS asset_stability_score         Float64 DEFAULT 0,

    -- convenient running sums (server-side or ETL maintained)
    ADD COLUMN IF NOT EXISTS total_yield_usd_cum           Decimal(38,6) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_rewards_usd_cum         Decimal(38,6) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fees_paid_usd_cum             Decimal(38,6) DEFAULT 0;
