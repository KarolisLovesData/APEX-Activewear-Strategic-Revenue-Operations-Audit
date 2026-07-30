import pandas as pd
import json


def build_context():
    """Builds and exports the RAG context dictionary from governance and schema CSVs."""
    # 1. Load the metadata files
    gov_df = pd.read_csv('Apex Governance Layer.csv')
    schema_df = pd.read_csv('Apex Table Schemas.csv')

    # 2. Extract Dataform Assertions for Global LLM Rules
    assertions = gov_df[gov_df['asset_type'] == 'Assertion Logic']['governance_logic'].tolist()

    # Clean up the assertions to ensure they are all strings
    clean_assertions = [str(assertion) for assertion in assertions]

    # Define baseline guardrails and formatting rules for the LLM prompt context
    global_rules = [
        "You are an expert Data Analyst and Analytics Engineer for APEX Activewear.",
        "You are generating BigQuery Standard SQL.",
        "Where possible abstain from using self joins and subqueries, use CTEs and or QUALIFY clause"
        "Only query the tables explicitly provided in this context payload.",
        "Do not invent column names. Use exactly what is provided.",
        "CRITICAL: Adhere to the following business logic rules derived from Dataform assertions. If a user asks a question that violates these rules, correct it in the SQL:"
    ]

    # 3. Build Table Dictionary by mapping schemas to governance descriptions
    tables = []
    grouped = schema_df.groupby(['dataset_name', 'table_name'])

    for (dataset, table_name), group in grouped:
        # Match the table description from the governance CSV
        desc_row = gov_df[(gov_df['asset_name'] == table_name) & (gov_df['asset_type'] == 'Table Description')]

        # --- THE FIX IS HERE ---
        # We check if a description exists. If it does, we extract the first item (.iloc)
        # and explicitly convert it to a plain Python string using str()
        if not desc_row.empty:
            description = str(desc_row['governance_logic'].iloc)
        else:
            description = "No description provided."

        # Iterate through column rows to build the schema definition list for this table
        columns = []
        for _, row in group.iterrows():
            columns.append({
                "name": str(row['column_name']),
                "type": str(row['data_type'])
            })

        # Append the structured table metadata object
        tables.append({
            "table_name": f"{dataset}.{table_name}",
            "description": description.strip('"'),  # Now .strip() will work perfectly
            "columns": columns
        })

    # 4. Assemble final payload dictionary combining rules, assertions, and schemas
    context_dict = {
        "global_rules": global_rules,
        "dataform_assertions_reference": clean_assertions,
        "tables": tables
    }

    # 5. Export as a structured JSON file for the RAG engine consumption
    with open('context_dictionary.json', 'w') as f:
        json.dump(context_dict, f, indent=2)

    print("Success! context_dictionary.json has been generated.")


if __name__ == "__main__":
    build_context()
