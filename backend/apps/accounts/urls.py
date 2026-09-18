from django.urls import path
from .views import RegisterView, EmailTokenObtainPairView, google_sign_in
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', EmailTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('google/', google_sign_in, name='google_sign_in'),
]
