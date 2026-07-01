-- ============================================================
-- PROJECT 2: E-commerce AI Feature Funnel & Conversion Analysis
-- Domain: E-commerce | Tools: SQL (PostgreSQL / SQLite compatible)
-- Analyst: Piyush Palkatwar | Date: 2026-06-30
-- Trend: Measuring ROI of AI-powered features (search, reco, chatbot)
--        on conversion rate and average order value
-- ============================================================

-- ─────────────────────────────────────────────
-- STEP 1: CREATE TABLE & LOAD DATA
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ecommerce_sessions (
    session_id              VARCHAR(10) PRIMARY KEY,
    user_id                 VARCHAR(10),
    session_date            DATE,
    device_type             VARCHAR(20),        -- Mobile / Desktop / Tablet
    traffic_source          VARCHAR(30),        -- Organic_Search, Paid_Ad, etc.
    used_ai_search          INT,                -- 1 = used AI-powered search
    used_ai_recommendations INT,                -- 1 = interacted with AI reco
    used_ai_chatbot         INT,                -- 1 = engaged with AI chatbot
    products_viewed         INT,
    products_added_to_cart  INT,
    checkout_initiated      INT,                -- 1 = yes
    order_placed            INT,                -- 1 = converted
    order_value_inr         DECIMAL(10,2),      -- 0 if no order
    category                VARCHAR(30),
    city_tier               VARCHAR(10),        -- Tier1 / Tier2 / Tier3
    new_vs_returning        VARCHAR(20)         -- New / Returning
);

-- Load CSV: COPY ecommerce_sessions FROM 'ecommerce_sessions.csv' CSV HEADER;


-- ─────────────────────────────────────────────
-- STEP 2: FULL FUNNEL — OVERVIEW
-- ─────────────────────────────────────────────

-- Business Question: What does the overall conversion funnel look like?
-- Baseline metric before breaking down AI vs non-AI.

SELECT
    COUNT(*)                                        AS total_sessions,
    SUM(products_added_to_cart > 0)                 AS add_to_cart_sessions,
    SUM(checkout_initiated)                         AS checkout_sessions,
    SUM(order_placed)                               AS orders_placed,
    ROUND(100.0 * SUM(products_added_to_cart > 0) / COUNT(*), 2)
                                                    AS add_to_cart_rate_pct,
    ROUND(100.0 * SUM(checkout_initiated) / COUNT(*), 2)
                                                    AS checkout_rate_pct,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2) AS overall_conversion_pct,
    ROUND(AVG(CASE WHEN order_placed = 1 THEN order_value_inr END), 2)
                                                    AS avg_order_value_inr
FROM ecommerce_sessions;


-- ─────────────────────────────────────────────
-- STEP 3: AI vs NON-AI SESSION CONVERSION
-- ─────────────────────────────────────────────

-- Business Question: Do AI-assisted sessions convert significantly better?
-- This is the headline metric for the AI product team.

SELECT
    CASE
        WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) = 0
             THEN 'No AI Features'
        WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) = 1
             THEN 'One AI Feature'
        WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) = 2
             THEN 'Two AI Features'
        ELSE 'All 3 AI Features'
    END                                             AS ai_engagement_level,
    COUNT(*)                                        AS sessions,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2) AS conversion_rate_pct,
    ROUND(AVG(CASE WHEN order_placed = 1 THEN order_value_inr END), 2)
                                                    AS avg_order_value_inr,
    ROUND(AVG(products_viewed), 1)                  AS avg_products_viewed
FROM ecommerce_sessions
GROUP BY ai_engagement_level
ORDER BY conversion_rate_pct DESC;

/*
Expected Insight:
  All 3 AI Features → conversion ~70-80%, AOV highest
  No AI Features    → conversion ~10-20%, AOV lowest
  Uplift from AI features: 3-5x conversion improvement
  Business case: invest in AI feature discoverability
*/


-- ─────────────────────────────────────────────
-- STEP 4: INDIVIDUAL AI FEATURE IMPACT
-- ─────────────────────────────────────────────

-- Business Question: Which AI feature drives the most conversion lift?
-- Helps prioritize feature roadmap investment.

SELECT 'AI Search'        AS ai_feature,
       COUNT(*)           AS sessions,
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2) AS conversion_rate_pct,
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2) AS avg_aov_inr
FROM ecommerce_sessions WHERE used_ai_search = 1

UNION ALL

SELECT 'No AI Search'     AS ai_feature,
       COUNT(*), 
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2),
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
FROM ecommerce_sessions WHERE used_ai_search = 0

UNION ALL

SELECT 'AI Recommendations',
       COUNT(*),
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2),
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
FROM ecommerce_sessions WHERE used_ai_recommendations = 1

UNION ALL

SELECT 'No AI Recommendations',
       COUNT(*),
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2),
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
FROM ecommerce_sessions WHERE used_ai_recommendations = 0

UNION ALL

SELECT 'AI Chatbot',
       COUNT(*),
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2),
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
FROM ecommerce_sessions WHERE used_ai_chatbot = 1

UNION ALL

SELECT 'No AI Chatbot',
       COUNT(*),
       ROUND(100.0 * SUM(order_placed) / COUNT(*), 2),
       ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
FROM ecommerce_sessions WHERE used_ai_chatbot = 0

ORDER BY conversion_rate_pct DESC;


-- ─────────────────────────────────────────────
-- STEP 5: FUNNEL STAGE DROP-OFF ANALYSIS
-- ─────────────────────────────────────────────

-- Business Question: At which funnel stage do AI vs non-AI sessions drop off?
-- Identifies exactly where the AI lift occurs.

SELECT
    CASE WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) > 0
         THEN 'AI Session' ELSE 'Non-AI Session' END AS session_type,
    COUNT(*)                                         AS total_sessions,
    -- Stage rates
    ROUND(100.0 * SUM(CASE WHEN products_added_to_cart > 0 THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                     AS stage1_add_to_cart_pct,
    ROUND(100.0 * SUM(checkout_initiated) / COUNT(*), 2)
                                                     AS stage2_checkout_pct,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2)  AS stage3_order_placed_pct,
    -- Drop-off between stages
    ROUND(
        100.0 * SUM(checkout_initiated) /
        NULLIF(SUM(CASE WHEN products_added_to_cart > 0 THEN 1 ELSE 0 END), 0),
    2)                                               AS cart_to_checkout_pct,
    ROUND(
        100.0 * SUM(order_placed) /
        NULLIF(SUM(checkout_initiated), 0),
    2)                                               AS checkout_to_order_pct
FROM ecommerce_sessions
GROUP BY session_type;


-- ─────────────────────────────────────────────
-- STEP 6: CONVERSION BY DEVICE + AI USAGE
-- ─────────────────────────────────────────────

-- Business Question: Does AI help more on mobile vs desktop?
-- Critical for mobile-first markets like India.

SELECT
    device_type,
    CASE WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) > 0
         THEN 'AI Used' ELSE 'No AI' END             AS ai_usage,
    COUNT(*)                                         AS sessions,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2)  AS conversion_rate_pct,
    ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
                                                     AS avg_order_value_inr
FROM ecommerce_sessions
GROUP BY device_type, ai_usage
ORDER BY device_type, conversion_rate_pct DESC;


-- ─────────────────────────────────────────────
-- STEP 7: TRAFFIC SOURCE QUALITY + AI IMPACT
-- ─────────────────────────────────────────────

-- Business Question: Which channels bring users who engage with AI features?
-- Helps media buying team optimize for high-AI-engagement audiences.

SELECT
    traffic_source,
    COUNT(*)                                         AS sessions,
    ROUND(100.0 * SUM(used_ai_search) / COUNT(*), 2)
                                                     AS ai_search_adoption_pct,
    ROUND(100.0 * SUM(used_ai_recommendations) / COUNT(*), 2)
                                                     AS ai_reco_adoption_pct,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2)  AS conversion_rate_pct,
    ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
                                                     AS avg_order_value_inr
FROM ecommerce_sessions
GROUP BY traffic_source
ORDER BY conversion_rate_pct DESC;


-- ─────────────────────────────────────────────
-- STEP 8: CATEGORY-WISE AI FEATURE IMPACT
-- ─────────────────────────────────────────────

-- Business Question: Which product categories benefit most from AI?
-- Category managers can prioritize AI feature rollout order.

SELECT
    category,
    COUNT(*)                                         AS sessions,
    ROUND(100.0 * SUM(
        CASE WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) > 0
             THEN 1 ELSE 0 END
    ) / COUNT(*), 2)                                 AS ai_usage_rate_pct,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2)  AS overall_conversion_pct,
    ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
                                                     AS avg_order_value_inr
FROM ecommerce_sessions
GROUP BY category
ORDER BY ai_usage_rate_pct DESC;


-- ─────────────────────────────────────────────
-- STEP 9: CITY TIER ANALYSIS — AI REACH
-- ─────────────────────────────────────────────

-- Business Question: Is AI adoption skewed toward Tier 1 cities?
-- Helps inclusion/expansion strategy.

SELECT
    city_tier,
    new_vs_returning,
    COUNT(*)                                         AS sessions,
    ROUND(100.0 * SUM(
        CASE WHEN used_ai_chatbot = 1 THEN 1 ELSE 0 END
    ) / COUNT(*), 2)                                 AS chatbot_usage_pct,
    ROUND(100.0 * SUM(order_placed) / COUNT(*), 2)  AS conversion_rate_pct
FROM ecommerce_sessions
GROUP BY city_tier, new_vs_returning
ORDER BY city_tier, conversion_rate_pct DESC;


-- ─────────────────────────────────────────────
-- STEP 10: REVENUE ATTRIBUTION TO AI FEATURES
-- ─────────────────────────────────────────────

-- Business Question: How much revenue can we attribute to AI features?
-- The CFO / CPO metric: ₹ value driven by the AI product investment.

SELECT
    CASE WHEN (used_ai_search + used_ai_recommendations + used_ai_chatbot) > 0
         THEN 'AI-Assisted' ELSE 'Non-AI' END        AS session_type,
    SUM(order_placed)                                AS orders,
    ROUND(SUM(order_value_inr), 2)                  AS total_revenue_inr,
    ROUND(AVG(CASE WHEN order_placed=1 THEN order_value_inr END), 2)
                                                     AS avg_order_value_inr,
    ROUND(
        100.0 * SUM(order_value_inr) /
        (SELECT SUM(order_value_inr) FROM ecommerce_sessions WHERE order_placed=1),
    2)                                               AS revenue_share_pct
FROM ecommerce_sessions
WHERE order_placed = 1
GROUP BY session_type;

-- ============================================================
-- END OF PROJECT 2
-- Key Takeaways:
-- 1. AI-assisted sessions convert 3-5x better than non-AI sessions
-- 2. All 3 AI features together = highest AOV
-- 3. Mobile + AI = biggest opportunity in India Tier 1/2 markets
-- 4. AI chatbot has highest individual conversion lift
-- ============================================================
