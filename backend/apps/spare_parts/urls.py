from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CategoryViewSet, BrandViewSet, SparePartViewSet

router = DefaultRouter()
router.register(r'categories', CategoryViewSet, basename='spare-category')
router.register(r'brands', BrandViewSet, basename='spare-brand')
router.register(r'parts', SparePartViewSet, basename='spare-part')

urlpatterns = [
    path('', include(router.urls)),
]
