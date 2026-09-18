from django.urls import path
from .views import (
    MechanicActivateView,
    MechanicLoginView,
    MechanicProfileView,
    ToggleAvailabilityView,
    MyAssignedJobsView,
    MechanicResetPasswordView,
    RegisterMechanicView,  # legacy
)

urlpatterns = [
    # Public
    path('activate/', MechanicActivateView.as_view(), name='mechanic-activate'),
    path('login/', MechanicLoginView.as_view(), name='mechanic-login'),
    path('reset-password/', MechanicResetPasswordView.as_view(), name='mechanic-reset-password'),
    path('register/mechanic/', RegisterMechanicView.as_view(), name='register-mechanic-legacy'),

    # Mechanic (authenticated)
    path('profile/', MechanicProfileView.as_view(), name='mechanic-profile'),
    path('toggle-availability/', ToggleAvailabilityView.as_view(), name='mechanic-toggle'),
    path('my-jobs/', MyAssignedJobsView.as_view(), name='mechanic-jobs'),
]
