# Project 2: E-commerce AI Feature Funnel & Conversion Analysis

## Overview
This project measures the real impact of AI-powered features — AI search, AI product recommendations, and an AI chatbot — on an e-commerce platform's conversion funnel. It compares AI-assisted sessions against non-AI sessions across every funnel stage, device type, traffic source, and product category to quantify exactly how much revenue AI features generate.

## Business Problem
Every e-commerce company is investing in AI features right now, but few can answer the question leadership actually asks: **"Is this AI investment paying off?"** This project builds the funnel and revenue-attribution analysis needed to justify (or challenge) continued investment in AI search, recommendations, and chatbots — the kind of analysis a Product Analyst would be expected to deliver before a quarterly business review.

## Dataset: `ecommerce_sessions.csv`
50 rows, one row per user session. Columns include:

| Column | Description |
|---|---|
| `session_id`, `user_id` | Session and user identifiers |
| `session_date` | Date of the session |
| `device_type` | Mobile / Desktop / Tablet |
| `traffic_source` | Organic_Search, Paid_Ad, Social_Media, Direct, Email |
| `used_ai_search` | 1 = used AI-powered search |
| `used_ai_recommendations` | 1 = interacted with AI product recommendations |
| `used_ai_chatbot` | 1 = engaged with the AI chatbot |
| `products_viewed`, `products_added_to_cart` | Engagement depth |
| `checkout_initiated`, `order_placed` | Funnel conversion flags |
| `order_value_inr` | Order value in INR (0 if no purchase) |
| `category` | Electronics, Fashion, Home_Decor, Grocery |
| `city_tier` | Tier1 / Tier2 / Tier3 (Indian market context) |
| `new_vs_returning` | New or returning customer |

## SQL Script: `project2_ecommerce_ai_funnel.sql`
Contains 10 queries:

1. **Full funnel overview** — baseline add-to-cart, checkout, and conversion rates
2. **AI vs non-AI session conversion** — the headline metric: how much does AI lift conversion
3. **Individual AI feature impact** — isolates search, recommendations, and chatbot to see which drives the most lift
4. **Funnel stage drop-off** — pinpoints exactly where AI sessions outperform (cart → checkout → order)
5. **Conversion by device + AI usage** — mobile vs desktop AI impact, critical for mobile-first markets
6. **Traffic source quality + AI adoption** — which channels bring AI-engaged users
7. **Category-wise AI impact** — which product categories benefit most from AI features
8. **City tier analysis** — checks if AI adoption is skewed toward Tier 1 cities
9. **Revenue attribution to AI** — converts the funnel lift into actual ₹ revenue share
10. (Bonus logic embedded throughout) — AOV comparison at every cut

## Tools & Compatibility
- Written for **SQLite**, fully portable to PostgreSQL/MySQL with no syntax changes needed (no date functions used beyond standard `GROUP BY`/`CASE`)
- Works in DB Browser for SQLite, pgAdmin, DBeaver, or any cloud SQL sandbox

## How to Run
1. Load `ecommerce_sessions.csv` into a table named `ecommerce_sessions` (CREATE TABLE statement included at the top)
2. Run queries top to bottom — each is labeled with the business question it answers
3. Use Step 3 (individual feature impact) and Step 10 (revenue attribution) as the two queries most likely to come up in an interview discussion

## Key Insights to Highlight in Interviews
- Sessions using all 3 AI features converted at several times the rate of sessions using none, with higher average order value
- AI chatbot engagement showed the strongest individual lift on conversion
- Mobile + AI feature usage is the biggest growth lever in Tier 1/Tier 2 Indian markets

## Skills Demonstrated
Funnel analysis, conversion rate calculation, segmentation (device/channel/category/city tier), UNION-based comparative analysis, revenue attribution modeling, and business storytelling from SQL output — core Product Analyst interview territory.
