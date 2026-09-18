import math
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from .models import (
    Geofence,
    GeofenceEvent,
    GeofenceEventType,
    LocationSource,
    MechanicLocation,
    TrackingSession,
    TrackingSessionStatus,
    VehicleLocation,
)


class TrackingService:

    @staticmethod
    def calculate_distance_km(
        latitude1,
        longitude1,
        latitude2,
        longitude2,
    ):
        """
        Haversine distance calculation.
        Returns distance in kilometers.
        """

        lat1 = math.radians(float(latitude1))
        lon1 = math.radians(float(longitude1))
        lat2 = math.radians(float(latitude2))
        lon2 = math.radians(float(longitude2))

        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(lat1)
            * math.cos(lat2)
            * math.sin(dlon / 2) ** 2
        )

        c = 2 * math.atan2(
            math.sqrt(a),
            math.sqrt(1 - a),
        )

        earth_radius_km = 6371.0

        return earth_radius_km * c

    @staticmethod
    @transaction.atomic
    def start_session(
        *,
        user,
        vehicle=None,
        tracking_type="VEHICLE",
        metadata=None,
    ):
        active_session = (
            TrackingSession.objects.filter(
                user=user,
                status=TrackingSessionStatus.ACTIVE,
            ).first()
        )

        if active_session:
            return active_session

        return TrackingSession.objects.create(
            user=user,
            vehicle=vehicle,
            tracking_type=tracking_type,
            status=TrackingSessionStatus.ACTIVE,
            metadata=metadata or {},
        )

    @staticmethod
    @transaction.atomic
    def pause_session(session):
        session.status = (
            TrackingSessionStatus.PAUSED
        )

        session.save(
            update_fields=[
                "status",
                "updated_at",
            ]
        )

        return session

    @staticmethod
    @transaction.atomic
    def resume_session(session):
        session.status = (
            TrackingSessionStatus.ACTIVE
        )

        session.save(
            update_fields=[
                "status",
                "updated_at",
            ]
        )

        return session

    @staticmethod
    @transaction.atomic
    def stop_session(session):
        session.status = (
            TrackingSessionStatus.COMPLETED
        )

        session.ended_at = timezone.now()

        session.save(
            update_fields=[
                "status",
                "ended_at",
                "updated_at",
            ]
        )

        return session

    @staticmethod
    @transaction.atomic
    def record_vehicle_location(
        *,
        session,
        vehicle,
        latitude,
        longitude,
        altitude=None,
        accuracy=None,
        speed_kmh=None,
        heading=None,
        battery_level=None,
        source=LocationSource.GPS,
        recorded_at=None,
    ):
        recorded_at = (
            recorded_at or timezone.now()
        )

        previous_location = (
            VehicleLocation.objects.filter(
                vehicle=vehicle
            )
            .order_by("-recorded_at")
            .first()
        )

        distance = 0.0

        if previous_location:
            distance = (
                TrackingService.calculate_distance_km(
                    previous_location.latitude,
                    previous_location.longitude,
                    latitude,
                    longitude,
                )
            )

        location = VehicleLocation.objects.create(
            session=session,
            vehicle=vehicle,
            latitude=latitude,
            longitude=longitude,
            altitude=altitude,
            accuracy=accuracy,
            speed_kmh=speed_kmh,
            heading=heading,
            battery_level=battery_level,
            source=source,
            recorded_at=recorded_at,
        )

        session.last_location_at = recorded_at

        session.total_distance_km = (
            Decimal(str(
                float(
                    session.total_distance_km
                )
                + distance
            ))
        )

        session.save(
            update_fields=[
                "last_location_at",
                "total_distance_km",
                "updated_at",
            ]
        )

        TrackingService.check_geofences(
            vehicle=vehicle,
            latitude=latitude,
            longitude=longitude,
            recorded_at=recorded_at,
        )

        return location

    @staticmethod
    @transaction.atomic
    def record_mechanic_location(
        *,
        mechanic,
        latitude,
        longitude,
        altitude=None,
        accuracy=None,
        speed_kmh=None,
        heading=None,
        is_online=True,
        recorded_at=None,
    ):
        return MechanicLocation.objects.create(
            mechanic=mechanic,
            latitude=latitude,
            longitude=longitude,
            altitude=altitude,
            accuracy=accuracy,
            speed_kmh=speed_kmh,
            heading=heading,
            is_online=is_online,
            recorded_at=(
                recorded_at
                or timezone.now()
            ),
        )

    @staticmethod
    def get_latest_vehicle_location(
        vehicle
    ):
        return (
            VehicleLocation.objects.filter(
                vehicle=vehicle
            )
            .order_by("-recorded_at")
            .first()
        )

    @staticmethod
    def get_latest_mechanic_location(
        mechanic
    ):
        return (
            MechanicLocation.objects.filter(
                mechanic=mechanic
            )
            .order_by("-recorded_at")
            .first()
        )

    @staticmethod
    def is_inside_geofence(
        *,
        geofence,
        latitude,
        longitude,
    ):
        distance_km = (
            TrackingService.calculate_distance_km(
                geofence.latitude,
                geofence.longitude,
                latitude,
                longitude,
            )
        )

        radius_km = (
            geofence.radius_meters / 1000
        )

        return distance_km <= radius_km

    @staticmethod
    def check_geofences(
        *,
        vehicle,
        latitude,
        longitude,
        recorded_at,
    ):
        geofences = Geofence.objects.filter(
            vehicle=vehicle,
            is_active=True,
        )

        events = []

        for geofence in geofences:
            inside = (
                TrackingService.is_inside_geofence(
                    geofence=geofence,
                    latitude=latitude,
                    longitude=longitude,
                )
            )

            previous_event = (
                GeofenceEvent.objects.filter(
                    geofence=geofence,
                    vehicle=vehicle,
                )
                .order_by("-occurred_at")
                .first()
            )

            if inside:
                should_create = (
                    previous_event is None
                    or previous_event.event_type
                    == GeofenceEventType.EXIT
                )

                if (
                    should_create
                    and geofence.notify_on_enter
                ):
                    events.append(
                        GeofenceEvent.objects.create(
                            geofence=geofence,
                            vehicle=vehicle,
                            event_type=(
                                GeofenceEventType.ENTER
                            ),
                            latitude=latitude,
                            longitude=longitude,
                            occurred_at=recorded_at,
                        )
                    )

            else:
                should_create = (
                    previous_event is not None
                    and previous_event.event_type
                    == GeofenceEventType.ENTER
                )

                if (
                    should_create
                    and geofence.notify_on_exit
                ):
                    events.append(
                        GeofenceEvent.objects.create(
                            geofence=geofence,
                            vehicle=vehicle,
                            event_type=(
                                GeofenceEventType.EXIT
                            ),
                            latitude=latitude,
                            longitude=longitude,
                            occurred_at=recorded_at,
                        )
                    )

        return events