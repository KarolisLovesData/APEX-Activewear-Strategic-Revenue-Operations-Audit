"""
APEX Activewear - Interactive RAG SQL Generation Engine

This script initializes the Gemini API client, loads the compiled context dictionary,
and provides an interactive CLI workflow where users can ask business questions in natural language.
The system augments the request with governance rules, Dataform assertions, and database schemas,
ensuring the LLM generates compliant and production-ready BigQuery SQL.
"""

import json
import os
from google import genai
from dotenv import load_dotenv

# Load environment variables from local .env file
load_dotenv()

# Initialize the official Google GenAI client using the stored API key
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# Test the live connection to the Gemini API on startup
try:
    response = client.models.generate_content(
        model='gemini-3.5-flash',
        contents='Hello'
    )
    print("Live connection established!")

except Exception as e:
    print(f"Connection failed: {e}")


def load_context_payload():
    """Loads and parses the compiled JSON context dictionary containing schemas and rules."""
    with open('context_dictionary.json', 'r') as f:
        return json.load(f)


def clean_generated_sql(raw_sql):
    """
    Defensive Parsing: Strips away accidental markdown block wrappers
    (like ```sql ... ```) to ensure the output is 100% raw, runnable SQL.
    """
    cleaned = raw_sql.strip()

    # Remove opening Markdown wrapper if present
    if cleaned.startswith("```sql"):
        cleaned = cleaned[6:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]

    # Remove closing Markdown wrapper if present
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]

    return cleaned.strip()


def generate_sql(user_question: str):
    """The RAG Function: Augments the prompt with metadata and queries the LLM."""
    context = load_context_payload()

    # 1. Augmentation: Build the mega-prompt combining rules, assertions, and schemas
    system_instruction = f"""
    {chr(10).join(context['global_rules'])}

    DATAFORM ASSERTIONS (Strict Logic to Follow):
    {chr(10).join(context['dataform_assertions_reference'])}

    DATABASE SCHEMA (Only use these tables/columns):
    {json.dumps(context['tables'], indent=2)}

    Output ONLY valid BigQuery SQL. Do not include markdown formatting. Just the raw text.
    """

    prompt = f"System Rules:\n{system_instruction}\n\nUser Question:\n{user_question}"

    # Query the Gemini model with the fully constructed RAG prompt
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt
    )

    # Pass the raw response through our cleaning gate
    return clean_generated_sql(response.text)


if __name__ == "__main__":

    print("=============================================")
    print("APEX Activewear AI Governance Layer Active")
    print("=============================================\n")

    # Capture natural language business question from the user
    question = input("Dear APEXer please, ask a business question (or type 'exit' to quit):\n> ")

    # Process question and generate compliant SQL if user does not exit
    if question.lower() != 'exit':
        print("\nAnalyzing governance rules and generating SQL...\n")
        sql_result = generate_sql(question)

        print("Generated Production SQL:")
        print("---------------------------------------------")
        print(sql_result)
        print("---------------------------------------------")
