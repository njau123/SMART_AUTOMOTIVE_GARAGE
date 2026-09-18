"""
Seed initial data for Smart Automotive Garage.
Correct version - matches actual model fields.
"""
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils.text import slugify


class Command(BaseCommand):
    help = "Seed initial data (spare parts, services, news, ads)"

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("=== Starting comprehensive seed ===\n"))
        self._seed_spare_parts()
        self._seed_services()
        self._seed_news()
        self._seed_ads()
        self.stdout.write(self.style.SUCCESS("\n=== Seed complete ==="))

    def _seed_spare_parts(self):
        from apps.spare_parts.models import Category, Brand, SparePart

        # Categories
        for name in ["Engine Parts", "Brake System", "Suspension", "Electrical", "Filters"]:
            Category.objects.get_or_create(
                slug=slugify(name),
                defaults={"name": name, "description": f"{name} category"},
            )

        # Brands
        for name in ["Toyota", "Nissan", "Mazda", "BMW", "Honda", "Mitsubishi", "Ford", "Hyundai"]:
            Brand.objects.get_or_create(
                slug=slugify(name),
                defaults={"name": name},
            )

        # Spare Parts
        parts = [
            ("Front Brake Pads - Toyota Camry 2015-2020", "Toyota", "Brake System", Decimal("85000"), 20, "BP-TOY-001"),
            ("Oil Filter - Nissan X-Trail", "Nissan", "Filters", Decimal("15000"), 50, "OF-NIS-002"),
            ("Air Filter - Mazda CX-5", "Mazda", "Filters", Decimal("25000"), 30, "AF-MAZ-003"),
            ("Spark Plug - BMW 3 Series", "BMW", "Engine Parts", Decimal("35000"), 40, "SP-BMW-004"),
            ("Shock Absorber - Honda CRV", "Honda", "Suspension", Decimal("150000"), 10, "SA-HON-005"),
            ("Alternator - Mitsubishi Pajero", "Mitsubishi", "Electrical", Decimal("350000"), 5, "AL-MIT-006"),
            ("Fuel Filter - Ford Ranger", "Ford", "Filters", Decimal("45000"), 15, "FF-FOR-007"),
            ("Wiper Blades - Hyundai Tucson", "Hyundai", "Electrical", Decimal("20000"), 25, "WB-HYU-008"),
            ("Timing Belt - Toyota Land Cruiser", "Toyota", "Engine Parts", Decimal("120000"), 8, "TB-TOY-009"),
            ("Battery 12V 60Ah - Universal", "Toyota", "Electrical", Decimal("250000"), 12, "BT-UNI-010"),
        ]
        created = 0
        for name, brand_name, cat_name, price, stock, part_num in parts:
            try:
                brand = Brand.objects.get(slug=slugify(brand_name))
                category = Category.objects.get(slug=slugify(cat_name))
                _, was_created = SparePart.objects.get_or_create(
                    slug=slugify(name),
                    defaults={
                        "name": name,
                        "description": f"High quality {name}",
                        "short_description": name[:100],
                        "brand": brand,
                        "category": category,
                        "part_number": part_num,
                        "price": price,
                        "stock_quantity": stock,
                        "minimum_stock": 5,
                        "status": "AVAILABLE",
                        "condition": "NEW",
                        "is_active": True,
                    },
                )
                if was_created:
                    created += 1
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"    Skip {name}: {e}"))
        self.stdout.write(
            f"  [OK] SpareParts: {created} created, {SparePart.objects.count()} total "
            f"(Brands: {Brand.objects.count()}, Categories: {Category.objects.count()})"
        )

    def _seed_services(self):
        from apps.services.models import ServiceCategory, Service

        cats = ["Engine Services", "Brake Services", "Electrical Services"]
        for name in cats:
            ServiceCategory.objects.get_or_create(name=name)

        services = [
            ("Full Engine Diagnostic", "Engine Services", "Complete engine diagnostics", Decimal("30000"), 90),
            ("Oil Change", "Engine Services", "Engine oil and filter replacement", Decimal("50000"), 45),
            ("Brake Pad Replacement", "Brake Services", "Front or rear brake pads", Decimal("80000"), 120),
            ("Brake Fluid Flush", "Brake Services", "Complete brake fluid replacement", Decimal("60000"), 60),
            ("Battery Replacement", "Electrical Services", "Battery testing and replacement", Decimal("40000"), 30),
        ]
        created = 0
        for name, cat_name, desc, price, duration in services:
            try:
                category = ServiceCategory.objects.get(name=cat_name)
                _, was_created = Service.objects.get_or_create(
                    name=name,
                    defaults={
                        "category": category,
                        "description": desc,
                        "base_price": price,
                        "estimated_duration_minutes": duration,
                        "is_active": True,
                    },
                )
                if was_created:
                    created += 1
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"    Skip {name}: {e}"))
        self.stdout.write(
            f"  [OK] Services: {created} created, {Service.objects.count()} total "
            f"(Categories: {ServiceCategory.objects.count()})"
        )

    def _seed_news(self):
        from apps.news.models import NewsCategory, News
        User = get_user_model()

        cats = ["Maintenance Tips", "Product Updates", "Industry News"]
        for name in cats:
            try:
                NewsCategory.objects.get_or_create(slug=slugify(name), defaults={"name": name})
            except Exception:
                NewsCategory.objects.get_or_create(name=name)

        author = User.objects.filter(is_superuser=True).first() or User.objects.first()
        if not author:
            self.stdout.write(self.style.WARNING("  ! No user for news author, skipping"))
            return

        news_items = [
            ("Welcome to Smart Automotive Garage",
             "We are excited to launch our new platform. Get diagnosed, book a mechanic, order parts - all in one place.",
             "Maintenance Tips"),
            ("5 Signs Your Car Needs Immediate Attention",
             "Learn warning signs: strange noises, warning lights, unusual smells, hard starting, fluid leaks.",
             "Maintenance Tips"),
            ("New AI Diagnosis Feature Launched",
             "Our AI-powered car diagnosis is now available. Describe symptoms and get instant possible causes.",
             "Product Updates"),
        ]
        created = 0
        for title, content, cat_name in news_items:
            try:
                category = NewsCategory.objects.get(slug=slugify(cat_name))
                _, was_created = News.objects.get_or_create(
                    slug=slugify(title),
                    defaults={
                        "title": title,
                        "summary": content[:200],
                        "content": content,
                        "category": category,
                        "author": author,
                        "status": "published",
                    },
                )
                if was_created:
                    created += 1
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"    Skip {title}: {e}"))
        self.stdout.write(f"  [OK] News: {created} created, {News.objects.count()} total")

    def _seed_ads(self):
        try:
            from apps.advertisements.models import Advertisement
            from django.utils import timezone
            from datetime import timedelta

            now = timezone.now()
            ads = [
                ("20% Off Engine Diagnostics", "Get 20% off all engine diagnostics this month."),
                ("Free Oil Change with Brake Service", "Book any brake service, get free oil change."),
            ]
            created = 0
            for title, desc in ads:
                try:
                    ref = f"AD-{slugify(title)[:20].upper()}"
                    _, was_created = Advertisement.objects.get_or_create(
                        reference=ref,
                        defaults={
                            "title": title,
                            "description": desc,
                            "advertisement_type": "BANNER",
                            "status": "active",
                            "start_at": now,
                            "end_at": now + timedelta(days=30),
                            "is_active": True,
                        },
                    )
                    if was_created:
                        created += 1
                except Exception as e:
                    self.stdout.write(self.style.WARNING(f"    Skip {title}: {e}"))
            self.stdout.write(f"  [OK] Advertisements: {created} created, {Advertisement.objects.count()} total")
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"  ! Advertisements skipped: {e}"))
