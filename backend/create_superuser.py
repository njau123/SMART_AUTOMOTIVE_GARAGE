"""
Auto-create superuser from env vars on deploy.
Adapted for custom User model (email-based, no username).
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'automotive_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'njaufredrick0@gmail.com').strip().lower()
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
first_name = os.environ.get('DJANGO_SUPERUSER_FIRST_NAME', 'Fred')
last_name = os.environ.get('DJANGO_SUPERUSER_LAST_NAME', 'Njau')
phone_number = os.environ.get('DJANGO_SUPERUSER_PHONE', '+255700000000')

if not password:
    print("[SKIP] DJANGO_SUPERUSER_PASSWORD not set")
    exit(0)

if User.objects.filter(email=email).exists():
    print(f"[SKIP] Superuser '{email}' already exists")
else:
    User.objects.create_superuser(
        email=email,
        password=password,
        first_name=first_name,
        last_name=last_name,
        phone_number=phone_number,
    )
    print(f"[OK] Superuser '{email}' created")
