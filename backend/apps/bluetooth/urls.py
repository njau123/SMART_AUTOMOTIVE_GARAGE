from django.urls import path

from .views import (
    BluetoothConnectView,
    BluetoothConnectionCommandListCreateView,
    BluetoothConnectionDetailView,
    BluetoothConnectionListCreateView,
    BluetoothDeviceDetailView,
    BluetoothDeviceListCreateView,
    BluetoothDisconnectView,
    BluetoothTelemetryLatestView,
    BluetoothTelemetryListCreateView,
)

app_name = "bluetooth"

urlpatterns = [
    path(
        "devices/",
        BluetoothDeviceListCreateView.as_view(),
        name="device-list-create",
    ),

    path(
        "devices/<int:pk>/",
        BluetoothDeviceDetailView.as_view(),
        name="device-detail",
    ),

    path(
        "connections/",
        BluetoothConnectionListCreateView.as_view(),
        name="connection-list-create",
    ),

    path(
        "connections/<int:pk>/",
        BluetoothConnectionDetailView.as_view(),
        name="connection-detail",
    ),

    path(
        "connections/<int:pk>/connect/",
        BluetoothConnectView.as_view(),
        name="connection-connect",
    ),

    path(
        "connections/<int:pk>/disconnect/",
        BluetoothDisconnectView.as_view(),
        name="connection-disconnect",
    ),

    path(
        "connections/<int:connection_id>/commands/",
        BluetoothConnectionCommandListCreateView.as_view(),
        name="connection-commands",
    ),

    path(
        "connections/<int:connection_id>/telemetry/",
        BluetoothTelemetryListCreateView.as_view(),
        name="connection-telemetry",
    ),

    path(
        "connections/<int:connection_id>/telemetry/latest/",
        BluetoothTelemetryLatestView.as_view(),
        name="connection-telemetry-latest",
    ),
]