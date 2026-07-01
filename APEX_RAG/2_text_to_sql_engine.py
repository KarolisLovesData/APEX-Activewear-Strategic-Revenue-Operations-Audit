import json
import os
from google import genai
from dotenv import load_dotenv


load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

try:
    response = client.models.generate_content(
        model='gemini-3.5-flash',
        contents='Hello'
    )
    print("Live connection established!")

except Exception as e:
    print(f"Connection failed: {e}")

def load_context_payload():

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
    """The RAG Function: Augments the prompt and queries the LLM."""
    context = load_context_payload()

    # 1. Augmentation: Build the mega-prompt
    system_instruction = f"""
    {chr(10).join(context['global_rules'])}

    DATAFORM ASSERTIONS (Strict Logic to Follow):
    {chr(10).join(context['dataform_assertions_reference'])}

    DATABASE SCHEMA (Only use these tables/columns):
    {json.dumps(context['tables'], indent=2)}

    Output ONLY valid BigQuery SQL. Do not include markdown formatting. Just the raw text.
    """

    prompt = f"System Rules:\n{system_instruction}\n\nUser Question:\n{user_question}"

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

    question = input("Dear APEXer please, ask a business question (or type 'exit' to quit):\n> ")

    if question.lower() != 'exit':
        print("\nAnalyzing governance rules and generating SQL...\n")
        sql_result = generate_sql(question)

        print("Generated Production SQL:")
        print("---------------------------------------------")
        print(sql_result)
        print("---------------------------------------------")
