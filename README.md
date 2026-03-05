# APEX-Activewear-Strategic-Revenue-Operations-Audit

# Executive Summary

**APEX Activewear** has reached a pivotal operational crossroads.

Having successfully scaled to **$48.85M in lifetime revenue** between **January 2023 and early 2026** across **422,000 orders**, we have proven our market fit across the **United States**, our core market, **Mexico**, and **Canada**.

However, while our unit economics remain premium (**$148 AOV, 53.9% Gross Margin**), our ability to continue scaling through volume alone has stalled. To identify the specific friction points hindering our next phase of expansion, a diagnostic audit of the revenue engine was conducted. This analysis moved beyond surface-level performance to reveal four structural risks that aggregate metrics were obscuring.

*[*View Executive Summary SQL Query*](models/gold/Executive_Summary.sql)*

# Data Architecture & Scope 

To perform this audit, I built a relational data model that connects the entire customer lifecycle—from the initial website visit to the final delivery and potential return. By linking marketing events, transactions, and logistics, I created a **"source of truth"** to identify specific friction points where revenue was leaking and margins were being eroded. (Note: the tables in the ERD are the **Staging Layer** (the stg_ nodes), see the **Directed Acyclic Graph (DAG)** and full **Medallion Transformation** flow in the Analytics Engineering section.)  
