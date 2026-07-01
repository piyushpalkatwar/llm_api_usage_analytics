# LLM API Usage Analytics & Cost Optimization

## Overview
This project analyzes enterprise usage of LLM APIs (GPT-4 Turbo, GPT-3.5 Turbo, Claude 3 Opus, Claude 3 Sonnet) across 10 organizations. It tracks cost, latency, token consumption, error rates, and RAG (Retrieval-Augmented Generation) adoption to identify where spend can be optimized without sacrificing reliability — a direct, current-day reflection of how companies actually manage their AI infrastructure costs in 2025–26.

## Business Problem
As companies scale their use of LLM APIs, costs grow fast and unpredictably. Engineering and finance teams need a clear answer to: **"Where is our AI spend going, and how do we cut costs without breaking the product?"** This project builds the cost/performance dashboard a Data Analyst would deliver to a platform or FinOps team — including a concrete savings estimate from smarter model routing.

## Dataset: `llm_api_requests.csv`
50 rows, one row per API call. Columns include:

| Column | Description |
|---|---|
| `request_id`, `org_id`, `org_name` | Request and customer identifiers |
| `request_timestamp` | Date and time of the API call |
| `model_name` | gpt-4-turbo, gpt-3.5-turbo, claude-3-opus, claude-3-sonnet |
| `prompt_tokens`, `completion_tokens`, `total_tokens` | Token usage breakdown |
| `latency_ms` | Response time in milliseconds |
| `cost_usd` | Cost of this individual API call |
| `use_case` | e.g. Summarization, Code_Generation, Medical_QA, Contract_Analysis |
| `success` | 1 = succeeded, 0 = failed |
| `error_type` | timeout, rate_limit, context_overflow (blank if successful) |
| `rag_enabled` | 1 = call used a Retrieval-Augmented Generation pipeline |
| `streaming_enabled` | 1 = response was streamed |
| `temperature` | Model temperature/creativity setting |
| `plan_tier` | Starter / Pro / Enterprise customer tier |

## SQL Script: `project3_llm_api_usage_analytics.sql`
Contains 11 queries:

1. **Platform overview** — total requests, cost, success rate, average latency
2. **Model comparison** — cost, latency, and tokens-per-dollar across all 4 models
3. **Use case analysis** — which workflows (e.g. Contract_Analysis, Code_Generation) cost the most
4. **Error analysis** — breakdown by error type (timeout, rate limit, context overflow) and which orgs are affected
5. **Org-level spend ranking** — top API consumers and their primary model
6. **RAG vs non-RAG performance** — cost and token trade-offs of using retrieval pipelines
7. **Latency percentile analysis (P50/P95)** — SLA-style monitoring using a SQLite-compatible workaround, with a PostgreSQL `PERCENTILE_CONT` version included in comments
8. **Temperature vs output length** — how creativity settings affect completion size and cost
9. **Monthly cost projection** — extrapolates observed spend to a 30-day forecast using a CTE
10. **Model routing savings estimate** — projects ~15–20% savings from shifting simple tasks to cheaper models
11. **Executive summary view** — a reusable `CREATE VIEW` summarizing cost, success rate, and RAG usage by model and plan tier

## Tools & Compatibility
- Written for **SQLite** (uses `julianday()` for time-window calculations)
- PostgreSQL equivalent for percentile calculations included in comments (`PERCENTILE_CONT`)
- Uses CTEs (`WITH` clauses), correlated subqueries, and `CREATE VIEW` — slightly more advanced SQL than Projects 1 and 2, good for demonstrating range

## How to Run
1. Load `llm_api_requests.csv` into a table named `llm_api_requests` (CREATE TABLE included at the top)
2. Run queries sequentially — each is labeled with the business question it answers
3. Step 11's `llm_exec_summary` view can be queried independently for a recurring dashboard

## Key Insights to Highlight in Interviews
- GPT-3.5 Turbo delivers the best tokens-per-dollar ratio, ideal for high-volume simple tasks
- Claude 3 Opus dominates complex, high-stakes use cases (contract drafting, legal research) despite higher per-call cost
- RAG-enabled calls cost roughly 2x more but consume more prompt tokens for better-grounded answers — a cost/quality trade-off worth surfacing to stakeholders
- Timeout errors are the leading reliability issue, concentrated in a few specific use cases

## Skills Demonstrated
CTEs, correlated subqueries, percentile estimation without native window functions, UNION-based comparative breakdowns, view creation, and cost-modeling — directly relevant to Data Analyst roles at AI-forward product companies (Razorpay, Groww, and similar Series B/C startups working with LLM infrastructure).
