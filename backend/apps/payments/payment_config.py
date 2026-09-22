"""
Payment Configuration — Networks, Banks, Admin Accounts.

Hii ni config kuu ya maelekezo ya malipo.
Admin anaweza ku-update namba zake hapa.
"""

# ============ ADMIN ACCOUNTS (Namba zako) ============
ADMIN_ACCOUNTS = {
    "MOBILE_MONEY": {
        "Vodacom": {
            "number": "0759212300",
            "name": "Automotive Smart Garage",
            "ussd": "*150*00#",
        },
        "Tigo/Yas": {
            "number": "0759212300",
            "name": "Automotive Smart Garage",
            "ussd": "*150*01#",
        },
        "Airtel": {
            "number": "0759212300",
            "name": "Automotive Smart Garage",
            "ussd": "*150*60#",
        },
        "Halotel": {
            "number": "0759212300",
            "name": "Automotive Smart Garage",
            "ussd": "*150*88#",
        },
    },
    "BANK": {
        "NMB": {
            "account": "23210042232",
            "name": "Automotive Smart Garage",
        },
        "CRDB": {
            "account": "23210042232",
            "name": "Automotive Smart Garage",
        },
        "Azania": {
            "account": "23210042232",
            "name": "Automotive Smart Garage",
        },
        "NBC": {
            "account": "23210042232",
            "name": "Automotive Smart Garage",
        },
    },
}

# ============ NETWORK PREFIXES ============
NETWORK_PREFIXES = {
    "Vodacom": ["075", "076", "071"],
    "Tigo/Yas": ["065", "067", "077"],
    "Airtel": ["068", "069", "078"],
    "Halotel": ["061", "062"],
    "TTCL": ["073"],
}

# ============ BANK PATTERNS ============
# Kila bank ina patterns tofauti:
#   - card: BIN za kadi (4-6 digits)
#   - account_prefix: namba za account zinazoanza na
#   - account_length: urefu wa account
BANK_PATTERNS = {
    "NMB": {
        "card": ["5061", "5035"],
        "account_prefix": ["23", "22", "21"],
        "account_length": [10, 11, 12, 13],
    },
    "CRDB": {
        "card": ["5062"],
        "account_prefix": ["015"],
        "account_length": [10, 11, 12, 13],
    },
    "Azania": {
        "card": ["5063"],
        "account_prefix": ["40", "41"],
        "account_length": [10, 11, 12, 13],
    },
    "NBC": {
        "card": ["5064"],
        "account_prefix": ["011", "012"],
        "account_length": [10, 11, 12, 13],
    },
}

# Bank zote zinazopatikana (kwa dropdown)
AVAILABLE_BANKS = ["NMB", "CRDB", "Azania", "NBC"]

# Mitandao yote inayopatikana (kwa dropdown)
AVAILABLE_NETWORKS = [
    "Vodacom",
    "Tigo/Yas",
    "Airtel",
    "Halotel",
    "TTCL",
]

# ============ TIMER ============
PAYMENT_TIMEOUT_MINUTES = 45
