# Bond.Credit — Scoring Agent

## Overview
This branch contains **all code, documentation, and resources related to the AI Agent Scoring Engine** for Bond.Credit.  
It serves as the dedicated workspace for developing, testing, and refining the metric definitions, scoring algorithms, and data pipelines that determine creditworthiness for agents.

All scoring-related work — including sub-branches, commits, and pull requests — will originate from here.

## Scope of Work
The `agent-scoring` branch is the home for:

1. **Metric Definition**  
   - Identifying, categorizing, and documenting the performance, risk, liquidity, and other metrics used in scoring.
   - Storing metric definitions in structured formats (JSON/YAML) with descriptions, formulas, data sources, and dependencies.

2. **Formula Implementation**  
   - Translating defined metric formulas into executable code.
   - Ensuring calculations match the reference documentation.

3. **Data Acquisition & Processing**  
   - Integrating on-chain/off-chain data sources.
   - Cleaning, standardizing, and storing retrieved data in `/data`.

4. **Scoring Algorithm Development**  
   - Implementing the overall scoring formula that combines metrics into a unified agent score.
   - Testing, validating, and refining scoring logic.

5. **Standardization & Validation**  
   - Ensuring metric definitions and code are consistent in units, lookback periods, and naming conventions.
   - Creating validation scripts and automated checks.

## Workflow
**Main Development Branch:** `scoring-agent`
- **Feature Branches:** Create from `scoring-agent` (e.g., `feat/add-success-rate-metric`).
- **Commits:** Use conventional commit messages:

**Pull Requests:**
- Target `agent-scoring`
- Link to related GitHub Issue(s)
- Include a summary of changes and relevant formulas.

## Scoring Engine Guidelines

### Metric Inputs
Metrics in the **Bond.Credit** scoring engines are computed from four main categories of data:

- **On-chain DeFi data** — e.g., total value locked (TVL), historical ROI (CAGR), drawdowns, liquidity depth, volatility, etc.
- **Off-chain development & security data** — e.g., GitHub repository activity, commit history, release cadence, audit records, vulnerability disclosures, governance events.
- **Sentiment metrics** — aggregated community sentiment scores derived from API-based analysis of social platforms, governance forum tone, and developer community discussions. These may be polarity-scored or confidence-weighted, depending on the source.
- **Derived values (feature metrics)** — ratios, rolling growth rates, weighted composite scores, performance trend deltas (e.g., 30-day ROI vs. previous 30 days).

Each metric file must explicitly:
1. List all required raw inputs.
2. Reference exact data sources (API endpoint, block height, dataset version).
3. Specify any weighting, smoothing, or adjustment logic used in calculations.

### Metric Outputs
All metric results are stored in a **structured JSON or YAML** file with the following fields:

- **`value`** — the computed number or score.
- **`unit`** — unit of measurement (e.g., `%`, `USD`, `days`).
- **`timestamp`** — ISO 8601 UTC timestamp of when the calculation was performed.
- **`source`** — the verifiable data source(s) used (on-chain query, API name, dataset link).
