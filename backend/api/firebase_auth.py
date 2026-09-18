import firebase_admin
from firebase_admin import credentials, auth
from django.conf import settings
import json

# Initialize Firebase (tumia service account key)
# Weka serviceAccountKey.json kwenye root ya project
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Firebase not initialized: {e}")

def verify_firebase_token(id_token):
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        return None
