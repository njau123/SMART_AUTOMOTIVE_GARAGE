from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, EmailTokenObtainPairView, google_sign_in,
    AdminUserViewSet,
)

router = DefaultRouter()
router.register(r'admin/users', AdminUserViewSet, basename='admin-user')

from api.password_reset_views import (
    RequestPasswordResetView,
    VerifyResetCodeView,
    ResetPasswordView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', EmailTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('google/', google_sign_in, name='google_sign_in'),
    # Password reset
    path('password-reset/request/', RequestPasswordResetView.as_view(), name='password-reset-request'),
    path('password-reset/verify/', VerifyResetCodeView.as_view(), name='password-reset-verify'),
    path('password-reset/confirm/', ResetPasswordView.as_view(), name='password-reset-confirm'),
    path('', include(router.urls)),
]
