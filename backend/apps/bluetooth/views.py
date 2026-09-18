from django.utils import timezone

from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import (
    BluetoothConnectionSession,
    BluetoothDevice,
    OBDCommandLog,
    OBDTelemetry,
)
from .serializers import (
    BluetoothConnectionCreateSerializer,
    BluetoothConnectionSessionSerializer,
    BluetoothDeviceCreateSerializer,
    BluetoothDeviceSerializer,
    OBDCommandLogSerializer,
    OBDTelemetrySerializer,
)


class BluetoothDeviceListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BluetoothDevice.objects.filter(
            user=self.request.user,
            is_active=True,
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return BluetoothDeviceCreateSerializer

        return BluetoothDeviceSerializer

    def perform_create(self, serializer):
        serializer.save(
            user=self.request.user,
        )


class BluetoothDeviceDetailView(
    generics.RetrieveUpdateDestroyAPIView
):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BluetoothDevice.objects.filter(
            user=self.request.user,
        )

    def get_serializer_class(self):
        return BluetoothDeviceSerializer


class BluetoothConnectionListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BluetoothConnectionSession.objects.filter(
            user=self.request.user,
        ).select_related(
            "device",
            "obd_scan",
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return BluetoothConnectionCreateSerializer

        return BluetoothConnectionSessionSerializer

    def perform_create(self, serializer):
        serializer.save(
            user=self.request.user,
        )


class BluetoothConnectionDetailView(
    generics.RetrieveAPIView
):
    permission_classes = [IsAuthenticated]
    serializer_class = BluetoothConnectionSessionSerializer

    def get_queryset(self):
        return BluetoothConnectionSession.objects.filter(
            user=self.request.user,
        ).select_related(
            "device",
            "obd_scan",
        )


class BluetoothConnectView(
    generics.GenericAPIView
):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            connection = (
                BluetoothConnectionSession.objects.get(
                    pk=pk,
                    user=request.user,
                )
            )
        except BluetoothConnectionSession.DoesNotExist:
            return Response(
                {
                    "success": False,
                    "message": "Bluetooth connection session not found.",
                    "data": None,
                    "errors": None,
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        connection.status = "CONNECTED"
        connection.connected_at = timezone.now()
        connection.error_message = ""

        connection.device.status = "CONNECTED"
        connection.device.last_connected_at = timezone.now()

        connection.device.save(
            update_fields=[
                "status",
                "last_connected_at",
                "updated_at",
            ]
        )

        connection.save(
            update_fields=[
                "status",
                "connected_at",
                "error_message",
                "updated_at",
            ]
        )

        return Response(
            {
                "success": True,
                "message": "Bluetooth device connected.",
                "data": BluetoothConnectionSessionSerializer(
                    connection
                ).data,
                "errors": None,
            }
        )


class BluetoothDisconnectView(
    generics.GenericAPIView
):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            connection = (
                BluetoothConnectionSession.objects.get(
                    pk=pk,
                    user=request.user,
                )
            )
        except BluetoothConnectionSession.DoesNotExist:
            return Response(
                {
                    "success": False,
                    "message": "Bluetooth connection session not found.",
                    "data": None,
                    "errors": None,
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        now = timezone.now()

        connection.status = "DISCONNECTED"
        connection.disconnected_at = now

        connection.device.status = "DISCONNECTED"
        connection.device.last_disconnected_at = now

        connection.device.save(
            update_fields=[
                "status",
                "last_disconnected_at",
                "updated_at",
            ]
        )

        connection.save(
            update_fields=[
                "status",
                "disconnected_at",
                "updated_at",
            ]
        )

        return Response(
            {
                "success": True,
                "message": "Bluetooth device disconnected.",
                "data": BluetoothConnectionSessionSerializer(
                    connection
                ).data,
                "errors": None,
            }
        )


class BluetoothConnectionCommandListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [IsAuthenticated]
    serializer_class = OBDCommandLogSerializer

    def get_queryset(self):
        return OBDCommandLog.objects.filter(
            connection__id=self.kwargs["connection_id"],
            connection__user=self.request.user,
        )

    def perform_create(self, serializer):
        connection = (
            BluetoothConnectionSession.objects.get(
                id=self.kwargs["connection_id"],
                user=self.request.user,
            )
        )

        serializer.save(
            connection=connection,
        )


class BluetoothTelemetryListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [IsAuthenticated]
    serializer_class = OBDTelemetrySerializer

    def get_queryset(self):
        return OBDTelemetry.objects.filter(
            connection__id=self.kwargs["connection_id"],
            connection__user=self.request.user,
        )

    def perform_create(self, serializer):
        connection = (
            BluetoothConnectionSession.objects.get(
                id=self.kwargs["connection_id"],
                user=self.request.user,
            )
        )

        serializer.save(
            connection=connection,
        )


class BluetoothTelemetryLatestView(
    generics.ListAPIView
):
    permission_classes = [IsAuthenticated]
    serializer_class = OBDTelemetrySerializer

    def get_queryset(self):
        return (
            OBDTelemetry.objects.filter(
                connection__id=self.kwargs["connection_id"],
                connection__user=self.request.user,
            )
            .order_by("-recorded_at")[:100]
        )