#!/usr/bin/env python
# coding: utf-8

# # =============================================================
# # PHASE 3 — ECOMMERCE ANALYTICS: EDA + CHARTS
# # =============================================================
# # 

# In[ ]:


Charts produced:
#   1. Funnel waterfall          — session outcomes
#   2. Cohort retention heatmap — monthly retention %
#   3. Category quadrant        — traffic vs conversion scatter
#   4. RFM segment bubble       — segment size vs revenue
#   5. Hourly conversion        — best hours to convert
#   6. Price elasticity curve   — revenue by price decile
#   7. Cart abandonment         — top abandoned products
# =============================================================

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.ticker as mticker
import seaborn as sns
import numpy as np
import os
import warnings
warnings.filterwarnings("ignore")

# ─────────────────────────────────────────
# 0. CONFIG — update this path only
# ─────────────────────────────────────────
DATA_DIR   = r"C:\Users\Infinix\Desktop\ecommerce_project_python"   # ← change this
OUTPUT_DIR = os.path.join(DATA_DIR, "charts")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def path(filename):
    return os.path.join(DATA_DIR, filename)

def save(fig, filename):
    out = os.path.join(OUTPUT_DIR, filename)
    fig.savefig(out, dpi=180, bbox_inches="tight", facecolor=fig.get_facecolor())
    print(f"  saved → {out}")

# ─────────────────────────────────────────
# GLOBAL STYLE
# ─────────────────────────────────────────
BLUE    = "#2563EB"
TEAL    = "#0D9488"
CORAL   = "#E85D30"
AMBER   = "#D97706"
PURPLE  = "#7C3AED"
GRAY    = "#6B7280"
LIGHT   = "#F9FAFB"
BG      = "#FFFFFF"

plt.rcParams.update({
    "figure.facecolor"  : BG,
    "axes.facecolor"    : LIGHT,
    "axes.edgecolor"    : "#E5E7EB",
    "axes.spines.top"   : False,
    "axes.spines.right" : False,
    "axes.grid"         : True,
    "grid.color"        : "#E5E7EB",
    "grid.linewidth"    : 0.6,
    "font.family"       : "sans-serif",
    "font.size"         : 11,
    "axes.titlesize"    : 13,
    "axes.titleweight"  : "bold",
    "axes.labelsize"    : 11,
    "xtick.labelsize"   : 10,
    "ytick.labelsize"   : 10,
})

print("=" * 55)
print("  PHASE 3 — ECOMMERCE ANALYTICS CHARTS")
print("=" * 55)


# In[4]:


# =============================================================
# CHART 1 — FUNNEL WATERFALL (session outcomes)
# =============================================================
print("\n[1/7] Funnel waterfall...")

df_funnel = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m2_session_funnel.csv"), sep=",")
df_funnel.head()

# order: converted on top, then abandoned, then bounce
order_map = {
    "converted"      : 0,
    "abandoned_cart" : 1,
    "bounce_at_view" : 2
}
df_funnel["sort_key"] = df_funnel["session_outcome"].map(order_map)
df_funnel = df_funnel.sort_values("sort_key")

labels = {
    "converted"      : "Converted",
    "abandoned_cart" : "Abandoned cart",
    "bounce_at_view" : "Bounced at view"
}
colors = {
    "converted"      : TEAL,
    "abandoned_cart" : AMBER,
    "bounce_at_view" : CORAL
}

fig, ax = plt.subplots(figsize=(10, 5))
fig.patch.set_facecolor(BG)

bars = ax.barh(
    [labels.get(o, o) for o in df_funnel["session_outcome"]],
    df_funnel["sessions"],
    color=[colors.get(o, GRAY) for o in df_funnel["session_outcome"]],
    height=0.55,
    edgecolor="none"
)

total = df_funnel["sessions"].sum()
for bar, row in zip(bars, df_funnel.itertuples()):
    pct = row.pct_of_sessions
    sessions = row.sessions
    ax.text(
        bar.get_width() + total * 0.01,
        bar.get_y() + bar.get_height() / 2,
        f"{sessions:,.0f}  ({pct:.1f}%)",
        va="center", ha="left", fontsize=10, color="#374151"
    )

ax.set_xlabel("Number of sessions")
ax.set_title("Session funnel — where do users drop off?", pad=14)
ax.set_xlim(0, df_funnel["sessions"].max() * 1.25)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:,.0f}"))
ax.grid(axis="y", visible=False)

# annotation box
converted_pct = df_funnel.loc[
    df_funnel["session_outcome"] == "converted", "pct_of_sessions"
].values[0]
bounce_pct = df_funnel.loc[
    df_funnel["session_outcome"] == "bounce_at_view", "pct_of_sessions"
].values[0]

ax.annotate(
    f"Key insight: {bounce_pct:.1f}% of sessions\nnever add a single item to cart",
    xy=(0.98, 0.08), xycoords="axes fraction",
    ha="right", va="bottom", fontsize=9.5,
    color="#1F2937",
    bbox=dict(boxstyle="round,pad=0.4", facecolor="#FEF3C7", edgecolor="#D97706", linewidth=0.8)
)

plt.tight_layout()
save(fig, "01_funnel_waterfall.png")
plt.show()


# In[5]:


# =============================================================
# CHART 2 — COHORT RETENTION HEATMAP
# =============================================================
print("\n[2/7] Cohort retention heatmap...")

df_ret = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m5_cohort_retention.csv"), sep=",")

# pivot to heatmap format: rows = cohort_month, cols = months_since_first
pivot = df_ret.pivot(
    index="cohort_month",
    columns="months_since_first",
    values="retention_pct"
)

# format cohort month labels cleanly
pivot.index = pd.to_datetime(pivot.index).strftime("%b %Y")
pivot.columns = [f"Month {int(c)}" for c in pivot.columns]

fig, ax = plt.subplots(figsize=(max(8, len(pivot.columns) * 1.4), max(4, len(pivot) * 0.9 + 1.5)))
fig.patch.set_facecolor(BG)

mask = pivot.isnull()

sns.heatmap(
    pivot,
    ax=ax,
    annot=True,
    fmt=".1f",
    cmap=sns.color_palette("Blues", as_cmap=True),
    linewidths=0.5,
    linecolor="#E5E7EB",
    cbar_kws={"label": "Retention %", "shrink": 0.7},
    mask=mask,
    vmin=0,
    vmax=100,
    annot_kws={"size": 10, "weight": "bold"}
)

ax.set_title("Cohort retention heatmap — % of users who purchased again", pad=14)
ax.set_xlabel("Months since first purchase")
ax.set_ylabel("Acquisition cohort")
ax.tick_params(axis="x", rotation=0)
ax.tick_params(axis="y", rotation=0)

# add cohort size annotation on left
cohort_sizes = df_ret[df_ret["months_since_first"] == 0].set_index("cohort_month")["cohort_users"]
cohort_sizes.index = pd.to_datetime(cohort_sizes.index).strftime("%b %Y")
for i, (month, size) in enumerate(cohort_sizes.items()):
    ax.text(
        -0.3, i + 0.5,
        f"n={size:,}",
        ha="right", va="center", fontsize=8.5,
        color=GRAY, transform=ax.get_yaxis_transform()
    )

plt.tight_layout()
save(fig, "02_cohort_retention_heatmap.png")
plt.show()


# In[6]:


# =============================================================
# CHART 3 — CATEGORY QUADRANT SCATTER
# (traffic vs conversion — the "opportunity" visual)
# =============================================================
print("\n[3/7] Category quadrant scatter...")

df_cat = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m4_category_quadrant.csv"), sep=",")
df_cat = df_cat.dropna(subset=["views", "conversion_rate_pct", "category_code"])

quadrant_colors = {
    "Star — high traffic, high CVR"        : TEAL,
    "Opportunity — high traffic, low CVR"  : CORAL,
    "Niche — low traffic, high CVR"        : PURPLE,
    "Underdog — low traffic, low CVR"      : GRAY
}

fig, ax = plt.subplots(figsize=(12, 7))
fig.patch.set_facecolor(BG)

avg_views = df_cat["views"].mean()
avg_cvr   = df_cat["conversion_rate_pct"].mean()

# quadrant shading
ax.axvspan(0,        avg_views, ymin=0.5, ymax=1.0, alpha=0.04, color=PURPLE)
ax.axvspan(avg_views, df_cat["views"].max() * 1.15, ymin=0.5, ymax=1.0, alpha=0.04, color=TEAL)
ax.axvspan(0,        avg_views, ymin=0,   ymax=0.5, alpha=0.04, color=GRAY)
ax.axvspan(avg_views, df_cat["views"].max() * 1.15, ymin=0,   ymax=0.5, alpha=0.06, color=CORAL)

# crosshair lines
ax.axvline(avg_views, color="#9CA3AF", linewidth=1, linestyle="--", alpha=0.7)
ax.axhline(avg_cvr,   color="#9CA3AF", linewidth=1, linestyle="--", alpha=0.7)

for _, row in df_cat.iterrows():
    q     = row["quadrant"]
    color = quadrant_colors.get(q, GRAY)
    size  = np.clip(row["views"] / df_cat["views"].max() * 600, 40, 600)
    ax.scatter(row["views"], row["conversion_rate_pct"],
               s=size, color=color, alpha=0.75, edgecolors="white", linewidth=0.8, zorder=3)

# label top categories only (avoid clutter)
top_n = df_cat.nlargest(8, "views")
for _, row in top_n.iterrows():
    short = row["category_code"].split(".")[-1] if "." in row["category_code"] else row["category_code"]
    ax.annotate(
        short,
        xy=(row["views"], row["conversion_rate_pct"]),
        xytext=(6, 4), textcoords="offset points",
        fontsize=8.5, color="#1F2937",
        bbox=dict(boxstyle="round,pad=0.2", facecolor="white", edgecolor="#E5E7EB", linewidth=0.5)
    )

# quadrant labels
xmax = df_cat["views"].max() * 1.12
ymax = df_cat["conversion_rate_pct"].max()
ymin = df_cat["conversion_rate_pct"].min()
ax.text(avg_views * 0.05, ymax * 0.95, "Niche",        fontsize=9, color=PURPLE, alpha=0.7, style="italic")
ax.text(xmax * 0.6,       ymax * 0.95, "Stars ★",      fontsize=9, color=TEAL,   alpha=0.7, style="italic")
ax.text(avg_views * 0.05, avg_cvr * 0.3, "Underdog",   fontsize=9, color=GRAY,   alpha=0.7, style="italic")
ax.text(xmax * 0.6,       avg_cvr * 0.3, "Opportunity ↑", fontsize=9, color=CORAL, alpha=0.7, style="italic")

legend_patches = [
    mpatches.Patch(color=c, label=l, alpha=0.8)
    for l, c in quadrant_colors.items()
]
ax.legend(handles=legend_patches, loc="upper right", fontsize=8.5,
          framealpha=0.9, edgecolor="#E5E7EB")

ax.set_xlabel("Total views (traffic volume)")
ax.set_ylabel("Conversion rate %")
ax.set_title("Category quadrant — traffic vs conversion rate", pad=14)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:,.0f}"))

plt.tight_layout()
save(fig, "03_category_quadrant.png")
plt.show()


# In[7]:


# =============================================================
# CHART 4 — RFM SEGMENT BUBBLE CHART
# =============================================================
print("\n[4/7] RFM segment bubble chart...")

df_rfm = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m6_rfm_segments.csv"), sep=",")

segment_colors = {
    "Champions"          : TEAL,
    "Loyal customers"    : BLUE,
    "New customers"      : PURPLE,
    "Potential loyalists": "#8B5CF6",
    "At-risk"            : AMBER,
    "Cannot lose them"   : CORAL,
    "Lost"               : "#EF4444",
    "Needs attention"    : GRAY
}

fig, ax = plt.subplots(figsize=(11, 6))
fig.patch.set_facecolor(BG)

max_revenue = df_rfm["total_segment_revenue"].max()

for _, row in df_rfm.iterrows():
    size  = (row["total_segment_revenue"] / max_revenue) * 3000 + 100
    color = segment_colors.get(row["segment"], GRAY)
    ax.scatter(
        row["avg_recency_days"],
        row["avg_revenue_per_user"],
        s=size,
        color=color,
        alpha=0.80,
        edgecolors="white",
        linewidth=1.2,
        zorder=3
    )
    ax.annotate(
        f"{row['segment']}\n({row['user_count']:,.0f} users)",
        xy=(row["avg_recency_days"], row["avg_revenue_per_user"]),
        xytext=(0, 14), textcoords="offset points",
        ha="center", fontsize=8.5, color="#1F2937",
        bbox=dict(boxstyle="round,pad=0.25", facecolor="white",
                  edgecolor="#E5E7EB", linewidth=0.5)
    )

ax.set_xlabel("Avg recency (days since last purchase) →  more recent = left")
ax.set_ylabel("Avg revenue per user ($)")
ax.set_title("RFM segments — size = total segment revenue", pad=14)
ax.invert_xaxis()   # recent buyers on the right visually

ax.annotate(
    "Bubble size = total revenue contribution\nof that segment",
    xy=(0.98, 0.05), xycoords="axes fraction",
    ha="right", fontsize=8.5, color=GRAY,
    bbox=dict(boxstyle="round,pad=0.3", facecolor=LIGHT, edgecolor="#E5E7EB")
)

plt.tight_layout()
save(fig, "04_rfm_segments.png")
plt.show()


# In[8]:


# =============================================================
# CHART 5 — HOURLY CONVERSION RATE
# =============================================================
print("\n[5/7] Hourly conversion rate...")

df_hourly = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m2_hourly_conversion.csv"), sep=",")
df_hourly = df_hourly.sort_values("hour_of_day")

fig, ax1 = plt.subplots(figsize=(12, 5))
fig.patch.set_facecolor(BG)

# bar — views volume
ax1.bar(
    df_hourly["hour_of_day"],
    df_hourly["views"],
    color=BLUE, alpha=0.25, width=0.7, label="Views (left axis)"
)
ax1.set_xlabel("Hour of day (24h)")
ax1.set_ylabel("View volume", color=BLUE)
ax1.tick_params(axis="y", labelcolor=BLUE)
ax1.set_xticks(range(0, 24))

# line — conversion rate
ax2 = ax1.twinx()
ax2.plot(
    df_hourly["hour_of_day"],
    df_hourly["conversion_rate_pct"],
    color=CORAL, linewidth=2.5, marker="o",
    markersize=5, label="Conversion rate % (right axis)", zorder=4
)
ax2.set_ylabel("Conversion rate %", color=CORAL)
ax2.tick_params(axis="y", labelcolor=CORAL)
ax2.spines["right"].set_visible(True)
ax2.spines["right"].set_color("#E5E7EB")

# highlight peak conversion hour
peak_hour = df_hourly.loc[df_hourly["conversion_rate_pct"].idxmax(), "hour_of_day"]
peak_cvr  = df_hourly["conversion_rate_pct"].max()
ax2.annotate(
    f"Peak: {peak_cvr:.2f}%\nat {int(peak_hour):02d}:00",
    xy=(peak_hour, peak_cvr),
    xytext=(peak_hour + 1.5, peak_cvr * 1.05),
    arrowprops=dict(arrowstyle="->", color=CORAL, lw=1.2),
    fontsize=9, color=CORAL
)

ax1.set_title("Hourly traffic vs conversion rate — when do users convert best?", pad=14)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper left", fontsize=9,
           framealpha=0.9, edgecolor="#E5E7EB")

plt.tight_layout()
save(fig, "05_hourly_conversion.png")
plt.show()


# In[9]:


# =============================================================
# CHART 6 — PRICE ELASTICITY CURVE
# =============================================================
print("\n[6/7] Price elasticity curve...")

df_price = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m3_price_elasticity.csv"), sep=",")
df_price = df_price.sort_values("price_decile")

fig, ax1 = plt.subplots(figsize=(11, 5))
fig.patch.set_facecolor(BG)

# bar — purchase count
ax1.bar(
    df_price["price_decile"],
    df_price["purchases"],
    color=PURPLE, alpha=0.3, width=0.6, label="Purchases (left axis)"
)
ax1.set_xlabel("Price decile (1 = cheapest 10%, 10 = most expensive 10%)")
ax1.set_ylabel("Number of purchases", color=PURPLE)
ax1.tick_params(axis="y", labelcolor=PURPLE)
ax1.set_xticks(df_price["price_decile"])

# line — total revenue
ax2 = ax1.twinx()
ax2.plot(
    df_price["price_decile"],
    df_price["total_revenue"],
    color=AMBER, linewidth=2.5, marker="s",
    markersize=5, label="Total revenue (right axis)", zorder=4
)
ax2.set_ylabel("Total revenue ($)", color=AMBER)
ax2.tick_params(axis="y", labelcolor=AMBER)
ax2.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
ax2.spines["right"].set_visible(True)
ax2.spines["right"].set_color("#E5E7EB")

# price range labels on x axis
if "decile_min" in df_price.columns and "decile_max" in df_price.columns:
    xtick_labels = [
        f"D{int(row.price_decile)}\n${row.decile_min:.0f}–${row.decile_max:.0f}"
        for _, row in df_price.iterrows()
    ]
    ax1.set_xticklabels(xtick_labels, fontsize=8)

ax1.set_title("Price elasticity — purchases and revenue by price decile", pad=14)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper right",
           fontsize=9, framealpha=0.9, edgecolor="#E5E7EB")

plt.tight_layout()
save(fig, "06_price_elasticity.png")
plt.show()


# In[10]:


# =============================================================
# CHART 7 — CART ABANDONMENT (top 15 products)
# =============================================================
print("\n[7/7] Cart abandonment...")

df_abandon = pd.read_csv(path(r"C:\Users\Infinix\Downloads\m2_cart_abandonment.csv"), sep=",")
df_abandon = df_abandon.sort_values("abandonment_rate_pct", ascending=False).head(15)

fig, ax = plt.subplots(figsize=(11, 6))
fig.patch.set_facecolor(BG)

colors_bar = [
    CORAL if r >= 80 else AMBER if r >= 60 else TEAL
    for r in df_abandon["abandonment_rate_pct"]
]

bars = ax.barh(
    df_abandon["product_id"].astype(str),
    df_abandon["abandonment_rate_pct"],
    color=colors_bar, height=0.6, edgecolor="none"
)

for bar, row in zip(bars, df_abandon.itertuples()):
    ax.text(
        bar.get_width() + 0.5,
        bar.get_y() + bar.get_height() / 2,
        f"{row.abandonment_rate_pct:.1f}%  ({row.times_carted:,} carted)",
        va="center", ha="left", fontsize=9, color="#374151"
    )

ax.set_xlabel("Cart abandonment rate %")
ax.set_ylabel("Product ID")
ax.set_title("Top 15 products by cart abandonment rate", pad=14)
ax.set_xlim(0, 115)
ax.grid(axis="y", visible=False)

legend_patches = [
    mpatches.Patch(color=CORAL, label="≥ 80% abandoned"),
    mpatches.Patch(color=AMBER, label="60–80% abandoned"),
    mpatches.Patch(color=TEAL,  label="< 60% abandoned"),
]
ax.legend(handles=legend_patches, loc="lower right", fontsize=9,
          framealpha=0.9, edgecolor="#E5E7EB")

plt.tight_layout()
save(fig, "07_cart_abandonment.png")
plt.show()


# In[11]:


# =============================================================
# SUMMARY STATS — print to console for quick reference
# =============================================================
print("\n" + "=" * 55)
print("  SUMMARY STATS")
print("=" * 55)

# funnel
converted = df_funnel.loc[df_funnel["session_outcome"] == "converted", "sessions"].values[0]
total_sessions = df_funnel["sessions"].sum()
print(f"\nFunnel:")
print(f"  Total sessions        : {total_sessions:,}")
print(f"  Converted sessions    : {converted:,}  ({converted/total_sessions*100:.1f}%)")

# retention
month1 = df_ret[df_ret["months_since_first"] == 1]
if not month1.empty:
    avg_m1 = month1["retention_pct"].mean()
    print(f"\nRetention:")
    print(f"  Month-1 avg retention : {avg_m1:.1f}%")

# rfm
champs = df_rfm[df_rfm["segment"] == "Champions"]
if not champs.empty:
    champ_rev_pct = champs["total_segment_revenue"].values[0] / df_rfm["total_segment_revenue"].sum() * 100
    print(f"\nRFM:")
    print(f"  Champions revenue share : {champ_rev_pct:.1f}%")
    print(f"  Champions user count    : {champs['user_count'].values[0]:,}")

print(f"\nAll charts saved to: {OUTPUT_DIR}")
print("=" * 55)


# In[ ]:




