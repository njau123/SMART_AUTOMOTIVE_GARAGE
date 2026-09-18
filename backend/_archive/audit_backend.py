import os
import sys
import json
import subprocess
import socket
import importlib
from pathlib import Path

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "automotive_backend.settings")
sys.path.insert(0, os.getcwd())

import django
django.setup()

from django.conf import settings
from django.apps import apps
from django.db import connection
from django.urls import get_resolver
from django.contrib.auth import get_user_model

try:
    from rest_framework.test import APIClient
    DRF_AVAILABLE = True
except Exception:
    DRF_AVAILABLE = False


# ============================================================
# GLOBAL STATE
# ============================================================

PASS = 0
FAIL = 0
WARN = 0
NOT_VERIFIED = 0


def header(title):
    print("\n" + "=" * 78)
    print(f"  {title}")
    print("=" * 78)


def ok(message):
    global PASS
    PASS += 1
    print(f"[PASS] {message}")


def fail(message):
    global FAIL
    FAIL += 1
    print(f"[FAIL] {message}")


def warn(message):
    global WARN
    WARN += 1
    print(f"[WARN] {message}")


def nv(message):
    global NOT_VERIFIED
    NOT_VERIFIED += 1
    print(f"[NOT VERIFIED] {message}")


def info(message):
    print(f"[INFO] {message}")


def command_exists(command):
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as exc:
        return False, "", str(exc)


def file_exists(path):
    return Path(path).is_file()


def compile_python_file(path):
    try:
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", str(path)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode == 0, result.stderr.strip()
    except Exception as exc:
        return False, str(exc)


# ============================================================
# START
# ============================================================

print("\n" + "=" * 78)
print("  SMART AUTOMOTIVE GARAGE - COMPLETE BACKEND AUDIT")
print("=" * 78)
print(f"Project: {Path.cwd()}")
print(f"Python : {sys.version.split()[0]}")
print(f"Django : {getattr(django, 'get_version', lambda: 'unknown')()}")
print("=" * 78)


# ============================================================
# 1. DJANGO CORE
# ============================================================

header("1. DJANGO CORE")

success, stdout, stderr = command_exists(
    [sys.executable, "manage.py", "check"]
)

if success:
    ok("Django system check passed.")
else:
    fail("Django system check failed.")
    if stderr:
        print(stderr)


# ============================================================
# 2. DATABASE
# ============================================================

header("2. DATABASE")

try:
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1")
        cursor.fetchone()

    ok("Database connection is working.")
except Exception as exc:
    fail(f"Database connection failed: {exc}")

engine = settings.DATABASES["default"]["ENGINE"]
name = settings.DATABASES["default"].get("NAME")

info(f"Database engine: {engine}")
info(f"Database name/path: {name}")

if "sqlite3" in engine.lower():
    warn("Current runtime database is SQLite. PostgreSQL migration is still pending.")
elif "postgresql" in engine.lower():
    ok("Current runtime database is PostgreSQL.")
else:
    warn(f"Unexpected database engine: {engine}")


# ============================================================
# 3. MIGRATIONS
# ============================================================

header("3. MIGRATIONS")

success, stdout, stderr = command_exists(
    [sys.executable, "manage.py", "showmigrations"]
)

if success:
    migration_lines = stdout.splitlines()

    total_migrations = 0
    unapplied_migrations = 0

    for line in migration_lines:
        stripped = line.strip()

        if stripped.startswith("[X]"):
            total_migrations += 1

        elif stripped.startswith("[ ]"):
            unapplied_migrations += 1

    info(f"Applied migrations: {total_migrations}")
    info(f"Unapplied migrations: {unapplied_migrations}")

    if unapplied_migrations == 0:
        ok("All detected migrations are applied.")
    else:
        fail(f"{unapplied_migrations} migration(s) are not applied.")
else:
    fail("Could not run showmigrations.")


# ============================================================
# 4. EXPECTED APPS
# ============================================================

header("4. DJANGO APPS")

expected_apps = [
    "accounts",
    "vehicles",
    "mechanics",
    "services",
    "spare_parts",
    "bookings",
    "diagnosis",
    "bluetooth",
    "wallet",
    "payments",
    "notifications",
    "news",
    "advertisements",
    "tracking",
    "reviews",
    "chat",
    "dashboard",
    "analytics",
    "media",
    "reports",
    "audit_logs",
    "system",
]

installed_labels = {
    config.label
    for config in apps.get_app_configs()
}

for app in expected_apps:
    if app in installed_labels:
        ok(f"App installed: {app}")
    else:
        warn(f"Expected app not found: {app}")


# ============================================================
# 5. PYTHON SYNTAX / IMPORT AUDIT
# ============================================================

header("5. PYTHON SOURCE AUDIT")

python_files = list(Path("apps").rglob("*.py"))

if python_files:
    syntax_errors = 0

    for path in python_files:
        if "__pycache__" in path.parts:
            continue

        success, error = compile_python_file(path)

        if not success:
            syntax_errors += 1
            fail(f"Python syntax error: {path}")
            if error:
                print(error)

    if syntax_errors == 0:
        ok(f"All {len(python_files)} application Python files compile successfully.")
else:
    warn("No Python files found below apps/.")


# ============================================================
# 6. FIREBASE
# ============================================================

header("6. FIREBASE ADMIN SDK")

firebase_path = Path("automotive_backend/serviceAccountKey.json")

if firebase_path.exists():
    size = firebase_path.stat().st_size
    info(f"Firebase credentials size: {size} bytes")

    if size > 0:
        ok("Firebase service-account file exists and is not empty.")

        try:
            with firebase_path.open("r", encoding="utf-8") as f:
                firebase_json = json.load(f)

            project_id = firebase_json.get("project_id")
            client_email = firebase_json.get("client_email")
            private_key = firebase_json.get("private_key")

            if project_id:
                info(f"Firebase project_id: {project_id}")
                ok("Firebase project_id exists.")
            else:
                fail("Firebase project_id is missing.")

            if client_email:
                ok("Firebase client_email exists.")
            else:
                fail("Firebase client_email is missing.")

            if private_key:
                ok("Firebase private_key exists.")
            else:
                fail("Firebase private_key is missing.")

        except Exception as exc:
            fail(f"Firebase credential JSON could not be parsed: {exc}")
    else:
        fail("Firebase credential file exists but is EMPTY.")
else:
    fail(f"Firebase credentials missing: {firebase_path}")

try:
    import firebase_admin
    from firebase_admin import messaging

    ok("firebase-admin package is installed.")
    ok("Firebase messaging module is available.")

    if firebase_admin._apps:
        ok("Firebase Admin SDK is initialized.")
    else:
        warn("Firebase Admin SDK package loaded but no initialized app was found.")
except Exception as exc:
    fail(f"Firebase Admin SDK initialization/import failed: {exc}")


# ============================================================
# 7. FIREBASE CONFIG FILE
# ============================================================

header("7. FIREBASE CONFIG")

firebase_config = Path("automotive_backend/firebase_config.py")

if firebase_config.exists():
    ok("automotive_backend/firebase_config.py exists.")

    content = firebase_config.read_text(
        encoding="utf-8",
        errors="ignore",
    )

    if "automotive_baackend" in content:
        fail("Typo 'automotive_baackend' still exists in firebase_config.py.")
    else:
        ok("No known Firebase path typo found.")

    if "serviceAccountKey.json" in content:
        ok("Firebase config references serviceAccountKey.json.")
    else:
        warn("Firebase config does not visibly reference serviceAccountKey.json.")
else:
    fail("firebase_config.py does not exist.")


# ============================================================
# 8. MODEL INVENTORY
# ============================================================

header("8. MODEL INVENTORY")

for app_label in expected_apps:
    try:
        config = apps.get_app_config(app_label)
    except LookupError:
        continue

    models = list(config.get_models())

    if not models:
        warn(f"{app_label}: no Django models detected.")
        continue

    info(
        f"{app_label}: "
        + ", ".join(model.__name__ for model in models)
    )


# ============================================================
# 9. DATABASE TABLE INVENTORY
# ============================================================

header("9. DATABASE TABLES")

try:
    tables = set(connection.introspection.table_names())

    info(f"Total database tables: {len(tables)}")

    important_tables = [
        "diagnosis_diagnosissession",
        "diagnosis_dtccode",
        "diagnosis_diagnosisdtc",
        "diagnosis_obdreading",
        "diagnosis_obdscanevent",
    ]

    for table in important_tables:
        if table in tables:
            ok(f"Table exists: {table}")
        else:
            fail(f"Missing required table: {table}")

except Exception as exc:
    fail(f"Could not inspect database tables: {exc}")


# ============================================================
# 10. DATA COUNTS
# ============================================================

header("10. CORE DATA COUNTS")

User = get_user_model()

def model_count(app_label, model_name):
    try:
        model = apps.get_model(app_label, model_name)
        return model.objects.count()
    except Exception:
        return None


count_targets = [
    ("Users", "accounts", User.__name__),

    ("Vehicles", "vehicles", "Vehicle"),
    ("Mechanics", "mechanics", "MechanicProfile"),

    ("DTC catalogue", "diagnosis", "DTCCode"),
    ("Diagnosis sessions", "diagnosis", "DiagnosisSession"),
    ("Diagnosis DTC links", "diagnosis", "DiagnosisDTC"),
    ("OBD readings", "diagnosis", "OBDReading"),
    ("OBD scan events", "diagnosis", "OBDScanEvent"),

    ("Payments", "payments", "Payment"),

    ("Notifications", "notifications", "Notification"),
    ("Notification devices", "notifications", "NotificationDevice"),

    ("Spare parts", "spare_parts", "SparePart"),
    ("Bookings", "bookings", "Booking"),
]

for label, app_label, model_name in count_targets:
    count = model_count(app_label, model_name)

    if count is None:
        warn(f"{label}: model not found using expected name {app_label}.{model_name}")
    else:
        print(f"{label}: {count}")


# ============================================================
# 11. DIAGNOSIS
# ============================================================

header("11. OBD / DIAGNOSIS")

required_diagnosis_files = [
    "apps/diagnosis/models.py",
    "apps/diagnosis/serializers.py",
    "apps/diagnosis/views.py",
    "apps/diagnosis/urls.py",
    "apps/diagnosis/services/dtc_decoder.py",
    "apps/diagnosis/services/pid_decoder.py",
    "apps/diagnosis/services/obd_protocol.py",
    "apps/diagnosis/services/obd_service.py",
]

for path in required_diagnosis_files:
    if file_exists(path):
        ok(f"Diagnosis file exists: {path}")
    else:
        fail(f"Missing diagnosis file: {path}")

dtc_count = model_count("diagnosis", "DTCCode")

if dtc_count is not None:
    if dtc_count >= 10:
        ok(f"DTC catalogue is populated: {dtc_count} codes.")
    elif dtc_count > 0:
        warn(f"DTC catalogue is small: only {dtc_count} codes.")
    else:
        fail("DTC catalogue is empty.")


# ============================================================
# 12. DIAGNOSIS MODEL FIELD CONSISTENCY
# ============================================================

header("12. DIAGNOSIS FIELD CONSISTENCY")

def has_field(model, field_name):
    try:
        model._meta.get_field(field_name)
        return True
    except Exception:
        return False


try:
    DTCCode = apps.get_model("diagnosis", "DTCCode")
    DiagnosisDTC = apps.get_model("diagnosis", "DiagnosisDTC")
    OBDScanEvent = apps.get_model("diagnosis", "OBDScanEvent")

    expected_dtc_fields = [
        "code",
        "system",
        "title",
        "symptoms",
        "possible_causes",
        "severity",
        "is_active",
    ]

    for field in expected_dtc_fields:
        if has_field(DTCCode, field):
            ok(f"DTCCode field exists: {field}")
        else:
            fail(f"DTCCode field missing: {field}")

    if has_field(DiagnosisDTC, "dtc_code"):
        ok("DiagnosisDTC uses correct field: dtc_code")
    else:
        fail("DiagnosisDTC does not have expected field dtc_code.")

    if has_field(DiagnosisDTC, "dtc"):
        warn("Old field 'dtc' still exists on DiagnosisDTC.")

    if has_field(DiagnosisDTC, "created_at"):
        warn("DiagnosisDTC still contains old field 'created_at'.")

    if has_field(OBDScanEvent, "created_at"):
        ok("OBDScanEvent uses created_at.")
    else:
        fail("OBDScanEvent does not have expected created_at field.")

    if has_field(OBDScanEvent, "detected_at"):
        warn("Old field 'detected_at' still exists on OBDScanEvent.")

except Exception as exc:
    fail(f"Could not audit diagnosis model fields: {exc}")


# ============================================================
# 13. NOTIFICATIONS
# ============================================================

header("13. NOTIFICATIONS / FCM")

notification_files = [
    "apps/notifications/models.py",
    "apps/notifications/serializers.py",
    "apps/notifications/views.py",
    "apps/notifications/services.py",
    "apps/notifications/urls.py",
]

for path in notification_files:
    if file_exists(path):
        ok(f"Notification file exists: {path}")
    else:
        fail(f"Missing notification file: {path}")

try:
    Notification = apps.get_model("notifications", "Notification")
    NotificationDevice = apps.get_model("notifications", "NotificationDevice")

    notification_fields = {
        f.name
        for f in Notification._meta.fields
    }

    notification_device_fields = {
        f.name
        for f in NotificationDevice._meta.fields
    }

    for required in [
        "recipient",
        "notification_type",
        "title",
        "message",
        "action_data",
        "is_read",
        "is_sent",
        "created_at",
    ]:
        if required in notification_fields:
            ok(f"Notification field exists: {required}")
        else:
            fail(f"Notification field missing: {required}")

    for required in [
        "user",
        "device_token",
        "device_type",
        "is_active",
    ]:
        if required in notification_device_fields:
            ok(f"NotificationDevice field exists: {required}")
        else:
            fail(f"NotificationDevice field missing: {required}")

    service_text = Path(
        "apps/notifications/services.py"
    ).read_text(
        encoding="utf-8",
        errors="ignore",
    )

    if "from firebase_admin import messaging" in service_text:
        ok("FCM messaging is imported.")
    else:
        fail("FCM messaging import is missing.")

    if "messaging.send(" in service_text:
        ok("FCM messaging.send() implementation exists.")
    else:
        fail("FCM messaging.send() implementation missing.")

    if "Notification.objects.create" in service_text:
        ok("Notification database persistence exists.")
    else:
        fail("Notification database persistence missing.")

    if "dummy_fcm_token" in service_text:
        warn("Dummy FCM token is hard-coded inside notification service.")
    else:
        ok("No dummy token found inside notification service.")

    dummy_devices = NotificationDevice.objects.filter(
        device_token__icontains="dummy"
    ).count()

    if dummy_devices:
        warn(
            f"{dummy_devices} dummy notification device token(s) exist in database. "
            "Real Flutter FCM token is still required."
        )
        nv("Real FCM push to a physical device has not been verified.")
    else:
        nv("No dummy token found; real device FCM delivery still needs verification.")

except Exception as exc:
    fail(f"Notification audit failed: {exc}")


# ============================================================
# 14. AUTHENTICATION
# ============================================================

header("14. AUTHENTICATION / USERS")

try:
    user_count = User.objects.count()

    if user_count > 0:
        ok(f"User database contains {user_count} user(s).")
    else:
        warn("No users exist in database.")

    user_fields = {
        f.name
        for f in User._meta.fields
    }

    for required in [
        "email",
        "password",
    ]:
        if required in user_fields:
            ok(f"User model field exists: {required}")
        else:
            fail(f"User model field missing: {required}")

except Exception as exc:
    fail(f"User model audit failed: {exc}")


# ============================================================
# 15. URL AUDIT
# ============================================================

header("15. API ROUTES")

def collect_url_patterns(patterns, prefix=""):
    routes = []

    for pattern in patterns:
        current = prefix + str(pattern.pattern)

        if hasattr(pattern, "url_patterns"):
            routes.extend(
                collect_url_patterns(
                    pattern.url_patterns,
                    current,
                )
            )
        else:
            routes.append(current)

    return routes


try:
    routes = collect_url_patterns(
        get_resolver().url_patterns
    )

    info(f"Detected URL patterns: {len(routes)}")

    route_requirements = {
        "auth login": "auth/login",
        "vehicles": "vehicles",
        "diagnosis payment": "diagnosis/obd-payment/initiate",
        "diagnosis scans": "diagnosis/scans",
        "notifications device registration": "notifications/devices/register",
        "payment verification": "payments/gateway/verify",
    }

    for label, fragment in route_requirements.items():
        matches = [
            route for route in routes
            if fragment.lower() in route.lower()
        ]

        if matches:
            ok(f"Route found for {label}: {matches[:3]}")
        else:
            warn(f"Could not automatically find expected route: {label}")

except Exception as exc:
    fail(f"URL audit failed: {exc}")


# ============================================================
# 16. API LIVE CHECK - SAFE READ/LOGIN ONLY
# ============================================================

header("16. LIVE API CHECK")

if DRF_AVAILABLE:
    client = APIClient()

    try:
        response = client.post(
            "/api/v1/auth/login/",
            {
                "email": "njaufredrick@gmail.com",
                "password": "A929292a",
            },
            format="json",
        )

        info(f"Login HTTP status: {response.status_code}")

        if response.status_code == 200:
            ok("JWT login endpoint returned HTTP 200.")

            body = response.json()

            if body.get("access"):
                ok("JWT access token was generated.")

                client.credentials(
                    HTTP_AUTHORIZATION=f"Bearer {body['access']}"
                )

                vehicle_response = client.get(
                    "/api/v1/vehicles/"
                )

                info(
                    f"Vehicle endpoint HTTP status: "
                    f"{vehicle_response.status_code}"
                )

                if vehicle_response.status_code in [200, 204]:
                    ok("Authenticated vehicle endpoint responds successfully.")
                elif vehicle_response.status_code == 404:
                    warn("Vehicle endpoint returned 404. Route may use a different path.")
                else:
                    warn(
                        f"Vehicle endpoint returned "
                        f"{vehicle_response.status_code}."
                    )

            else:
                fail("Login returned 200 but no access token was found.")

        elif response.status_code in [401, 403]:
            fail("Configured admin credentials were rejected by login.")
        else:
            warn(
                f"Login endpoint returned HTTP {response.status_code}; "
                "manual authentication review required."
            )

    except Exception as exc:
        warn(f"Safe API check could not complete: {exc}")
else:
    warn("Django REST Framework test client unavailable.")


# ============================================================
# 17. PAYMENT AUDIT
# ============================================================

header("17. PAYMENTS")

payment_files = [
    "apps/payments/models.py",
    "apps/payments/serializers.py",
    "apps/payments/views.py",
    "apps/payments/services.py",
    "apps/payments/urls.py",
]

for path in payment_files:
    if file_exists(path):
        ok(f"Payment file exists: {path}")
    else:
        fail(f"Missing payment file: {path}")

try:
    Payment = apps.get_model("payments", "Payment")

    payment_fields = {
        f.name
        for f in Payment._meta.fields
    }

    for required in [
        "amount",
        "currency",
        "status",
    ]:
        if required in payment_fields:
            ok(f"Payment field exists: {required}")
        else:
            warn(f"Payment model field not found: {required}")

    payment_count = Payment.objects.count()

    if payment_count > 0:
        ok(f"Payment records exist: {payment_count}")
    else:
        warn("No payment records exist.")

    payment_service_text = Path(
        "apps/payments/services.py"
    ).read_text(
        encoding="utf-8",
        errors="ignore",
    )

    lower_payment_text = payment_service_text.lower()

    if "sandbox" in lower_payment_text or "mock" in lower_payment_text:
        warn(
            "Payment implementation contains sandbox/mock terminology. "
            "Real commercial gateway is not production verified."
        )
        nv("Real Selcom/mobile-money merchant payment not verified.")
    else:
        nv(
            "Real production payment gateway credentials and live transaction "
            "have not been verified by this audit."
        )

except Exception as exc:
    fail(f"Payment audit failed: {exc}")


# ============================================================
# 18. WALLET AUDIT
# ============================================================

header("18. WALLET")

wallet_files = [
    "apps/wallet/models.py",
    "apps/wallet/serializers.py",
    "apps/wallet/views.py",
    "apps/wallet/urls.py",
]

for path in wallet_files:
    if file_exists(path):
        ok(f"Wallet file exists: {path}")
    else:
        warn(f"Wallet file missing: {path}")

try:
    wallet_config = apps.get_app_config("wallet")
    wallet_models = list(wallet_config.get_models())

    if wallet_models:
        ok(
            "Wallet models found: "
            + ", ".join(model.__name__ for model in wallet_models)
        )
    else:
        warn("No wallet models detected.")
except Exception:
    warn("Wallet app could not be inspected.")


# ============================================================
# 19. MECHANICS / BOOKINGS / LOCATION
# ============================================================

header("19. MECHANICS / BOOKINGS / TRACKING")

for app_label in [
    "mechanics",
    "bookings",
    "tracking",
]:
    try:
        config = apps.get_app_config(app_label)
        models = list(config.get_models())

        if models:
            ok(
                f"{app_label} models detected: "
                + ", ".join(model.__name__ for model in models)
            )
        else:
            warn(f"{app_label}: no models detected.")
    except LookupError:
        fail(f"{app_label}: app not installed.")

mechanic_count = model_count(
    "mechanics",
    "MechanicProfile",
)

if mechanic_count == 0:
    warn(
        "MechanicProfile count is 0. "
        "Mechanic search/booking cannot be fully tested yet."
    )
elif mechanic_count is not None:
    ok(f"Mechanic profiles exist: {mechanic_count}")


# ============================================================
# 20. SPARE PARTS / NEWS / ADVERTISEMENTS
# ============================================================

header("20. CONTENT MANAGEMENT")

content_targets = [
    ("SparePart", "spare_parts", "SparePart"),
    ("News", "news", "News"),
    ("Advertisement", "advertisements", "Advertisement"),
]

for label, app_label, model_name in content_targets:
    count = model_count(app_label, model_name)

    if count is None:
        warn(
            f"{label}: expected model {app_label}.{model_name} "
            "was not found."
        )
    else:
        ok(f"{label} model exists. Records: {count}")


# ============================================================
# 21. BLUETOOTH / REAL OBD HARDWARE
# ============================================================

header("21. BLUETOOTH / REAL OBD HARDWARE")

bluetooth_files = [
    "apps/bluetooth",
    "apps/diagnosis/services/obd_protocol.py",
    "apps/diagnosis/services/obd_service.py",
]

for path in bluetooth_files:
    if Path(path).exists():
        ok(f"Bluetooth/OBD component exists: {path}")
    else:
        fail(f"Missing Bluetooth/OBD component: {path}")

nv(
    "Real ELM327/OBD-II Bluetooth communication with an actual vehicle "
    "cannot be verified from Django backend audit alone."
)

nv(
    "Live ECU DTC/PID acquisition through the Pixel 4a 5G has not been "
    "verified by this backend-only audit."
)


# ============================================================
# 22. SECURITY / PRODUCTION SETTINGS
# ============================================================

header("22. SECURITY / PRODUCTION SETTINGS")

if getattr(settings, "DEBUG", False):
    warn("DEBUG=True. This is appropriate for local development, not production.")
else:
    ok("DEBUG=False.")

secret_key = getattr(settings, "SECRET_KEY", "")

if not secret_key:
    fail("SECRET_KEY is empty.")
elif "django-insecure" in secret_key:
    warn("SECRET_KEY appears to use Django development insecure value.")
else:
    ok("SECRET_KEY is configured.")


allowed_hosts = getattr(settings, "ALLOWED_HOSTS", [])

if allowed_hosts:
    ok(f"ALLOWED_HOSTS configured: {allowed_hosts}")
else:
    warn("ALLOWED_HOSTS is empty.")


# ============================================================
# 23. SESSION / JWT
# ============================================================

header("23. SESSION / JWT SECURITY")

simple_jwt = getattr(settings, "SIMPLE_JWT", None)

if simple_jwt:
    ok("SIMPLE_JWT configuration exists.")

    access_lifetime = simple_jwt.get("ACCESS_TOKEN_LIFETIME")

    if access_lifetime:
        info(f"ACCESS_TOKEN_LIFETIME: {access_lifetime}")
    else:
        warn("ACCESS_TOKEN_LIFETIME not explicitly configured.")

else:
    warn("SIMPLE_JWT configuration not found.")

search_files = [
    path
    for path in Path("apps").rglob("*.py")
    if "__pycache__" not in path.parts
]

session_text_found = False
admin_three_hour_hint = False
user_ten_minute_hint = False

for path in search_files:
    try:
        text = path.read_text(
            encoding="utf-8",
            errors="ignore",
        ).lower()

        if "10" in text and "minute" in text:
            user_ten_minute_hint = True

        if "3" in text and "hour" in text:
            admin_three_hour_hint = True

    except Exception:
        pass

if user_ten_minute_hint:
    info("Possible 10-minute session/token logic found in source.")
else:
    warn(
        "No clear 10-minute user session implementation detected "
        "by static audit."
    )

if admin_three_hour_hint:
    info("Possible 3-hour admin session/token logic found in source.")
else:
    warn(
        "No clear 3-hour admin session implementation detected "
        "by static audit."
    )


# ============================================================
# 24. GIT SECRET SAFETY
# ============================================================

header("24. GIT / SECRET SAFETY")

try:
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "--error-unmatch",
            "automotive_backend/serviceAccountKey.json",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        fail(
            "CRITICAL: serviceAccountKey.json is tracked by Git. "
            "Remove it from version control immediately."
        )
    else:
        ok("serviceAccountKey.json is not tracked by Git.")

except Exception as exc:
    warn(f"Could not check Git tracking status: {exc}")


# ============================================================
# 25. REQUIRED PROJECT FILES
# ============================================================

header("25. REQUIRED BACKEND FILES")

required_files = [
    "manage.py",
    "requirements.txt",
    "automotive_backend/settings.py",
    "automotive_backend/urls.py",
    "automotive_backend/firebase_config.py",

    "apps/accounts/models.py",
    "apps/accounts/serializers.py",
    "apps/accounts/views.py",
    "apps/accounts/urls.py",

    "apps/vehicles/models.py",
    "apps/vehicles/serializers.py",
    "apps/vehicles/views.py",
    "apps/vehicles/urls.py",

    "apps/diagnosis/models.py",
    "apps/diagnosis/serializers.py",
    "apps/diagnosis/views.py",
    "apps/diagnosis/urls.py",

    "apps/payments/models.py",
    "apps/payments/serializers.py",
    "apps/payments/views.py",
    "apps/payments/urls.py",

    "apps/notifications/models.py",
    "apps/notifications/serializers.py",
    "apps/notifications/views.py",
    "apps/notifications/services.py",
    "apps/notifications/urls.py",
]

for path in required_files:
    if file_exists(path):
        ok(path)
    else:
        fail(f"Missing required file: {path}")


# ============================================================
# 26. REQUIREMENTS
# ============================================================

header("26. PYTHON DEPENDENCIES")

requirements_file = Path("requirements.txt")

if requirements_file.exists():
    requirements_text = requirements_file.read_text(
        encoding="utf-8",
        errors="ignore",
    ).lower()

    expected_packages = [
        "django",
        "djangorestframework",
        "firebase-admin",
        "djangorestframework-simplejwt",
        "django-cors-headers",
    ]

    for package in expected_packages:
        if package in requirements_text:
            ok(f"requirements.txt mentions {package}")
        else:
            warn(f"requirements.txt does not clearly mention {package}")
else:
    fail("requirements.txt does not exist.")


# ============================================================
# 27. AUDIT SUMMARY
# ============================================================

header("FINAL AUDIT RESULT")

print(f"PASS         : {PASS}")
print(f"FAIL         : {FAIL}")
print(f"WARN         : {WARN}")
print(f"NOT VERIFIED : {NOT_VERIFIED}")

print("\n" + "-" * 78)

if FAIL == 0 and NOT_VERIFIED == 0:
    print("[RESULT] BACKEND FULLY VERIFIED")
elif FAIL == 0:
    print("[RESULT] BACKEND CORE IS WORKING, BUT SOME PRODUCTION FEATURES ARE NOT VERIFIED")
else:
    print("[RESULT] BACKEND IS NOT YET COMPLETE")

print("-" * 78)

print("\nIMPORTANT:")
print("PASS means the audit verified the item.")
print("WARN means the item exists but still needs production review.")
print("FAIL means there is a concrete backend problem.")
print("NOT VERIFIED means hardware/live service/frontend verification is still required.")

print("\nThis audit does NOT perform destructive database changes.")
print("It does NOT create payments.")
print("It does NOT send notifications.")
print("It does NOT perform real payment transactions.")
print("It does NOT claim real OBD hardware works.")

print("\nNext decision:")
if FAIL > 0:
    print("1. Fix every FAIL first.")
elif NOT_VERIFIED > 0 or WARN > 0:
    print("1. Review WARN and NOT VERIFIED items.")
    print("2. Complete only the backend items that are actually required.")
    print("3. Then begin Flutter integration.")
else:
    print("1. Backend audit is clean.")
    print("2. Proceed to Flutter integration.")
