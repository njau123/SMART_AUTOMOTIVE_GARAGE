import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'automotive_backend.settings')
django.setup()

from apps.spare_parts.models import SparePart, Category, Brand

print("=== TEST CREATE SPARE PART ===")
try:
    cat, _ = Category.objects.get_or_create(
        slug='general',
        defaults={'name': 'General', 'is_active': True},
    )
    print(f"Category: {cat.id} - {cat.name}")

    part = SparePart.objects.create(
        name='Test Part Shell',
        slug='test-part-shell-001',
        description='Test description',
        short_description='Test',
        category=cat,
        part_number='TST-SH-001',
        price=1000,
        stock_quantity=5,
        condition='new',
        status='AVAILABLE',
        is_active=True,
    )
    print(f"✅ SUCCESS: ID={part.id}, Name={part.name}")
    part.delete()
    print("✅ Cleanup: imefutwa")
except Exception as e:
    import traceback
    print("❌ ERROR:")
    traceback.print_exc()
