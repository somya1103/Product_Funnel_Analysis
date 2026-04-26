# E-Commerce User Behaviour Analytics
### Diagnosing a conversion and retention crisis across 88,000 users

> **Tools:** MySQL · Python · Power BI · pandas · seaborn  
> **Dataset:** 300K events · Oct–Nov 2019 · 
> [Kaggle Source](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store)

---

## The Business Problem

An e-commerce platform with 88,000+ monthly active users 
and $1.68M in revenue is failing to convert browsers into 
buyers — and failing to bring buyers back for a second purchase.

This project investigates:
- Where exactly the funnel breaks and why
- Which categories represent the highest recovery opportunity
- Why retention is near-zero and how to fix it
- Which customer segments drive disproportionate revenue

---

## Dashboard

https://github.com/somya1103/Product_Funnel_Analysis/blob/b8f1f947a6153a9710a9176a37ccdc1fa86bedd9/dashboard/Page%201%3A%20Executive%20Summary/Executive%20summary(Page%201).png
https://github.com/somya1103/Product_Funnel_Analysis/blob/b8f1f947a6153a9710a9176a37ccdc1fa86bedd9/dashboard/Page%202%3A%20Funnel%20%26%20Pricing/Funnel%20and%20pricing(page%202).png
https://github.com/somya1103/Product_Funnel_Analysis/blob/b8f1f947a6153a9710a9176a37ccdc1fa86bedd9/dashboard/Page%203%3A%20Retention%20%26%20RFM/Retention(Page%203).png

🔗 [Live Interactive Dashboard][(#) ← replace with your Power BI link](https://github.com/somya1103/Product_Funnel_Analysis/blob/b8f1f947a6153a9710a9176a37ccdc1fa86bedd9/dashboard/product_funnel.pbix)

---

## Dataset

| Field | Detail |
|---|---|
| Source | Kaggle — eCommerce behavior data |
| Period | October–November 2019 |
| Sample size | 300,000 events (from 42M+ row dataset) |
| Columns | event_time, event_type, product_id, category_code, brand, price, user_id, user_session |
| Event types | view, cart, purchase |

---

## Key Findings

### 1. 93.2% of sessions never add to cart
101,061 of 108,456 sessions end without a single cart addition.
The bottleneck is at the view stage — not checkout.
Cart-to-purchase behaviour is healthy, meaning users with 
buying intent follow through. This is a discovery problem, 
not a checkout problem.

### 2. Month-1 retention is 1.2% vs 8–15% industry benchmark
Only 28 of 2,434 October buyers returned in November.
The platform has no meaningful re-engagement mechanism.
Fixing retention from 1.2% to 5% would compound revenue 
growth beyond what funnel optimisation alone can achieve.

### 3. Smartphone category — biggest single opportunity
50,854 views, sub-2% CVR. If this category reached median 
platform conversion, it would generate hundreds of additional 
purchases per month. High traffic + low conversion = 
recoverable revenue.

### 4. Champions generate 14.3% of revenue from 0.3% of users
268 Champion users average $1,793 revenue each.
Loyal customers generate the highest total revenue ($1.038M) 
but Champions lead on per-user value.
These two segments require completely different retention strategies.

---

## Recommendations

| Priority | Recommendation | Metric it moves | Effort |
|---|---|---|---|
| 1 | Add social proof + EMI options to smartphone category pages | View-to-cart CVR | Low |
| 2 | 3-email re-engagement sequence for Month-1 churned buyers | Month-1 retention | Medium |
| 3 | VIP programme for Champions segment | Champion retention rate | Low |
| 4 | Schedule promotions at 06:00 UTC (peak conversion hour) | Overall CVR | Low |
| 5 | SEO + marketing investment in Niche high-CVR categories | Traffic volume | High |

**Revenue opportunity:** Targeting 2,434 Oct cohort buyers 
with a re-engagement campaign at 5% conversion = 
~120 additional purchases × $300 AOV = **$36,000 
recovered revenue from a single campaign.**

---

## Project Structure
