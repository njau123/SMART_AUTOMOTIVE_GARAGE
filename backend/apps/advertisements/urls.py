from rest_framework.routers import DefaultRouter
from .views import AdvertisementViewSet

router = DefaultRouter()
router.register(r'advertisements', AdvertisementViewSet, basename='advertisement')
urlpatterns = router.urls
