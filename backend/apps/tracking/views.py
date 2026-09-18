from django.utils import timezone

from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.vehicles.models import Vehicle

from .models import (
    Geofence,
    GeofenceEvent,
    MechanicLocation,
    TrackingSession,
    TrackingSessionStatus,
    VehicleLocation,
)
from .serializers import (
    GeofenceEventSerializer,
    GeofenceSerializer,
    MechanicLocationSerializer,
    TrackingSessionSerializer,
    VehicleLocationSerializer,
)
from .services import TrackingService


def success_response(
    message,
    data=None,
    status_code=status.HTTP_200_OK,
):
    return Response(
        {
            "success": True,
            "message": message,
            "data": data,
            "errors": None,
        },
        status=status_code,
    )


def error_response(
    message,
    errors=None,
    status_code=status.HTTP_400_BAD_REQUEST,
):
    return Response(
        {
            "success": False,
            "message": message,
            "data": None,
            "errors": errors,
        },
        status=status_code,
    )


class TrackingSessionListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = TrackingSessionSerializer

    def get_queryset(self):
        return TrackingSession.objects.filter(
            user=self.request.user
        )

    def create(self, request, *args, **kwargs):
        vehicle_id = request.data.get(
            "vehicle"
        )

        vehicle = None

        if vehicle_id:
            try:
                vehicle = Vehicle.objects.get(
                    id=vehicle_id,
                    owner=request.user,
                )
            except Vehicle.DoesNotExist:
                return error_response(
                    "Vehicle not found.",
                    status_code=404,
                )

        session = TrackingService.start_session(
            user=request.user,
            vehicle=vehicle,
            tracking_type=request.data.get(
                "tracking_type",
                "VEHICLE",
            ),
            metadata=request.data.get(
                "metadata",
                {},
            ),
        )

        return success_response(
            "Tracking session started.",
            TrackingSessionSerializer(
                session
            ).data,
            status.HTTP_201_CREATED,
        )


class TrackingSessionDetailView(
    generics.RetrieveAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = TrackingSessionSerializer

    def get_queryset(self):
        return TrackingSession.objects.filter(
            user=self.request.user
        )


class TrackingSessionPauseView(
    generics.GenericAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    def post(self, request, pk):
        try:
            session = TrackingSession.objects.get(
                id=pk,
                user=request.user,
            )
        except TrackingSession.DoesNotExist:
            return error_response(
                "Tracking session not found.",
                status_code=404,
            )

        if (
            session.status
            != TrackingSessionStatus.ACTIVE
        ):
            return error_response(
                "Only active sessions can be paused."
            )

        TrackingService.pause_session(
            session
        )

        return success_response(
            "Tracking session paused.",
            TrackingSessionSerializer(
                session
            ).data,
        )


class TrackingSessionResumeView(
    generics.GenericAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    def post(self, request, pk):
        try:
            session = TrackingSession.objects.get(
                id=pk,
                user=request.user,
            )
        except TrackingSession.DoesNotExist:
            return error_response(
                "Tracking session not found.",
                status_code=404,
            )

        if (
            session.status
            != TrackingSessionStatus.PAUSED
        ):
            return error_response(
                "Only paused sessions can be resumed."
            )

        TrackingService.resume_session(
            session
        )

        return success_response(
            "Tracking session resumed.",
            TrackingSessionSerializer(
                session
            ).data,
        )


class TrackingSessionStopView(
    generics.GenericAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    def post(self, request, pk):
        try:
            session = TrackingSession.objects.get(
                id=pk,
                user=request.user,
            )
        except TrackingSession.DoesNotExist:
            return error_response(
                "Tracking session not found.",
                status_code=404,
            )

        if session.status in [
            TrackingSessionStatus.COMPLETED,
            TrackingSessionStatus.CANCELLED,
        ]:
            return error_response(
                "Tracking session is already closed."
            )

        TrackingService.stop_session(
            session
        )

        return success_response(
            "Tracking session stopped.",
            TrackingSessionSerializer(
                session
            ).data,
        )


class VehicleLocationCreateView(
    generics.CreateAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = VehicleLocationSerializer

    def create(self, request, *args, **kwargs):
        vehicle_id = request.data.get(
            "vehicle"
        )

        session_id = request.data.get(
            "session"
        )

        try:
            vehicle = Vehicle.objects.get(
                id=vehicle_id,
                owner=request.user,
            )
        except Vehicle.DoesNotExist:
            return error_response(
                "Vehicle not found.",
                status_code=404,
            )

        try:
            session = TrackingSession.objects.get(
                id=session_id,
                user=request.user,
                vehicle=vehicle,
            )
        except TrackingSession.DoesNotExist:
            return error_response(
                "Tracking session not found.",
                status_code=404,
            )

        if (
            session.status
            != TrackingSessionStatus.ACTIVE
        ):
            return error_response(
                "Tracking session is not active."
            )

        serializer = self.get_serializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )

        location = (
            TrackingService.record_vehicle_location(
                session=session,
                vehicle=vehicle,
                latitude=serializer.validated_data[
                    "latitude"
                ],
                longitude=serializer.validated_data[
                    "longitude"
                ],
                altitude=serializer.validated_data.get(
                    "altitude"
                ),
                accuracy=serializer.validated_data.get(
                    "accuracy"
                ),
                speed_kmh=serializer.validated_data.get(
                    "speed_kmh"
                ),
                heading=serializer.validated_data.get(
                    "heading"
                ),
                battery_level=serializer.validated_data.get(
                    "battery_level"
                ),
                source=serializer.validated_data.get(
                    "source",
                    "GPS",
                ),
                recorded_at=serializer.validated_data.get(
                    "recorded_at"
                ),
            )
        )

        return success_response(
            "Vehicle location recorded.",
            VehicleLocationSerializer(
                location
            ).data,
            status.HTTP_201_CREATED,
        )


class VehicleLocationHistoryView(
    generics.ListAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = VehicleLocationSerializer

    def get_queryset(self):
        vehicle_id = self.kwargs["vehicle_id"]

        return VehicleLocation.objects.filter(
            vehicle__id=vehicle_id,
            vehicle__owner=self.request.user,
        ).order_by("-recorded_at")


class VehicleLatestLocationView(
    generics.GenericAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request, vehicle_id):
        try:
            vehicle = Vehicle.objects.get(
                id=vehicle_id,
                owner=request.user,
            )
        except Vehicle.DoesNotExist:
            return error_response(
                "Vehicle not found.",
                status_code=404,
            )

        location = (
            TrackingService.get_latest_vehicle_location(
                vehicle
            )
        )

        if not location:
            return success_response(
                "No vehicle location available.",
                None,
            )

        return success_response(
            "Latest vehicle location.",
            VehicleLocationSerializer(
                location
            ).data,
        )


class MechanicLocationCreateView(
    generics.CreateAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = MechanicLocationSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )

        location = (
            TrackingService.record_mechanic_location(
                mechanic=request.user,
                latitude=serializer.validated_data[
                    "latitude"
                ],
                longitude=serializer.validated_data[
                    "longitude"
                ],
                altitude=serializer.validated_data.get(
                    "altitude"
                ),
                accuracy=serializer.validated_data.get(
                    "accuracy"
                ),
                speed_kmh=serializer.validated_data.get(
                    "speed_kmh"
                ),
                heading=serializer.validated_data.get(
                    "heading"
                ),
                is_online=serializer.validated_data.get(
                    "is_online",
                    True,
                ),
                recorded_at=serializer.validated_data.get(
                    "recorded_at"
                ),
            )
        )

        return success_response(
            "Mechanic location recorded.",
            MechanicLocationSerializer(
                location
            ).data,
            status.HTTP_201_CREATED,
        )


class MyLatestMechanicLocationView(
    generics.GenericAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request):
        location = (
            TrackingService.get_latest_mechanic_location(
                request.user
            )
        )

        if not location:
            return success_response(
                "No mechanic location available.",
                None,
            )

        return success_response(
            "Latest mechanic location.",
            MechanicLocationSerializer(
                location
            ).data,
        )


class MechanicLocationHistoryView(
    generics.ListAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = MechanicLocationSerializer

    def get_queryset(self):
        return MechanicLocation.objects.filter(
            mechanic=self.request.user
        ).order_by("-recorded_at")


class GeofenceListCreateView(
    generics.ListCreateAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = GeofenceSerializer

    def get_queryset(self):
        return Geofence.objects.filter(
            user=self.request.user
        )

    def perform_create(self, serializer):
        vehicle = serializer.validated_data.get(
            "vehicle"
        )

        if vehicle and vehicle.owner != self.request.user:
            from rest_framework.exceptions import (
                PermissionDenied,
            )

            raise PermissionDenied(
                "You do not own this vehicle."
            )

        serializer.save(
            user=self.request.user
        )


class GeofenceDetailView(
    generics.RetrieveUpdateDestroyAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = GeofenceSerializer

    def get_queryset(self):
        return Geofence.objects.filter(
            user=self.request.user
        )


class GeofenceEventListView(
    generics.ListAPIView
):
    permission_classes = [
        IsAuthenticated
    ]

    serializer_class = GeofenceEventSerializer

    def get_queryset(self):
        return GeofenceEvent.objects.filter(
            geofence__user=self.request.user
        ).order_by("-occurred_at")