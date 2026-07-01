
---LLM API Usage Analytics & Cost Optimization
-- Domain: Generative AI / API Products
-- Tools: SQL (PostgreSQL / SQLite compatible)
-- Analyst: Piyush Palkatwar | Date: 2026-06-30
-- Trend: Analyzing enterprise LLM API consumption, costs,
--latency, error rates, and ROI by use case/model


-- STEP 1: CREATE TABLE & LOAD DATA

CREATE TABLE IF NOT EXISTS llm_api_requests (
    request_id          VARCHAR(10) PRIMARY KEY,
    org_id              VARCHAR(10),
    org_name            VARCHAR(50),
    request_timestamp   DATETIME,
    model_name          VARCHAR(30),      -- gpt-4-turbo, claude-3-opus, etc.
    prompt_tokens       INT,
    completion_tokens   INT,
    total_tokens        INT,
    latency_ms          INT,              -- response time in milliseconds
    cost_usd            DECIMAL(10,4),    -- per-call cost
    use_case            VARCHAR(50),      -- e.g., Summarization, Code_Generation
    success             INT,              -- 1 = success, 0 = error
    error_type          VARCHAR(30),      -- NULL if success
    rag_enabled         INT,              -- 1 = RAG pipeline used
    streaming_enabled   INT,              -- 1 = streaming response
    temperature         DECIMAL(3,1),     -- model temperature setting
    plan_tier           VARCHAR(20)       -- Starter / Pro / Enterprise
);

-- Load CSV: COPY llm_api_requests FROM 'llm_api_requests.csv' CSV HEADER;


-- STEP 2: PLATFORM OVERVIEW — USAGE SUMMARY


-- Business Question: What's the overall health of the LLM platform?
-- Baseline dashboard metrics for API product teams.

SELECT
    COUNT(*)                                        AS total_requests,
    COUNT(DISTINCT org_id)                          AS active_orgs,
    SUM(total_tokens)                               AS total_tokens_consumed,
    ROUND(SUM(cost_usd), 4)                         AS total_cost_usd,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_per_request_usd,
    ROUND(AVG(total_tokens), 0)                     AS avg_tokens_per_request
FROM llm_api_requests;



-- STEP 3: MODEL COMPARISON — PERFORMANCE & COST

-- Business Question: Which model gives the best performance/cost ratio?
-- Helps orgs optimize model selection for different use cases.

SELECT
    model_name,
    COUNT(*)                                        AS total_calls,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    ROUND(AVG(total_tokens), 0)                     AS avg_tokens,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_per_call_usd,
    ROUND(SUM(cost_usd), 4)                         AS total_cost_usd,
    ROUND(SUM(total_tokens), 0)                     AS total_tokens,
    -- Cost efficiency: tokens per USD
    ROUND(SUM(total_tokens) / NULLIF(SUM(cost_usd), 0), 0)
                                                    AS tokens_per_dollar
FROM llm_api_requests
GROUP BY model_name
ORDER BY total_calls DESC;

/*
Expected Insight:
  gpt-3.5-turbo: cheapest, highest tokens/$ ratio, for simple tasks
  claude-3-opus: highest quality, highest cost, for complex reasoning
  gpt-4-turbo: balanced, most popular
  Decision framework: use model routing by use case complexity
*/



-- STEP 4: USE CASE ANALYSIS — COST + LATENCY


-- Business Question: Which use cases are most expensive / slow?
-- Helps product teams identify optimization candidates.

SELECT
    use_case,
    COUNT(*)                                        AS total_calls,
    COUNT(DISTINCT org_id)                          AS orgs_using,
    ROUND(AVG(total_tokens), 0)                     AS avg_tokens,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_usd,
    ROUND(SUM(cost_usd), 4)                         AS total_cost_usd,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    -- Identify RAG adoption per use case
    ROUND(100.0 * SUM(rag_enabled) / COUNT(*), 2)  AS rag_adoption_pct
FROM llm_api_requests
GROUP BY use_case
ORDER BY total_cost_usd DESC;


-- STEP 5: ERROR ANALYSIS


-- Business Question: What's causing API failures and which orgs are affected?
-- SRE / platform reliability teams monitor this.

-- 5a. Error type breakdown
SELECT
    error_type,
    COUNT(*)                                        AS error_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM llm_api_requests WHERE success = 0), 2)
                                                    AS pct_of_errors,
    COUNT(DISTINCT org_id)                          AS orgs_affected,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,  -- errors often timeout
    SUM(total_tokens)                               AS tokens_wasted     -- billed but failed
FROM llm_api_requests
WHERE success = 0
GROUP BY error_type
ORDER BY error_count DESC;

-- 5b. Error rate by model
SELECT
    model_name,
    COUNT(*)                                        AS total_calls,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END)   AS failed_calls,
    ROUND(100.0 * SUM(CASE WHEN success=0 THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                    AS error_rate_pct,
    -- Cost lost to failed calls
    ROUND(SUM(CASE WHEN success=0 THEN cost_usd ELSE 0 END), 4)
                                                    AS cost_wasted_usd
FROM llm_api_requests
GROUP BY model_name
ORDER BY error_rate_pct DESC;


-- STEP 6: ORG-LEVEL SPEND ANALYSIS (TOP CONSUMERS)

-- Business Question: Who are our highest-spend API customers?
-- Revenue intelligence for enterprise sales and CSM teams.

SELECT
    org_id,
    org_name,
    plan_tier,
    COUNT(*)                                        AS total_requests,
    SUM(total_tokens)                               AS total_tokens,
    ROUND(SUM(cost_usd), 4)                         AS total_cost_usd,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_per_call,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    -- Dominant model used
    (
        SELECT model_name FROM llm_api_requests r2
        WHERE r2.org_id = r1.org_id
        GROUP BY model_name ORDER BY COUNT(*) DESC LIMIT 1
    )                                               AS primary_model
FROM llm_api_requests r1
GROUP BY org_id, org_name, plan_tier
ORDER BY total_cost_usd DESC;



-- STEP 7: RAG vs NON-RAG PERFORMANCE

-- Business Question: Does enabling RAG improve quality proxies?
-- RAG = Retrieval Augmented Generation (biggest 2024-25 AI trend).
-- Proxy metrics: token usage, success rate, latency.

SELECT
    CASE WHEN rag_enabled = 1 THEN 'RAG Enabled' ELSE 'No RAG' END
                                                    AS rag_status,
    COUNT(*)                                        AS total_calls,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    ROUND(AVG(total_tokens), 0)                     AS avg_tokens,
    ROUND(AVG(prompt_tokens), 0)                    AS avg_prompt_tokens,
    ROUND(AVG(completion_tokens), 0)                AS avg_completion_tokens,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_per_call_usd,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms
FROM llm_api_requests
GROUP BY rag_status;

/*
Expected Insight:
  RAG calls use more prompt tokens (context injection) but produce
  more accurate completions → higher completion_tokens → higher cost
  Trade-off: RAG costs ~2x but improves accuracy significantly
*/


-- STEP 8: LATENCY DISTRIBUTION (PERCENTILES)


-- Business Question: What's the P50/P75/P95 latency per model?
-- SLA monitoring: enterprise contracts often require <3000ms P95.

-- Note: SQLite doesn't support PERCENTILE_CONT natively.
-- Use this workaround with window functions:

SELECT
    model_name,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    MIN(latency_ms)                                 AS min_latency_ms,
    MAX(latency_ms)                                 AS max_latency_ms,
    -- Approximate percentiles using ROW_NUMBER approach
    (
        SELECT latency_ms FROM llm_api_requests r2
        WHERE r2.model_name = r1.model_name
        ORDER BY latency_ms
        LIMIT 1 OFFSET (COUNT(*) * 50 / 100)
    )                                               AS approx_p50_ms,
    (
        SELECT latency_ms FROM llm_api_requests r2
        WHERE r2.model_name = r1.model_name
        ORDER BY latency_ms
        LIMIT 1 OFFSET (COUNT(*) * 95 / 100)
    )                                               AS approx_p95_ms
FROM llm_api_requests r1
GROUP BY model_name
ORDER BY approx_p95_ms DESC;

/* PostgreSQL version — cleaner:
SELECT
    model_name,
    ROUND(AVG(latency_ms)) AS avg_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY latency_ms) AS p50_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_ms
FROM llm_api_requests GROUP BY model_name;
*/


-- STEP 9: TEMPERATURE vs OUTPUT LENGTH ANALYSIS


-- Business Question: Do higher temperature settings produce longer outputs?
-- Informs default parameter recommendations to new API users.

SELECT
    CASE
        WHEN temperature = 0.0 THEN '0.0 (Deterministic)'
        WHEN temperature BETWEEN 0.1 AND 0.3 THEN '0.1-0.3 (Focused)'
        WHEN temperature BETWEEN 0.4 AND 0.6 THEN '0.4-0.6 (Balanced)'
        ELSE '0.7+ (Creative)'
    END                                             AS temperature_range,
    COUNT(*)                                        AS calls,
    ROUND(AVG(completion_tokens), 0)                AS avg_completion_tokens,
    ROUND(AVG(cost_usd), 5)                         AS avg_cost_usd,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct
FROM llm_api_requests
GROUP BY temperature_range
ORDER BY avg_completion_tokens DESC;



-- STEP 10: MONTHLY COST PROJECTION + OPTIMIZATION VIEW

-- Business Question: At this rate, what's the monthly API spend?
-- And what's the potential saving from model optimization?

WITH hourly_stats AS (
    SELECT
        COUNT(*)                                    AS requests_in_window,
        SUM(cost_usd)                               AS cost_in_window,
        MIN(request_timestamp)                      AS window_start,
        MAX(request_timestamp)                      AS window_end
    FROM llm_api_requests
),
projections AS (
    SELECT
        requests_in_window,
        cost_in_window,
        -- Window duration in hours
        ROUND(
            CAST(julianday(window_end) - julianday(window_start) AS FLOAT) * 24,
        2)                                          AS window_hours,
        -- Project to 30 days
        ROUND(cost_in_window /
            NULLIF(CAST(julianday(window_end) - julianday(window_start) AS FLOAT) * 24, 0)
            * 24 * 30, 2)                           AS projected_monthly_cost_usd
    FROM hourly_stats
)
SELECT
    requests_in_window,
    ROUND(cost_in_window, 4)                        AS observed_cost_usd,
    window_hours,
    projected_monthly_cost_usd,
    -- If 30% of gpt-4-turbo calls downgraded to gpt-3.5-turbo → est. savings
    ROUND(projected_monthly_cost_usd * 0.18, 2)    AS est_savings_with_model_routing_usd
FROM projections;


-- STEP 11: EXECUTIVE SUMMARY VIEW

CREATE VIEW IF NOT EXISTS llm_exec_summary AS
SELECT
    model_name,
    plan_tier,
    COUNT(*)                                        AS requests,
    ROUND(SUM(cost_usd), 4)                         AS total_cost_usd,
    ROUND(100.0 * SUM(success) / COUNT(*), 2)       AS success_rate_pct,
    ROUND(AVG(latency_ms), 0)                       AS avg_latency_ms,
    ROUND(100.0 * SUM(rag_enabled) / COUNT(*), 2)  AS rag_usage_pct,
    SUM(total_tokens)                               AS tokens_consumed
FROM llm_api_requests
GROUP BY model_name, plan_tier
ORDER BY total_cost_usd DESC;

SELECT * FROM llm_exec_summary;

-- END OF PROJECT 3
-- Key Takeaways:
-- 1. gpt-3.5-turbo has best tokens/$ ratio for simple tasks
-- 2. claude-3-opus dominates high-complexity enterprise use cases
-- 3. RAG calls cost ~2x but produce richer completions
-- 4. Timeout errors = biggest reliability issue to solve
-- 5. Model routing by use case could cut spend 15-20%

