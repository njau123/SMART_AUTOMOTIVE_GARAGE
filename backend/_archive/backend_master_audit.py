import os
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parent

EXPECTED_APPS = [
    "accounts",
    "vehicles",
    "mechanics",
    "services",
    "bookings",
    "spare_parts",
    "diagnosis",
    "obd_scanner",
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
    "reports",
    "audit_logs",
    "system",
]

EXPECTED_ROUTE_KEYWORDS = [
    "/auth/",
    "/vehicles/",
    "/mechanics/",
    "/services/",
    "/bookings/",
    "/spare-parts/",
    "/diagnosis/",
    "/wallet/",
    "/payments/",
    "/notifications/",
    "/news/",
    "/advertisements/",
    "/tracking/",
    "/reviews/",
    "/chat/",
    "/dashboard/",
    "/analytics/",
    "/reports/",
]

REQUIRED_FILES = [
    "models.py",
    "serializers.py",
    "views.py",
    "urls.py",
    "admin.py",
]

def header(title):
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)

def run_command(command):
    result = subprocess.run(
        command,
        shell=True,
        cwd=BASE,
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout, result.stderr

header("SMART AUTOMOTIVE GARAGE — BACKEND MASTER AUDIT")

print(f"Backend: {BASE}")

# ---------------------------------------------------------
# 1. Django check
# ---------------------------------------------------------
header("1. DJANGO SYSTEM CHECK")

code, stdout, stderr = run_command(
    "python manage.py check"
)

print(stdout.strip())

if code == 0:
    print("RESULT: ✅ Django system check PASSED")
else:
    print("RESULT: ❌ Django system check FAILED")
    print(stderr.strip())

# ---------------------------------------------------------
# 2. Migrations
# ---------------------------------------------------------
header("2. MIGRATION AUDIT")

code, stdout, stderr = run_command(
    "python manage.py showmigrations"
)

print(stdout.strip())

if code == 0:
    print("RESULT: ✅ Migration command works")
else:
    print("RESULT: ❌ Migration audit failed")

# ---------------------------------------------------------
# 3. Installed apps
# ---------------------------------------------------------
header("3. INSTALLED / DISCOVERED APPS")

code, stdout, stderr = run_command(
    'python manage.py shell -c "from django.apps import apps; print([a.name for a in apps.get_app_configs()])"'
)

print(stdout.strip())

# ---------------------------------------------------------
# 4. Expected app directories
# ---------------------------------------------------------
header("4. EXPECTED APP DIRECTORY AUDIT")

missing_apps = []
existing_apps = []

for app in EXPECTED_APPS:
    possible_paths = [
        BASE / app,
        BASE / "apps" / app,
    ]

    found = None

    for path in possible_paths:
        if path.exists() and path.is_dir():
            found = path
            break

    if found:
        existing_apps.append(app)
        print(f"✅ {app:<20} {found.relative_to(BASE)}")
    else:
        missing_apps.append(app)
        print(f"❌ {app:<20} NOT FOUND")

# ---------------------------------------------------------
# 5. Required files
# ---------------------------------------------------------
header("5. MODULE FILE AUDIT")

for app in existing_apps:
    possible_paths = [
        BASE / app,
        BASE / "apps" / app,
    ]

    app_path = next(
        p for p in possible_paths
        if p.exists() and p.is_dir()
    )

    print(f"\n[{app}]")

    for filename in REQUIRED_FILES:
        path = app_path / filename

        if path.exists():
            size = path.stat().st_size
            print(
                f"  ✅ {filename:<18} {size} bytes"
            )
        else:
            print(
                f"  ⚠️ {filename:<18} MISSING"
            )

# ---------------------------------------------------------
# 6. URLs
# ---------------------------------------------------------
header("6. API URL AUDIT")

code, stdout, stderr = run_command(
    'python manage.py shell -c "from django.urls import get_resolver; print(chr(10).join(str(x) for x in get_resolver().url_patterns))"'
)

if code == 0:
    urls_text = stdout
    print(urls_text[:30000])

    for keyword in EXPECTED_ROUTE_KEYWORDS:
        if keyword in urls_text:
            print(f"✅ {keyword}")
        else:
            print(f"❌ {keyword} NOT DETECTED")
else:
    print("❌ Could not inspect Django URL resolver")
    print(stderr)

# ---------------------------------------------------------
# 7. Models
# ---------------------------------------------------------
header("7. DATABASE MODEL AUDIT")

code, stdout, stderr = run_command(
    'python manage.py shell -c "from django.apps import apps; [(print(a.label, \':\', \', \'.join(m.__name__ for m in a.get_models()))) for a in apps.get_app_configs()]"'
)

if code == 0:
    print(stdout[:30000])
else:
    print("❌ Could not inspect models")
    print(stderr)

# ---------------------------------------------------------
# 8. Important configuration checks
# ---------------------------------------------------------
header("8. SETTINGS / CONFIGURATION AUDIT")

settings_file = BASE / "automotive_backend" / "settings.py"

if settings_file.exists():
    settings = settings_file.read_text(
        encoding="utf-8",
        errors="ignore"
    )

    checks = {
        "REST_FRAMEWORK": "REST_FRAMEWORK" in settings,
        "SIMPLE_JWT": "SIMPLE_JWT" in settings,
        "CORS": (
            "corsheaders" in settings
            or "CORS_ALLOWED_ORIGINS" in settings
        ),
        "PostgreSQL": (
            "postgresql" in settings.lower()
        ),
        "Firebase": (
            "firebase" in settings.lower()
        ),
        "MEDIA_ROOT": "MEDIA_ROOT" in settings,
        "MEDIA_URL": "MEDIA_URL" in settings,
        "STATIC_ROOT": "STATIC_ROOT" in settings,
    }

    for name, ok in checks.items():
        print(
            f"{'✅' if ok else '⚠️'} {name}"
        )

else:
    print("❌ automotive_backend/settings.py not found")

# ---------------------------------------------------------
# 9. Environment files
# ---------------------------------------------------------
header("9. ENVIRONMENT / SECURITY FILE AUDIT")

for filename in [
    ".env",
    ".env.example",
    ".gitignore",
    "requirements.txt",
]:
    path = BASE / filename

    if path.exists():
        print(f"✅ {filename}")
    else:
        print(f"⚠️ {filename} missing")

# ---------------------------------------------------------
# 10. Search for hard-coded secrets/passwords
# ---------------------------------------------------------
header("10. POSSIBLE HARDCODED SECRET AUDIT")

patterns = [
    r'password\s*=\s*["\']',
    r'API_KEY\s*=\s*["\']',
    r'API_SECRET\s*=\s*["\']',
    r'SECRET_KEY\s*=\s*["\']',
    r'FIREBASE_PRIVATE_KEY',
]

hits = []

for path in BASE.rglob("*.py"):
    if any(
        part in {
            ".venv",
            "venv",
            "__pycache__",
            ".git",
        }
        for part in path.parts
    ):
        continue

    try:
        text = path.read_text(
            encoding="utf-8",
            errors="ignore"
        )
    except Exception:
        continue

    for pattern in patterns:
        if re.search(pattern, text, re.IGNORECASE):
            hits.append(
                str(path.relative_to(BASE))
            )
            break

if hits:
    for item in sorted(set(hits)):
        print(f"⚠️ Possible secret in: {item}")
else:
    print("✅ No obvious hard-coded secret pattern found")

# ---------------------------------------------------------
# 11. Admin
# ---------------------------------------------------------
header("11. ADMIN REGISTRATION AUDIT")

admin_files = []

for app in existing_apps:
    possible_paths = [
        BASE / app,
        BASE / "apps" / app,
    ]

    app_path = next(
        p for p in possible_paths
        if p.exists() and p.is_dir()
    )

    admin_path = app_path / "admin.py"

    if admin_path.exists():
        admin_files.append(str(
            admin_path.relative_to(BASE)
        ))

if admin_files:
    for path in admin_files:
        print(f"✅ {path}")
else:
    print("⚠️ No admin.py files detected")

# ---------------------------------------------------------
# 12. Summary
# ---------------------------------------------------------
header("12. AUDIT SUMMARY")

print(
    f"Existing expected apps : {len(existing_apps)}"
)
print(
    f"Missing expected apps  : {len(missing_apps)}"
)

if missing_apps:
    print("\nMissing apps:")
    for app in missing_apps:
        print(f"  ❌ {app}")

print("\nIMPORTANT:")
print(
    "This audit checks structure, Django health, URLs, "
    "models, configuration and files."
)
print(
    "It does NOT automatically prove that every business "
    "workflow/payment/Firebase/Flutter integration works."
)
print(
    "Those require endpoint-level functional tests."
)

print("\nDONE.")
