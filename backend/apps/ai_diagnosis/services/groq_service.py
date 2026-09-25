"""
Groq AI Service — Multi-language, Vision-capable
Models: openai/gpt-oss-120b (text), qwen/qwen3.8-27b (vision)
"""
import os
import base64
from groq import Groq


TEXT_MODEL = "openai/gpt-oss-120b"
VISION_MODEL = "qwen/qwen3.8-27b"

SYSTEM_PROMPT = """Wewe ni mtaalamu wa magari (automotive expert) mwenye uzoefu wa miaka 20.
Unajua magari yote — makubwa na madogo, petrol na diesel, ya kisasa na ya zamani.

KANUNI ZAKO:
1. Jibu kwa lugha ambayo user ameandika (Kiswahili au English).
2. Onyesha huruma kwa changamoto ya user (mfano: "Pole sana kwa changamoto hii...").
3. Toa uchambuzi wa kina:
   - Sababu zinazowezekana (causes)
   - Dalili zaidi za kuangalia
   - Hatua za kuchukua (actions)
   - Tahadhari za usalama
   - Specialist anayefaa
4. Kama user anatuma picha, ichambue kwa makini — tambua sehemu, hali yake, na kama kuna tatizo linaonekana.
5. Kama hujui kitu, sema ukweli na mwambie user aone mechanic.
6. Tumia lugha rahisi kueleweka, sio maneno magumu.
7. Onyesha kiwango cha hatari: LOW, MEDIUM, HIGH, CRITICAL.
8. Mwisho, mwambie user: "Kama hujaridhika na uchambuzi wetu, unaweza kuona mechanic wetu."

Jibu kwa muundo huu (JSON):
{
    "summary": "Muhtasari mfupi",
    "causes": ["sababu 1", "sababu 2", ...],
    "actions": ["hatua 1", "hatua 2", ...],
    "safety_warnings": ["tahadhari 1", ...],
    "severity": "LOW|MEDIUM|HIGH|CRITICAL",
    "mechanic_specialty": "Engine Specialist|Brake Specialist|...",
    "detailed_explanation": "Maelezo marefu kwa lugha rahisi..."
}
"""


def _get_client():
    api_key = os.environ.get('GROQ_API_KEY', '')
    if not api_key:
        raise Exception('GROQ_API_KEY haipo kwenye environment')
    return Groq(api_key=api_key)


def diagnose_with_ai(
    vehicle_make: str,
    vehicle_model: str,
    vehicle_year: str,
    symptoms: str,
    additional_info: str = '',
    image_bytes: bytes = None,
    image_name: str = '',
    user_language: str = 'auto',
) -> dict:
    """
    AI diagnosis — text + optional image.
    Returns dict: {summary, causes, actions, safety_warnings, severity, mechanic_specialty, detailed_explanation}
    """
    import json

    client = _get_client()

    # Unda user prompt
    user_text = f"""Gari: {vehicle_make} {vehicle_model} ({vehicle_year})
Dalili: {symptoms}
Maelezo ya ziada: {additional_info or 'Hakuna'}

Tafadhali nichambulie tatizo hili."""

    # Unda message content
    if image_bytes:
        # Encode image kwa base64
        img_b64 = base64.b64encode(image_bytes).decode()
        content = [
            {'type': 'text', 'text': user_text},
            {'type': 'image_url', 'image_url': {'url': f'data:image/jpeg;base64,{img_b64}'}},
        ]
        model = VISION_MODEL
    else:
        content = user_text
        model = TEXT_MODEL

    # Call Groq
    response = client.chat.completions.create(
        messages=[
            {'role': 'system', 'content': SYSTEM_PROMPT},
            {'role': 'user', 'content': content},
        ],
        model=model,
        temperature=0.7,
        max_tokens=2000,
        response_format={'type': 'json_object'} if not image_bytes else None,
    )

    raw = response.choices[0].message.content

    # Parse JSON
    try:
        # Tafuta JSON kwenye response
        start = raw.find('{')
        end = raw.rfind('}') + 1
        if start >= 0 and end > start:
            result = json.loads(raw[start:end])
        else:
            result = json.loads(raw)
    except Exception as e:
        # Fallback kama JSON parsing imefeli
        result = {
            'summary': raw[:300],
            'causes': ['Uchambuzi unahitaji mechanic'],
            'actions': ['Tafadhali wasiliana na mechanic'],
            'safety_warnings': [],
            'severity': 'MEDIUM',
            'mechanic_specialty': 'General Mechanic',
            'detailed_explanation': raw,
        }

    # Ensure fields zote zipo
    defaults = {
        'summary': '',
        'causes': [],
        'actions': [],
        'safety_warnings': [],
        'severity': 'MEDIUM',
        'mechanic_specialty': 'General Mechanic',
        'detailed_explanation': '',
    }
    for key, default in defaults.items():
        if key not in result:
            result[key] = default

    return result
