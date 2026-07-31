"""
APEX Activewear - RAG Context Builder Engine

This script parses upstream data governance metadata and BigQuery schema definitions,
extracts active Dataform assertions and architectural guardrails, and exports a 
structured JSON context dictionary used by the Gemini RAG SQL generation engine.
"""

import json
import pandas as pd


def build_context():
    """
    Reads governance and schema CSVs, compiles system rules and Dataform 
    assertions, and exports a standardized JSON payload for downstream LLM prompts.
    """
    # 1. Load data governance rules and table schemas from CSV sources
    gov_df = pd.read_csv('Apex Governance Layer.csv')
    schema_df = pd.read_csv('Apex Table Schemas.csv')

    # 2. Extract active Dataform assertions to serve as global LLM business logic rules
    assertions = gov_df[gov_df['asset_type'] == 'Assertion Logic']['governance_logic'].tolist()

    # Clean up assertions to ensure every entry is formatted as a valid string
    clean_assertions = [str(assertion) for assertion in assertions]

    # Define foundational BigQuery generation guardrails and LLM prompt instructions
    global_rules = [
        "You are an expert Data Analyst and Analytics Engineer for APEX Activewear.",
        "You are generating BigQuery Standard SQL.",
        "Where possible abstain from using self joins and subqueries, use CTEs and or QUALIFY clause.",
        "Only query the tables explicitly provided in this context payload.",
        "Do not invent column names. Use exactly what is provided.",
        "CRITICAL: Adhere to the following business logic rules derived from Dataform assertions. If a user asks a question that violates these rules, correct it in the SQL:"
    ]

    # 3. Build structured table dictionary mapping schemas to governance descriptions
    tables = []
    grouped = schema_df.groupby(['dataset_name', 'table_name'])

    for (dataset, table_name), group in grouped:
        # Match table-level description from governance metadata
        desc_row = gov_df[(gov_df['asset_name'] == table_name) & (gov_df['asset_type'] == 'Table Description')]

        # Extract table description if present; fallback gracefully if missing
        if not desc_row.empty:
            description = str(desc_row['governance_logic'].iloc[0])
        else:
            description = "No description provided."

        # Iterate through column rows to construct field schema definitions
        columns = []
        for _, row in group.iterrows():
            columns.append({
                "name": str(row['column_name']),
                "type": str(row['data_type'])
            })

        # Append fully structured dataset and table metadata object
        tables.append({
            "table_name": f"{dataset}.{table_name}",
            "description": description.strip('"'),
            "columns": columns
        })

    # 4. Assemble final payload dictionary combining system rules, assertions, and schemas
    context_dict = {
        "global_rules": global_rules,
        "dataform_assertions_reference": clean_assertions,
        "tables": tables
    }

    # 5. Export structured payload as a JSON artifact for the interactive RAG engine
    with open('context_dictionary.json', 'w') as f:
        json.dump(context_dict, f, indent=2)

    print("Success! context_dictionary.json has been generated.")


if __name__ == "__main__":
    build_context()
