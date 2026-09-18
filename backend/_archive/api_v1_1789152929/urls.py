from django.urls import path
from .views import (
    RegisterView,
    UserProfileView,
    MechanicProfileView,
    MechanicListView
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    # Auth
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # User Profile
    path('users/profile/', UserProfileView.as_view(), name='user_profile'),

    # Mechanic
    path('mechanics/profile/', MechanicProfileView.as_view(), name='mechanic_profile'),
    path('mechanics/', MechanicListView.as_view(), name='mechanic_list'),
]
