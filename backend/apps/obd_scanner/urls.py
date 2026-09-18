from django.urls import path

from .views import (
    OBDScanCreateView,
    OBDScanDetailView,
    OBDScanHistoryView,
    OBDScanStartView,
    OBDScanUpdateView,
)

app_name = "obd_scanner"

urlpatterns = [
    path("scans/", OBDScanCreateView.as_view(), name="create"),
    path("scans/history/", OBDScanHistoryView.as_view(), name="history"),
    path("scans/<int:pk>/", OBDScanDetailView.as_view(), name="detail"),
    path("scans/<int:pk>/start/", OBDScanStartView.as_view(), name="start"),
    path("scans/<int:pk>/update/", OBDScanUpdateView.as_view(), name="update"),
]
