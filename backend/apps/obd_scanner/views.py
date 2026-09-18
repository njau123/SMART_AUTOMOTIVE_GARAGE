from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import OBDScan
from .serializers import (
    CreateOBDScanSerializer,
    OBDScanSerializer,
)


class OBDScanCreateView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = CreateOBDScanSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)

        scan = serializer.save(
            user=request.user,
            status=OBDScan.Status.PENDING,
        )

        return Response(
            OBDScanSerializer(scan).data,
            status=status.HTTP_201_CREATED,
        )


class OBDScanStartView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        scan = OBDScan.objects.filter(
            pk=pk,
            user=request.user,
        ).first()

        if not scan:
            return Response(
                {"detail": "OBD scan not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if scan.status not in [
            OBDScan.Status.PENDING,
            OBDScan.Status.CONNECTING,
        ]:
            return Response(
                {"detail": "This scan cannot be started."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        scan.status = OBDScan.Status.SCANNING
        scan.save(update_fields=["status", "updated_at"])

        return Response(
            OBDScanSerializer(scan).data
        )


class OBDScanUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def patch(self, request, pk):
        scan = OBDScan.objects.filter(
            pk=pk,
            user=request.user,
        ).first()

        if not scan:
            return Response(
                {"detail": "OBD scan not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if "dtc_codes" in request.data:
            if not isinstance(request.data["dtc_codes"], list):
                return Response(
                    {"detail": "dtc_codes must be a list."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            scan.dtc_codes = request.data["dtc_codes"]

        if "live_data" in request.data:
            if not isinstance(request.data["live_data"], dict):
                return Response(
                    {"detail": "live_data must be an object."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            scan.live_data = request.data["live_data"]

        if "summary" in request.data:
            scan.summary = str(request.data["summary"])

        if request.data.get("complete") is True:
            scan.status = OBDScan.Status.COMPLETED
            scan.completed_at = timezone.now()

        scan.save(
            update_fields=[
                "dtc_codes",
                "live_data",
                "summary",
                "status",
                "completed_at",
                "updated_at",
            ]
        )

        return Response(
            OBDScanSerializer(scan).data
        )


class OBDScanHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        scans = (
            OBDScan.objects
            .filter(user=request.user)
            .select_related("vehicle")
        )
        return Response(
            OBDScanSerializer(scans, many=True).data
        )


class OBDScanDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        scan = (
            OBDScan.objects
            .filter(
                pk=pk,
                user=request.user,
            )
            .select_related("vehicle")
            .first()
        )

        if not scan:
            return Response(
                {"detail": "OBD scan not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            OBDScanSerializer(scan).data
        )
