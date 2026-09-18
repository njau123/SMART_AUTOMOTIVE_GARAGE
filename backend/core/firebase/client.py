import firebase_admin

from django.conf import settings
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import storage


_firebase_app = None


def get_firebase_app():
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    if not settings.FIREBASE_PROJECT_ID:
        raise RuntimeError(
            "FIREBASE_PROJECT_ID is not configured."
        )

    if not settings.FIREBASE_CLIENT_EMAIL:
        raise RuntimeError(
            "FIREBASE_CLIENT_EMAIL is not configured."
        )

    if not settings.FIREBASE_PRIVATE_KEY:
        raise RuntimeError(
            "FIREBASE_PRIVATE_KEY is not configured."
        )

    private_key = (
        settings.FIREBASE_PRIVATE_KEY
        .replace("\\n", "\n")
    )

    credential = credentials.Certificate(
        {
            "type": "service_account",
            "project_id": (
                settings.FIREBASE_PROJECT_ID
            ),
            "private_key": private_key,
            "client_email": (
                settings.FIREBASE_CLIENT_EMAIL
            ),
        }
    )

    options = {}

    if settings.FIREBASE_STORAGE_BUCKET:
        options["storageBucket"] = (
            settings.FIREBASE_STORAGE_BUCKET
        )

    _firebase_app = firebase_admin.initialize_app(
        credential,
        options=options,
    )

    return _firebase_app


def get_firestore_client():
    app = get_firebase_app()

    return firestore.client(
        app=app
    )


def get_storage_bucket():
    app = get_firebase_app()

    return storage.bucket(
        app=app
    )