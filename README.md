# Product_Funnel_Analysis

## Findings by Analysis Area

## Page 1 — Executive Summary

**Insights:**
- 93.2% of all sessions (101,061 out of 108,456) end without a single cart addition — the platform loses nearly every potential buyer at the very first stage of the funnel
- Cart-to-purchase behaviour is healthy — users who show buying intent follow through — meaning the problem is discovery and consideration, not checkout friction
- 268 Champion users representing just 0.3% of the user base generate 14.3% of total revenue — extreme value concentration in a tiny segment
- Loyal customers generate the highest total revenue ($1.038M) but Champions lead on per-user value at $1,793 average — two different retention problems requiring two different strategies

**Recommendations:**
- Prioritise product page improvements for high-traffic categories — better images, review counts, and trust signals to move users from passive browsing to active cart consideration
- Implement a VIP recognition programme for Champions immediately — early access, exclusive offers, personalised outreach — protecting this segment costs little but loss of even 50 Champions meaningfully impacts revenue
- Investigate why Loyal customers outnumber Champions 6:1 — what stops a Loyal customer from becoming a Champion is your most valuable product question

**Limitations:**
- Session bounce classification is based on whether a cart or purchase event exists in the session — sessions with only view events are classified as bounced, which may include users who returned in a later session
- Total Revenue shows $1.68M which reflects the 300K sampled dataset, not the full 42M row dataset

---

## Page 2 — Funnel & Pricing

**Insights:**
- High-price items ($65+) have the highest view-to-cart rate (1.81%) and highest view-to-purchase rate (2.02%) — counterintuitively, expensive product browsers are more intentional buyers than low-price browsers
- Low-price items ($0-15) have the worst view-to-cart rate (0.24%) despite being the cheapest — suggesting the low-price category has a product quality or trust perception problem, not a price barrier
- The smartphone category sits in the Opportunity quadrant with 50,854 views but sub-2% CVR — the largest single recoverable revenue opportunity on the platform
- Revenue concentrates exponentially in price deciles D9-D10 ($459-$2,558 range) — the top 20% of price points generate over 50% of total revenue despite equal transaction volume across deciles
- Peak conversion occurs at 06:00 UTC (11:30 PM IST) at 2.19% — users converting late at night are likely high-intent, distraction-free browsers making deliberate purchase decisions

**Recommendations:**
- For the smartphone category specifically — add EMI/affordability options, comparison tools, and expert review badges on product pages. This category has proven demand (50K+ views) but users are not crossing the consideration threshold
- Schedule flash sales, push notifications, and limited-time offers at 06:00 UTC to capture the peak conversion window when intent is highest
- Investigate the low-price category underperformance — run a qualitative review of product pages in the $0-15 range to identify trust and quality perception issues
- For D9-D10 price range products — invest in premium product photography, detailed specifications, and return policy prominence since these high-value purchases require more reassurance

**Limitations:**
- Hourly analysis covers UTC hours 00:00-07:00 only due to sampling distribution. Peak conversion at 06:00 UTC corresponds to 11:30 PM IST — consistent with late-night browsing behaviour in the Indian market
- cart_to_purchase_pct excluded from price band analysis — sampling artifact caused purchase events to outnumber cart events producing values above 100%, which is statistically impossible
- Category quadrant crosshair lines represent dataset averages — a larger dataset would shift these thresholds and may reclassify some categories between quadrants

---

## Page 3 — Retention & RFM

**Insights:**
- Only 28 of 2,434 October buyers (1.2%) returned to purchase in November — 8x below the industry benchmark of 8-15% Month-1 retention
- The November cohort has no Month-1 data because the dataset ends in November — this is a data boundary, not a retention finding
- Champions (0 days since last purchase, 5.2 avg orders) vs Lost users (31 days since last purchase, 2.0 avg orders) — the behavioural gap confirms Lost users were never highly engaged, they are likely one-time intentional buyers rather than previously loyal users who drifted
- Champions browse 15 pages on average vs 8 for Lost users — high browse depth before purchase is the strongest behavioural signal of a Champion, suggesting a discovery-rich experience drives high-value buying
- At-risk segment (1,034 users, 21.6% of buyers) has not purchased in 31 days but has a purchase history — this is your highest-ROI retention target because intent is proven and churn is not yet complete

**Recommendations:**
- Build a 3-email re-engagement sequence for all buyers who have not returned within 14 days — Day 3 thank you with personalised recommendations, Day 14 category-specific offer based on purchase history, Day 25 time-limited incentive. Targeting the 2,434 Oct cohort at even 5% re-engagement = 120 additional purchases at $300 AOV = $36,000 recovered revenue from one campaign
- Focus win-back spend on At-risk segment (1,034 users) not Lost segment — At-risk users have recent enough purchase history to respond to re-engagement. Lost users (31 days inactive, low browse depth) have a low probability of return and should receive minimal spend
- For Champions — move them to a dedicated high-touch retention track. Personal outreach, first access to new inventory, and loyalty rewards. The cost of losing one Champion ($1,793 avg revenue) exceeds the cost of retaining 10 standard users
- Track browse depth as a leading indicator of Champion conversion — users viewing 15+ pages before purchase are significantly more likely to become Champions. Surface this behaviour early with personalised deep-dive content

**Limitations:**
- Cohort retention is limited to Month-0 and Month-1 only — a 6-month dataset would enable Week 4 through Month-6 retention curves and LTV estimation by cohort
- RFM scores are calculated on a 2-month window — in production, RFM would typically use 12 months of data. Current scores may misclassify users who are seasonal buyers as Lost
- Lost segment shows 713 users in the dashboard vs 879 in the raw CSV — the difference reflects users filtered out during the Champions vs Lost comparison query due to NULL values in session data

---

## How to use all of this

**In Power BI insight boxes** — use the bold first sentence of each insight only. Keep boxes to 2-3 lines maximum. Full detail goes in the README.

**In your README** — paste all three sections under a heading called `## Findings by Analysis Area` with Page 1, Page 2, Page 3 as subheadings.

**In interviews** — memorise the one-line version of each insight. The detail is there if they probe deeper but lead with the headline number every time.

**In your Loom video** — use the recommendation for Page 3 about the $36,000 re-engagement opportunity. Putting a dollar figure on a recommendation in a video walkthrough is the single most memorable thing you can do. Interviewers remember it.
