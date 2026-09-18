from django.urls import path

from .views import (
    AdminDashboardView,
    DashboardView,
    MechanicDashboardView,
    UserDashboardView,
)


app_name = "dashboard"


urlpatterns = [
    path(
        "",
        DashboardView.as_view(),
        name="dashboard",
    ),

    path(
        "user/",
        UserDashboardView.as_view(),
        name="user-dashboard",
    ),

    path(
        "mechanic/",
        MechanicDashboardView.as_view(),
        name="mechanic-dashboard",
    ),

    path(
        "admin/",
        AdminDashboardView.as_view(),
        name="admin-dashboard",
    ),
]