import os
import firebase_admin
from firebase_admin import credentials, auth

# Path to service account key
cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')

if os.path.exists(cred_path):
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    print("[OK] Firebase initialized successfully")
else:
    print(f"[WARNING] Firebase credentials not found at {cred_path}")
    # Mock for development
    class MockFirebaseAuth:
        def verify_id_token(self, token):
            return {'uid': 'mock_user', 'email': 'test@example.com', 'name': 'Test User'}
    firebase_auth = MockFirebaseAuth()
