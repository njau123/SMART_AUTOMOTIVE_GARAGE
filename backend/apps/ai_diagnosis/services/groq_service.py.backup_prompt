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
    import logging

    logger = logging.getLogger(__name__)
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

    # Call Groq — BILA response_format (inaweza kusababisha 400 error)
    request_params = {
        'messages': [
            {'role': 'system', 'content': SYSTEM_PROMPT},
            {'role': 'user', 'content': content},
        ],
        'model': model,
        'temperature': 0.7,
        'max_tokens': 2000,
    }

    logger.info(f"[Groq] Calling model={model}, has_image={bool(image_bytes)}")

    try:
        response = client.chat.completions.create(**request_params)
    except Exception as e:
        logger.error(f"[Groq] API error: {type(e).__name__}: {e}")
        raise Exception(f"Groq API error: {str(e)}")

    raw = response.choices[0].message.content
    logger.info(f"[Groq] Response length: {len(raw)}")

    # Parse JSON — robust
    result = None

    # Jaribu 1: Parse moja kwa moja
    try:
        result = json.loads(raw)
    except Exception:
        pass

    # Jaribu 2: Tafuta JSON block
    if result is None:
        try:
            start = raw.find('{')
            end = raw.rfind('}') + 1
            if start >= 0 and end > start:
                result = json.loads(raw[start:end])
        except Exception:
            pass

    # Jaribu 3: Ondoa ```json ... ``` markdown
    if result is None:
        try:
            import re
            match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', raw, re.DOTALL)
            if match:
                result = json.loads(match.group(1))
        except Exception:
            pass

    # Fallback
    if result is None:
        logger.warning(f"[Groq] JSON parse failed, using fallback")
        result = {
            'summary': raw[:500],
            'causes': [],
            'actions': [],
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


# ==================== CONVERSATIONAL CHAT ====================
CHAT_SYSTEM_PROMPT = """Wewe ni "Mechanic AI" — msaidizi wa magari wa Smart Automotive Garage.
Unazungumza kwa upole, kwa heshima, na kwa lugha ambayo user ameandika (Kiswahili au English).

KANUNI ZAKO:
1. Onyesha huruma kwa changamoto ya user kwanza: "Pole sana...", "Nashukuru kwa maelezo..."
2. Uliza maswali ya ziada kama hujui vya kutosha (mfano: "Inatokea wakati gani?", "Kuna sauti gani?")
3. Kama una uhakika wa kutosha, toa uchambuzi wa kina:
   - Sababu zinazowezekana (numbered)
   - Kwa nini kila sababu inawezekana
   - Hatua za kuchukua
   - Tahadhari za usalama
   - Kiwango cha hatari (LOW/MEDIUM/HIGH/CRITICAL)
4. Kama hujui, sema ukweli: "Hii inahitaji mechanic kuangalia moja kwa moja"
5. Kama user anatuma picha, ichambue kwa makini
6. MWISHO wa diagnosis, ongeza mstari huu kama CTA:
   "Kama hujaridhika na uchambuzi wetu, unaweza kuona mechanic wetu."

Tumia markdown yenye nguvu:
- **Bold** kwa maneno muhimu
- Namba (1., 2., 3.) kwa orodha
- Viwango vya hatari kwa CAPS (HIGH, MEDIUM, n.k.)

USIRUDIE maelezo marefu kama hayahitajiki. Kuwa mfupi kwa maswali, mrefu kwa uchambuzi wa mwisho.
"""


def chat_with_ai(
    message: str,
    vehicle_make: str = '',
    vehicle_model: str = '',
    vehicle_year: str = '',
    history: list = None,
    image_bytes: bytes = None,
) -> dict:
    """
    Multi-turn chat na AI mechanic.
    Returns: {'reply': str, 'model_used': str}
    """
    import json
    import logging

    logger = logging.getLogger(__name__)
    client = _get_client()

    history = history or []

    # Unda context
    vehicle_context = ''
    if vehicle_make or vehicle_model or vehicle_year:
        vehicle_context = f"\n[Gari la user: {vehicle_make} {vehicle_model} ({vehicle_year})]"

    # Unda messages
    messages = [
        {'role': 'system', 'content': CHAT_SYSTEM_PROMPT + vehicle_context},
    ]

    # Ongeza history
    for h in history[-10:]:  # last 10 messages for context
        role = h.get('role', 'user')
        content = h.get('content', '')
        if role in ('user', 'assistant') and content:
            messages.append({'role': role, 'content': content})

    # Unda user message ya sasa
    if image_bytes:
        img_b64 = base64.b64encode(image_bytes).decode()
        messages.append({
            'role': 'user',
            'content': [
                {'type': 'text', 'text': message or 'Chambua picha hii ya gari langu.'},
                {'type': 'image_url', 'image_url': {'url': f'data:image/jpeg;base64,{img_b64}'}},
            ],
        })
        model = VISION_MODEL
    else:
        messages.append({'role': 'user', 'content': message})
        model = TEXT_MODEL

    logger.info(f"[Chat] model={model}, history_len={len(history)}, has_image={bool(image_bytes)}")

    try:
        response = client.chat.completions.create(
            messages=messages,
            model=model,
            temperature=0.7,
            max_tokens=1500,
        )
        reply = response.choices[0].message.content
    except Exception as e:
        logger.error(f"[Chat] API error: {type(e).__name__}: {e}")
        raise Exception(f"AI error: {str(e)}")

    return {
        'reply': reply,
        'model_used': model,
        'has_image': bool(image_bytes),
    }
