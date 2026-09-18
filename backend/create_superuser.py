import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'automotive_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'njau')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'njaufredrick0@gmail.com')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')

if not password:
    print("[SKIP] DJANGO_SUPERUSER_PASSWORD not set")
    exit(0)

if User.objects.filter(username=username).exists():
    print(f"[SKIP] Superuser '{username}' already exists")
else:
    User.objects.create_superuser(username=username, email=email, password=password)
    print(f"[OK] Superuser '{username}' created")
