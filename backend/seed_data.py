"""
Seed sample advertisements + news for testing.
Run: python manage.py shell < seed_data.py
"""
import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'automotive_backend.settings')
django.setup()

from apps.advertisements.models import Advertisement, AdvertisementType, AdvertisementStatus
from apps.news.models import News, NewsCategory
from django.contrib.auth import get_user_model

User = get_user_model()

# Admin user
admin = User.objects.filter(is_superuser=True).first()

# === ADVERTISEMENTS ===
ads_data = [
    {
        "title": "Karibu Smart Garage",
        "description": "Huduma bora za gari - Service, Spare Parts, Mechanics",
        "advertisement_type": AdvertisementType.BANNER,
        "priority": 10,
    },
    {
        "title": "Punguzo la 20% - Service",
        "description": "Pata punguzo la 20% kwa huduma zote za service mwezi huu",
        "advertisement_type": AdvertisementType.CARD,
        "priority": 5,
    },
    {
        "title": "Spare Parts Original",
        "description": "Tunauza spare parts halisi kwa bei nafuu",
        "advertisement_type": AdvertisementType.BANNER,
        "priority": 8,
    },
]

created_ads = 0
for ad_data in ads_data:
    if not Advertisement.objects.filter(title=ad_data['title']).exists():
        ad = Advertisement(
            title=ad_data['title'],
            description=ad_data['description'],
            advertisement_type=ad_data['advertisement_type'],
            status=AdvertisementStatus.ACTIVE,
            start_at=timezone.now(),
            end_at=timezone.now() + timedelta(days=30),
            priority=ad_data['priority'],
            is_active=True,
            created_by=admin,
        )
        ad.save()
        created_ads += 1
        print(f"✅ Ad: {ad.title}")

print(f"\n📢 Advertisements zilizoundwa: {created_ads}")

# === NEWS ===
# Category
cat, _ = NewsCategory.objects.get_or_create(
    slug="updates",
    defaults={"name": "Updates", "description": "Updates kutoka Smart Garage"}
)

news_data = [
    {
        "title": "Updates Mpya za Smart Garage",
        "slug": "updates-mpya-smart-garage",
        "summary": "Tunafurahi kuwasilisha updates mpya",
        "content": "Smart Garage imeongeza huduma mpya za AI diagnosis na OBD scanner. Karibu ujaribu!",
        "is_breaking": True,
    },
    {
        "title": "Mechanics Wapya Wamejiunga",
        "slug": "mechanics-wapya-wamejiunga",
        "summary": "Mechanics wapya wenye uzoefu",
        "content": "Tumepokea mechanics wapya 10 wenye uzoefu wa miaka 5+. Karibu kuwafahamu!",
        "is_featured": True,
    },
    {
        "title": "OBD Scanner Sasa Inapatikana",
        "slug": "obd-scanner-sasa-inapatikana",
        "summary": "Scan gari yako kwa dakika 5",
        "content": "Kwa sasa unaweza kuscan gari yako kwa kutumia OBD scanner yetu. Pata ripoti kamili ya afya ya gari yako.",
    },
]

created_news = 0
for news_item in news_data:
    if not News.objects.filter(slug=news_item['slug']).exists():
        n = News(
            title=news_item['title'],
            slug=news_item['slug'],
            summary=news_item['summary'],
            content=news_item['content'],
            category=cat,
            author=admin,
            status='published',
            published_at=timezone.now(),
            is_featured=news_item.get('is_featured', False),
            is_breaking=news_item.get('is_breaking', False),
        )
        n.save()
        created_news += 1
        print(f"✅ News: {n.title}")

print(f"\n📰 News zilizoundwa: {created_news}")
print(f"\n✅ JUMLA: {created_ads} ads + {created_news} news")
