from django.urls import path

from .views import (
    AnalyticsEventCreateView,
    AnalyticsOverviewView,
    UserAnalyticsView,
)


app_name = "analytics"


urlpatterns = [
    path(
        "events/",
        AnalyticsEventCreateView.as_view(),
        name="event-create",
    ),

    path(
        "overview/",
        AnalyticsOverviewView.as_view(),
        name="overview",
    ),

    path(
        "me/",
        UserAnalyticsView.as_view(),
        name="user-analytics",
    ),
]