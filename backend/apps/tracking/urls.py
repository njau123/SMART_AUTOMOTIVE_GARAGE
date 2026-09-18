from django.urls import path

from .views import (
    GeofenceDetailView,
    GeofenceEventListView,
    GeofenceListCreateView,
    MechanicLocationCreateView,
    MechanicLocationHistoryView,
    MyLatestMechanicLocationView,
    TrackingSessionDetailView,
    TrackingSessionListCreateView,
    TrackingSessionPauseView,
    TrackingSessionResumeView,
    TrackingSessionStopView,
    VehicleLatestLocationView,
    VehicleLocationCreateView,
    VehicleLocationHistoryView,
)


app_name = "tracking"


urlpatterns = [
    path(
        "sessions/",
        TrackingSessionListCreateView.as_view(),
        name="session-list-create",
    ),

    path(
        "sessions/<int:pk>/",
        TrackingSessionDetailView.as_view(),
        name="session-detail",
    ),

    path(
        "sessions/<int:pk>/pause/",
        TrackingSessionPauseView.as_view(),
        name="session-pause",
    ),

    path(
        "sessions/<int:pk>/resume/",
        TrackingSessionResumeView.as_view(),
        name="session-resume",
    ),

    path(
        "sessions/<int:pk>/stop/",
        TrackingSessionStopView.as_view(),
        name="session-stop",
    ),

    path(
        "vehicles/location/",
        VehicleLocationCreateView.as_view(),
        name="vehicle-location-create",
    ),

    path(
        "vehicles/<int:vehicle_id>/locations/",
        VehicleLocationHistoryView.as_view(),
        name="vehicle-location-history",
    ),

    path(
        "vehicles/<int:vehicle_id>/location/latest/",
        VehicleLatestLocationView.as_view(),
        name="vehicle-location-latest",
    ),

    path(
        "mechanics/location/",
        MechanicLocationCreateView.as_view(),
        name="mechanic-location-create",
    ),

    path(
        "mechanics/location/latest/",
        MyLatestMechanicLocationView.as_view(),
        name="mechanic-location-latest",
    ),

    path(
        "mechanics/location/history/",
        MechanicLocationHistoryView.as_view(),
        name="mechanic-location-history",
    ),

    path(
        "geofences/",
        GeofenceListCreateView.as_view(),
        name="geofence-list-create",
    ),

    path(
        "geofences/<int:pk>/",
        GeofenceDetailView.as_view(),
        name="geofence-detail",
    ),

    path(
        "geofences/events/",
        GeofenceEventListView.as_view(),
        name="geofence-events",
    ),
]