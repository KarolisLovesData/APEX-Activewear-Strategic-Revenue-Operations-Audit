
# APEX-Activewear-Strategic-Revenue-Operations-Audit

**NOTE:** This is a comprehensive portfolio project utilizing a simulated enterprise dataset. The metrics, company names, and financial figures were constructed to demonstrate production-grade Analytics Engineering, Medallion Architecture, and business-focused data modeling.

## Table of Contents
* [Executive Summary & Business Impact](#executive-summary)
* [Data Architecture & Scope](#data-architecture)
* [Key Findings: The "Profit Paradox"](#key-findings)
* [I. Structural Fractures (Revenue Leakage)](#structural-fractures)
  * [1. Critical Attribution Leakage (The "Dark Traffic" Crisis)](#attribution-leakage)
  * [2. Network-Wide Fulfillment Optimization](#fulfillment-optimization)
* [II. Dormant Opportunities (Value Unlocks)](#dormant-opportunities)
  * [1. The "First Order" Multiplier (LTV Optimization)](#first-order-multiplier)
  * [2. RFM Strategic Insight: Reclaiming & Scaling](#rfm-insight)
  * [3. Predictive AI: The "Sleeping Giant" Intercept](#predictive-ai)
* [🛠️ Analytics Engineering & Data Quality](#analytics-engineering)
  * [Technical Implementation: Production-Grade Data Pipeline](#tech-implementation)
  * [Core Technology Stack](#core-stack)
  * [Infrastructure & Cost Optimization](#infrastructure)
  * [Defensive Data Modeling & Guardrails](#guardrails)
  * [Challenges and Roadblocks](#edge-case)

***

# <a id="executive-summary"></a>Executive Summary & Business Impact

**APEX Activewear** has reached a pivotal operational crossroads. As a premier retailer specializing in high-performance alpine outerwear, technical footwear, and adventure-ready gear, we have successfully scaled to **$48.85M in realized lifetime revenue** (net of returns and cancellations) between January 2023 and early 2026. With over **436K+** orders processed, we have proven our market fit across the United States, Mexico, and Canada, establishing solid unit economics that include a **$148 AOV** and a **53.9% Gross Margin** on retained sales.

**Business Problem:** Despite strong foundational metrics, growth has stalled from 344% YoY to just 9.8%. A diagnostic audit of the revenue engine revealed four structural risks obscuring profitability. **[Access SQL Queries](Strategic_Insights/Executive_Summary.sql)**

**Key Deliverables & Identified ROI:**
* **$34.3M Attribution Recovery:** Diagnosed mid-funnel session breaks causing 68% of revenue to be misattributed to "Direct" traffic.
* **$33.3M Retention Target:** Deployed RFM segmentation to isolate dormant "Sleeping Giant" users globally.
* **Predictive Churn Automation:** Engineered an in-warehouse XGBoost machine learning model to intercept churning users *before* they go dormant.
* **21% Fulfillment Speed Gain:** Proposed a 'Clean Flow' protocol to cut delivery lag from 5.1 to 4.1 days.

***

# <a id="data-architecture"></a>Data Architecture & Scope 

To perform this audit, a relational data model was built to connect the entire customer lifecycle—from the initial website visit to the final delivery and potential return. By linking marketing events, transactions, and logistics, I created a **"source of truth"** to identify specific friction points where revenue was leaking and margins were being eroded. (Note: the tables in the ERD are the **Staging Layer** (the stg_ nodes), see the **Directed Acyclic Graph (DAG)** and full **Medallion Transformation** flow in the [Analytics Engineering section](#analytics-engineering).) 

**APEX Activewear Entity Relationship Diagram:**
<img src="./Visuals/apex_activewear_erd.png" alt="Apex Activewear ERD" width="800">

**Audit Scale & Data Volume:**
* _stg_online_events_ (fact table): **1.33M** online events and user touchpoints captured.
* _stg_orders_: **436K+** orders analyzed split across **122K+** unique users in the _stg_users_ table.
* _stg_order_items_ (fact table): **544K+** order records processed across the US, Canada, and Mexico.
* _stg_products_: performance and return-rate data for over **2000** unique SKUs.
* _stg_distribution_centers_: integration with data from **11** distribution centers to reconcile realized revenue against operational costs.

***

# <a id="key-findings"></a>Key Findings: The "Profit Paradox"

* **Growth Deceleration:** Momentum dropped from a peak of **344%** (Q2 2023) to just **9.8%** (Q4 2025). Future revenue gains must now come from maximizing customer Lifetime Value (LTV) rather than relying on new order volume. 🔗 **[Access SQL Queries](Strategic_Insights/Key_Findings__Growth_Deceleration.sql)**
  <br><img src="./Visuals/APEX Growth.png" alt="APEX Growth" width="600">

* **Critical Attribution Leakage:** We are "flying blind" on **68.3%** of total revenue. Mid-funnel tracking breaks mean we cannot trace the ROI on **~$34.3M** of revenue, leading to massive inefficiencies in paid ad spend. 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Critical_Attribution_Leakage.sql)**
  <br><img src="./Visuals/Revenue_by_traffic_source.png" alt="Revenue by traffic source" width="600">

* **Category-Specific Profit Drag:** Men's Alpine Outerwear is our top revenue driver, but incurs **$3.2M** in return losses. Across top categories, a **~24% total loss rate** (returns + cancellations) means one-quarter of operational effort generates zero realized revenue. 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Category-Specific_Profit_Drag.sql)**
  <br><img src="./Visuals/APEX_product_leakage.png" alt="Product leakage" width="600">

* **Systemic Retention Risk:** The US market is saturated (76.3% of revenue). Furthermore, our RFM segmentation reveals **$33.3M** in lifetime revenue is trapped globally in the dormant "At Risk / Can't Lose" segment, proving retention mechanics are failing across all borders. 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Geographic_Saturation.sql)**

**The Strategic Pivot:** The data confirms APEX must transition to a value-driven model. The rest of this audit targets two specific areas to execute this pivot:
1. **Structural Fractures:** Identifying silent operational errors (Attribution & Logistics) leaking revenue.
2. **Dormant Opportunities:** Exploiting RFM segments and AI models to reclaim LTV and scale profitably.

***

# <a id="structural-fractures"></a>I. Structural Fractures (Revenue Leakage)

### <a id="attribution-leakage"></a>1. Critical Attribution Leakage (The "Dark Traffic" Crisis)
**Stakeholder:** CMO & Data Engineering Lead | **Priority:** 🔴 CRITICAL

**📊 Key Metrics:**
* **Impacted Revenue:** ~$34.3M (68.4% of total revenue is currently untraceable)
* **Traffic Split:** 53.5% "Direct" | 14.9% "Unattributed"
* **Signal Loss:** 100% of "Direct" buyers showed 0 Product Views prior to checkout.

**The Insight:** **Genuine users do not "teleport" to checkout**; they browse. The complete absence of funnel history for 225k+ orders proves the **digital thread is severing mid-session**. This is not just a reporting issue; it means we are **starving our paid ad algorithms** (Meta/Google) of conversion data, **artificially inflating our Customer Acquisition Cost (CAC)**. 🔗 **[Access SQL Queries](Strategic_Insights/Structural_Fractures_(Revenue_Leakage).sql)**
<br><img src="Visuals/Impossible_funnel.png" alt="Impossible funnel" width="600">

**Strategic Action:** Execute an immediate Tech Audit on the "Session-Break Triad":
1. Whitelist payment gateways (PayPal, Stripe) to prevent referral overwriting.
2. Verify cross-domain cookie persistence between the main shop and checkout subdomain.
3. Ensure 301 redirects are not stripping UTM parameters.

**Business Impact:** Re-attributing ~$34.3M to its true source, allowing marketing to scale budgets based on **True ROAS** rather than blended averages.

### <a id="fulfillment-optimization"></a>2. Network-Wide Fulfillment Optimization
**Stakeholder:** COO & Supply Chain Lead | **Priority:** 🟠 HIGH

**📊 Key Metrics:**
* **Avg Shipping Time:** 2.1 Days (Target: <1 Day)
* **Return Rate:** 21.62% 
* **Effective Capacity Loss:** ~22% of warehouse labor is tied up in reverse logistics.

**The Insight:** Our supply chain is fighting a civil war. Decomposing the delivery timeline reveals that **inbound returns are actively cannibalizing outbound sales capacity**. Our distribution centers are **prioritizing inventory restocking over revenue capture**, creating a **universal 2.1-day fulfillment lag**. 🔗 **[Access SQL Queries](Strategic_Insights/Structural_Fracture_2.Network_Wide_Fulfillment_Optimization.sql)**
<br><img src="Visuals/APEX_fulfillment.png" alt="Fulfillment delays" width="600">

**Strategic Action:** Implement a **'Clean Flow' SOP**: a strict operational decoupling that mandates all outbound orders clear in <24 hours before labor shifts to returns processing. Launch a 4-week pilot in Reno, NV to stress-test this protocol.

**Business Impact:** Compresses total fulfillment cycle time from 5.1 to 4.1 days (a **21%** speed gain) without requiring costly carrier shipping upgrades.

***

# <a id="dormant-opportunities"></a>II. Dormant Opportunities (Value Unlocks)

### <a id="first-order-multiplier"></a>1. The "First Order" Multiplier (LTV Optimization)
**Stakeholder:** Head of Growth | **Priority:** 🟠 HIGH

**📊 Key Metrics:**
* **High-Value LTV:** $516 (Triggered when Initial Order >$90) 
* **Low-Value LTV:** $330 (Triggered when Initial Order <$90)
* **Retention Reality:** Drops to 4.29% by Month 4 across *all* segments.

**The Insight:** Customer retention degrades structurally regardless of how much they spend; the **"leaky bucket" is a reality of our model**. However, **First Order Value is a massive predictor of lifetime worth**. Customers starting with a basket >$90 generate a **56% lift in LTV**, yet share the exact same churn curve as low-value buyers. **Loyalty is static, but entry point is dynamic.** 🔗 **[Access SQL Queries](Strategic_Insights/The_First_Order_Multiplier.sql)**
<br><img src="Visuals/LTVs.png" alt="LTV curves" width="600">

**Strategic Action:** Transition from Generic Conversion to **Threshold Engineering**. Replace flat acquisition discounts with Tiered Thresholds (e.g., "Save $20 on Orders >$100") to force users to self-select into the High-Value tier on Day 1.

**Business Impact:** Unlocks $185 incremental LTV per user. Nudging just 1,000 baseline users across this threshold generates $185,000 in risk-free revenue without acquiring a single extra customer.

### <a id="rfm-insight"></a>2. RFM Strategic Insight: Reclaiming & Scaling
**Stakeholder:** Head of Retention | **Global Revenue Impact:** ~$39M

By dividing our 122k+ user base into **actionable RFM (Recency, Frequency, Monetary) cohorts**, we isolated **three segments requiring distinct, data-driven interventions**. 🔗 **[Access SQL Queries](Strategic_Insights/rfm_strategic_insights.sql)**
<br><img src="Visuals/APEX_RFM.png" alt="RFM Segments" width="600">

**A. The "Sleeping Giant" (Reactivation)** | **Priority:** 🔴 CRITICAL
* **The Problem:** **$33.3M in dormant revenue** is tied to 53k users in the "At Risk / Can't Lose" segment.
* **The Action:** Deploy an **SMS-first "Pending Credit" sequence** utilizing loss aversion (e.g., *"Your $50 store credit expires tomorrow"*). Dynamically localize language for MX and CA segments.
* **The Impact:** Even a conservative 10% win-back rate **reclaims ~$3.33M in lost revenue**.

**B. The "Tipping Point" (Upsell)** | **Priority:** 🟠 HIGH
* **The Problem:** A **"Missing Middle" of 10,996 active users** ($380 Avg LTV) who haven't reached the "Loyal" tier ($890 Avg LTV). 
* **The Action:** Deploy highly targeted "Complete the Set" or bundle offers to **artificially inflate AOV** and push them across the monetary loyalty threshold.
* **The Impact:** Migrating just 20% of this group to the Loyal tier **generates ~$1.1M in incremental LTV**.

**C. Cloning the Champions (Acquisition)** | **Priority:** 🟡 MEDIUM
* **The Problem:** We **only have 122 "Champion" users** in Canada and Mexico—far too few to achieve statistical significance for ad pixel training. 
* **The Action:** **Merge "Champions" ($1,402 LTV) with "Loyal Customers" ($890 LTV)** to build a statistically stable global seed audience of 6,663 users. 
* **The Impact:** Provides ad algorithms with the critical mass of data needed to **reliably clone high-value users** in international markets.

### <a id="predictive-ai"></a>3. Predictive AI: The "Sleeping Giant" Intercept
**Stakeholder:** Head of Retention | **Technology:** BigQuery ML (XGBoost)

**The Insight:** Relying solely on RFM segmentation is inherently reactive; by the time a user is classified as a "Sleeping Giant," they have already been dormant for 6 months. To shift from reactive win-backs to preemptive intervention, I engineered an in-warehouse predictive classifier to identify users *before* they churn.

**Strategic Action & Technical Implementation:**
* **Point-in-Time Feature Engineering:** Constructed a 30-day snapshotting window in SQL to prevent data leakage, forcing the AI to learn from historical features (Frequency, Return Rates, Delivery Latency) exactly as they appeared prior to the churn event.
* **In-Warehouse ML:** Leveraged BigQuery ML to train an XGBoost classifier (`BOOSTED_TREE_CLASSIFIER`) directly on the Silver layer, eliminating the need for brittle external Python data pipelines. 
* **Model Evaluation & Data Limitations:** The end-to-end predictive pipeline is fully operational. However, because the underlying dataset was synthetically generated with random distributions, the model achieved a baseline ROC AUC of 0.51. This served as a perfect real-world demonstration of a core data science principle: advanced algorithms cannot manufacture signal from random noise. 

**Business Impact:** The pipeline is now perfectly staged to ingest real production data. Utilizing automated hyperparameter tuning, it generates a daily "Live Risk List," allowing marketing to trigger the $50 SMS credit preemptively during the critical 30-day window before dormancy.

***

# <a id="analytics-engineering"></a>🛠️ Analytics Engineering & Data Quality

### <a id="tech-implementation"></a>Technical Implementation: Production-Grade Data Pipeline
Architected a scalable Medallion pipeline (**Google Cloud Dataform, BigQuery**) delivering reliable C-Suite metrics (LTV, Fulfillment Latency, RFM). Enforced a strict `stg_` ➔ `int_` ➔ `mart_` DAG progression, centralizing business logic in the Silver layer to eliminate downstream metric drift. 

<img src="Visuals/APEX_Activewear Data_Lineage.png" alt="DAG" width="600"> 

### <a id="core-stack"></a>Core Technology Stack
**Google Cloud Platform (GCP), BigQuery ML, Cloud Dataform (SQLX/Medallion), Advanced SQL, Python, Gemini 3.1**

### <a id="infrastructure"></a>Infrastructure & Cost Optimization
Engineered for "Day 1 Scalability" to support petabyte-scale expansion from a 300MB baseline without structural redesign.
* **Partitioning & Clustering:** Partitioned tables by time columns to optimize query scans, applied `TIMESTAMP_TRUNC` to manage high-cardinality data and avoid the 4,000-partition limit. Clustered on low-cardinality IDs to prevent block fragmentation.
* **Dimension Strategy:** Configured low-cardinality reference tables (`stg_distribution_centers`, `stg_products`) as unpartitioned views to eliminate metadata overhead and small-file fragmentation.
* **Event-Driven Ingestion (Bronze):** Deployed GCS-triggered Cloud Functions for landing files. Centralized source declarations via Dataform JS configs (`bronze_sources.js`) to insulate against upstream schema breaks.

### <a id="guardrails"></a>Defensive Data Modeling & Guardrails
Deployed automated **Dataform Assertions** and defensive SQL to guarantee 100% schema integrity before data reaches the Gold (Mart) layer:
* **Circuit Breakers & Integrity:** Built a "Dark Traffic" alert that halts updates if `traffic_source = 'Direct'` exceeds 20% of revenue. Enforced strict null checks on primary keys to prevent "Ghost Revenue."
* **Temporal Logic Locks:** Validated chronological integrity (`created_at` ➔ `shipped_at` ➔ `delivered_at`). Applied `COALESCE` and `GREATEST` to handle null timestamps and protect financial averages.
* **Financial Guardrails:** Locked `is_realized_revenue` to valid business statuses and implemented defensive casting (`returned_at` to `TIMESTAMP`) for bulletproof downstream joins.
* **Attribution QA:** Monitored the 5-minute session-stitching window using safe joins to flag unmapped purchase events and prevent attribution leakage.

### <a id="edge-case"></a>Challenges and Roadblocks
* **The Edge Case:** Logistical assertions flagged 509 order items (out of ~545k) where `returned_at` preceded `delivered_at` (e.g., carrier "Return to Sender" events).
* **The Solution & Impact:** Instead of silently filtering anomalies in Staging—which skews source-to-warehouse record counts—I engineered a `has_timeline_anomaly` boolean flag in the Silver layer. This preserved raw data for logistics QA while allowing Gold layer LTV models to cleanly bypass bad records via `WHERE has_timeline_anomaly = FALSE`.

