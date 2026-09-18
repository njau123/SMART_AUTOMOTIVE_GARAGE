"""
Firebase Admin initialization.

Production: reads FIREBASE_CREDENTIALS_B64 (base64-encoded service account JSON)
Local dev:  falls back to serviceAccountKey.json file
"""
import os
import json
import base64
import firebase_admin
from firebase_admin import credentials, auth

# Default placeholder auth for development (no credentials)
class MockFirebaseAuth:
    def verify_id_token(self, token):
        return {
            'uid': 'mock_user',
            'email': 'test@example.com',
            'name': 'Test User',
        }

firebase_auth = None
_initialized = False


def _load_credentials():
    """Return firebase credentials.Certificate or None."""
    # 1. Try base64 env var (Render production)
    b64 = os.environ.get('FIREBASE_CREDENTIALS_B64', '').strip()
    if b64:
        try:
            decoded = base64.b64decode(b64).decode('utf-8')
            cred_dict = json.loads(decoded)
            return credentials.Certificate(cred_dict)
        except Exception as exc:
            print(f"[ERROR] Failed to load FIREBASE_CREDENTIALS_B64: {exc}")
            return None

    # 2. Try individual env vars (alternative)
    project_id = os.environ.get('FIREBASE_PROJECT_ID', '').strip()
    client_email = os.environ.get('FIREBASE_CLIENT_EMAIL', '').strip()
    private_key = os.environ.get('FIREBASE_PRIVATE_KEY', '').strip()
    if project_id and client_email and private_key:
        return credentials.Certificate({
            'type': 'service_account',
            'project_id': project_id,
            'private_key': private_key.replace('\\n', '\n'),
            'client_email': client_email,
        })

    # 3. Try local file (dev only)
    cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
    if os.path.exists(cred_path):
        print(f"[INFO] Loading Firebase credentials from file: {cred_path}")
        return credentials.Certificate(cred_path)

    return None


def init_firebase():
    """Initialize Firebase app once. Safe to call multiple times."""
    global firebase_auth, _initialized

    if _initialized:
        return firebase_auth

    cred = _load_credentials()
    if cred is None:
        print("[WARNING] Firebase credentials not found. Using mock auth (dev mode).")
        firebase_auth = MockFirebaseAuth()
        _initialized = True
        return firebase_auth

    try:
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        firebase_auth = auth
        print("[OK] Firebase initialized successfully")
    except Exception as exc:
        print(f"[ERROR] Firebase init failed: {exc}")
        firebase_auth = MockFirebaseAuth()

    _initialized = True
    return firebase_auth


# Initialize on module import
init_firebase()
