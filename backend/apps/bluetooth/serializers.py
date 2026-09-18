from rest_framework import serializers

from .models import (
    BluetoothConnectionSession,
    BluetoothDevice,
    OBDCommandLog,
    OBDTelemetry,
)


class BluetoothDeviceSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = BluetoothDevice
        fields = [
            "id",
            "device_id",
            "name",
            "device_type",
            "connection_type",
            "mac_address",
            "manufacturer",
            "model_name",
            "firmware_version",
            "hardware_version",
            "protocol",
            "status",
            "is_paired",
            "is_trusted",
            "is_active",
            "last_connected_at",
            "last_disconnected_at",
            "metadata",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "last_connected_at",
            "last_disconnected_at",
            "created_at",
            "updated_at",
        ]


class BluetoothDeviceCreateSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = BluetoothDevice
        fields = [
            "device_id",
            "name",
            "device_type",
            "connection_type",
            "mac_address",
            "manufacturer",
            "model_name",
            "firmware_version",
            "hardware_version",
            "protocol",
            "metadata",
        ]

    def validate_device_id(self, value):
        request = self.context.get("request")

        if request and request.user.is_authenticated:
            exists = BluetoothDevice.objects.filter(
                user=request.user,
                device_id=value,
            ).exists()

            if exists:
                raise serializers.ValidationError(
                    "This Bluetooth device is already registered."
                )

        return value


class BluetoothConnectionSessionSerializer(
    serializers.ModelSerializer
):
    device = BluetoothDeviceSerializer(
        read_only=True,
    )

    class Meta:
        model = BluetoothConnectionSession
        fields = [
            "id",
            "reference",
            "device",
            "obd_scan",
            "status",
            "connection_type",
            "transport_identifier",
            "error_message",
            "connected_at",
            "disconnected_at",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "reference",
            "device",
            "connected_at",
            "disconnected_at",
            "created_at",
            "updated_at",
        ]


class BluetoothConnectionCreateSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = BluetoothConnectionSession
        fields = [
            "device",
            "obd_scan",
            "connection_type",
            "transport_identifier",
        ]

    def validate_device(self, device):
        request = self.context.get("request")

        if request and device.user_id != request.user.id:
            raise serializers.ValidationError(
                "This Bluetooth device does not belong to you."
            )

        return device

    def validate_obd_scan(self, obd_scan):
        request = self.context.get("request")

        if (
            request
            and obd_scan
            and obd_scan.user_id != request.user.id
        ):
            raise serializers.ValidationError(
                "This OBD scan does not belong to you."
            )

        return obd_scan


class OBDCommandLogSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = OBDCommandLog
        fields = [
            "id",
            "command",
            "direction",
            "raw_data",
            "decoded_data",
            "successful",
            "error_message",
            "response_time_ms",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
        ]


class OBDTelemetrySerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = OBDTelemetry
        fields = [
            "id",
            "scan",
            "pid",
            "name",
            "value",
            "unit",
            "raw_value",
            "latitude",
            "longitude",
            "recorded_at",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
        ]