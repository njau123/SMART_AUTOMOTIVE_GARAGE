"""
Payment Detection — Networks, Banks, Instructions.

Helper functions:
- detect_network(phone) → "Vodacom" | "Tigo/Yas" | "Airtel" | "Halotel" | "TTCL" | "Unknown"
- detect_bank(card_or_account) → "CRDB" | "NMB" | ... | "Unknown"
- get_payment_instructions(network_or_bank, amount, reference, method_type) → str
"""
import re
from .payment_config import (
    ADMIN_ACCOUNTS,
    NETWORK_PREFIXES,
    BANK_PATTERNS,
    AVAILABLE_BANKS,
    AVAILABLE_NETWORKS,
)


# ============ PHONE CLEANING ============
def clean_phone(phone: str) -> str:
    """Ondoa spaces, dashes, +. Rudisha digits pekee."""
    if not phone:
        return ""
    return re.sub(r"[^0-9]", "", str(phone))


def normalize_phone(phone: str) -> str:
    """
    Rudisha phone kwa format ya 0XXXXXXXXX (local).
    Inakubali: 075..., 25575..., +25575...
    """
    clean = clean_phone(phone)
    if not clean:
        return ""
    if clean.startswith("255"):
        clean = "0" + clean[3:]
    elif not clean.startswith("0"):
        clean = "0" + clean
    return clean


# ============ NETWORK DETECTION ============
def detect_network(phone: str) -> str:
    """
    Tambua mtandao kutoka namba ya simu.

    Inarudisha: 'Vodacom', 'Tigo/Yas', 'Airtel', 'Halotel', 'TTCL', au 'Unknown'
    """
    normalized = normalize_phone(phone)
    if len(normalized) < 3:
        return "Unknown"

    prefix = normalized[:3]

    for network, prefixes in NETWORK_PREFIXES.items():
        if prefix in prefixes:
            return network

    return "Unknown"


# ============ BANK DETECTION ============
def detect_bank(card_or_account: str) -> str:
    """
    Tambua bank kutoka namba ya kadi au account.

    Inarudisha: 'CRDB', 'NMB', 'Azania', 'NBC', au 'Unknown'

    Kumbuka: Bank detection kwa account number SI reliable 100%.
    User anapaswa ku-chagua bank mwenyewe kwa usahihi.
    Hii ni "smart guess" tu.
    """
    clean = clean_phone(card_or_account)
    if not clean:
        return "Unknown"

    length = len(clean)

    for bank, patterns in BANK_PATTERNS.items():
        # 1. Angalia card BIN
        for bin_prefix in patterns.get("card", []):
            if clean.startswith(bin_prefix):
                return bank

        # 2. Angalia account prefix + length
        account_lengths = patterns.get("account_length", [])
        if length in account_lengths:
            for acc_prefix in patterns.get("account_prefix", []):
                if clean.startswith(acc_prefix):
                    return bank

    return "Unknown"


# ============ INSTRUCTIONS ============
def get_mobile_money_instructions(network: str, amount, reference: str) -> str:
    """Rudisha maelekezo ya kulipia kwa mtandao husika."""
    account_info = ADMIN_ACCOUNTS.get("MOBILE_MONEY", {}).get(network)

    if not account_info:
        # Mtandao haujulikani
        return (
            f"Mtandao wako haujatambuliwa.\n\n"
            f"Tafadhali tumia namba ya simu inayoanza na:\n"
            f"  • Vodacom: 075, 076, 071\n"
            f"  • Tigo/Yas: 065, 067, 077\n"
            f"  • Airtel: 068, 069, 078\n"
            f"  • Halotel: 061, 062\n"
            f"  • TTCL: 073\n\n"
            f"Kumbukumbu: {reference}"
        )

    ussd = account_info.get("ussd", "")
    number = account_info.get("number", "")
    name = account_info.get("name", "")

    return (
        f"💰 MALIPO KWA {network.upper()}\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"1. Fungua app ya simu (Phone)\n"
        f"2. Piga USSD: {ussd}\n"
        f"3. Chagua 'Lipa kwa M-Pesa' au 'Malipo'\n"
        f"4. Weka namba: {number}\n"
        f"5. Weka kiasi: TSh {amount:,.0f}\n"
        f"6. Weka kumbukumbu: {reference}\n"
        f"7. Weka PIN yako\n"
        f"8. Utapata SMS ya uthibitisho\n\n"
        f"👤 Jina la Mpokeaji: {name}\n"
        f"📞 Namba ya Kulipia: {number}\n"
        f"💵 Kiasi: TSh {amount:,.0f}\n"
        f"📝 Kumbukumbu: {reference}\n\n"
        f"Baada ya kulipa, rudi hapa na ubonyeze 'Nimelipa'."
    )


def get_bank_instructions(bank: str, amount, reference: str) -> str:
    """Rudisha maelekezo ya kulipia kwa bank husika."""
    account_info = ADMIN_ACCOUNTS.get("BANK", {}).get(bank)

    if not account_info:
        return (
            f"Benki yako haijatambuliwa.\n\n"
            f"Tafadhali tumia benki zifuatazo:\n"
            f"  • CRDB, NMB, Azania, NBC\n\n"
            f"Kumbukumbu: {reference}"
        )

    account = account_info.get("account", "")
    name = account_info.get("name", "")

    return (
        f"💰 MALIPO KWA {bank.upper()}\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"1. Fungua app ya benki yako ({bank})\n"
        f"2. Chagua 'Tuma Pesa' au 'Transfer'\n"
        f"3. Weka account: {account}\n"
        f"4. Weka kiasi: TSh {amount:,.0f}\n"
        f"5. Weka kumbukumbu: {reference}\n"
        f"6. Thibitisha malipo\n\n"
        f"👤 Jina la Mpokeaji: {name}\n"
        f"🏦 Benki: {bank}\n"
        f"🔢 Account: {account}\n"
        f"💵 Kiasi: TSh {amount:,.0f}\n"
        f"📝 Kumbukumbu: {reference}\n\n"
        f"Baada ya kulipia, rudi hapa na ubonyeze 'Nimelipa'."
    )


def get_instructions(method_type: str, identifier: str, amount, reference: str) -> dict:
    """
    Rudisha dict yenye maelekezo kamili.

    Args:
        method_type: 'MOBILE_MONEY' au 'BANK'
        identifier: phone number (mobile) au account (bank)
        amount: kiasi (Decimal au float)
        reference: kumbukumbu (payment reference)

    Returns:
        {
            'network_or_bank': str,
            'method_type': str,
            'instructions': str,
            'is_detected': bool,
        }
    """
    if method_type == "MOBILE_MONEY":
        detected = detect_network(identifier)
        instructions = get_mobile_money_instructions(detected, amount, reference)
        return {
            "network_or_bank": detected,
            "method_type": "MOBILE_MONEY",
            "instructions": instructions,
            "is_detected": detected != "Unknown",
        }
    elif method_type == "BANK":
        detected = detect_bank(identifier)
        instructions = get_bank_instructions(detected, amount, reference)
        return {
            "network_or_bank": detected,
            "method_type": "BANK",
            "instructions": instructions,
            "is_detected": detected != "Unknown",
        }
    else:
        return {
            "network_or_bank": "Unknown",
            "method_type": method_type,
            "instructions": "Njia ya malipo haijulikani.",
            "is_detected": False,
        }
