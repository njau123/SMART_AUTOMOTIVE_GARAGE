from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WalletViewSet, WithdrawalRequestViewSet

router = DefaultRouter()
router.register(r'wallets', WalletViewSet, basename='wallet')
router.register(r'withdrawals', WithdrawalRequestViewSet, basename='withdrawal')

urlpatterns = [
    path('', include(router.urls)),
]
