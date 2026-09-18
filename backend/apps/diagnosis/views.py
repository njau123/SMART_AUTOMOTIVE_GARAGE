from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import DiagnosisSession, DTCCode, DiagnosisDTC, OBDPID, OBDReading, OBDScanEvent
from .serializers import (
    DiagnosisSessionSerializer,
    DiagnosisSessionCreateSerializer,
    DiagnosisSessionUpdateSerializer,
    DTCCodeSerializer,
    DiagnosisDTCSerializer,
    OBDPIDSerializer,
    OBDReadingSerializer,
    OBDScanEventSerializer,
)


def success_response(data=None, message="Success", status_code=200):
    """Helper for success response"""
    return Response(
        {
            "success": True,
            "message": message,
            "data": data,
            "errors": None,
        },
        status=status_code,
    )


def error_response(message="Error", errors=None, status_code=400):
    """Helper for error response"""
    return Response(
        {
            "success": False,
            "message": message,
            "data": None,
            "errors": errors,
        },
        status=status_code,
    )


class DiagnosisSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for managing diagnosis sessions"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['session_id', 'user__email', 'vehicle__registration_number']
    ordering_fields = ['created_at', 'status']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return DiagnosisSession.objects.all()
        return DiagnosisSession.objects.filter(user=user)

    def get_serializer_class(self):
        if self.action == 'create':
            return DiagnosisSessionCreateSerializer
        if self.action in ['update', 'partial_update']:
            return DiagnosisSessionUpdateSerializer
        return DiagnosisSessionSerializer

    def perform_create(self, serializer):
        serializer.save(
            user=self.request.user,
            session_id=f"DX-{timezone.now().strftime('%Y%m%d')}-{self.request.user.id}"
        )

    @action(detail=True, methods=['post'])
    def add_dtc(self, request, pk=None):
        session = self.get_object()
        raw_code = request.data.get('raw_code')
        dtc_code = request.data.get('dtc_code')
        status_val = request.data.get('status', 'ACTIVE')
        is_confirmed = request.data.get('is_confirmed', False)

        if not raw_code:
            return error_response(message="raw_code is required")

        dtc = None
        if dtc_code:
            dtc = DTCCode.objects.filter(code=dtc_code).first()

        diagnosis_dtc = DiagnosisDTC.objects.create(
            session=session,
            dtc_code=dtc,
            raw_code=raw_code,
            status=status_val,
            is_confirmed=is_confirmed
        )

        return success_response(
            data=DiagnosisDTCSerializer(diagnosis_dtc).data,
            message="DTC added successfully"
        )

    @action(detail=True, methods=['post'])
    def add_obd_reading(self, request, pk=None):
        session = self.get_object()
        pid = request.data.get('pid')
        raw_response = request.data.get('raw_response', '')
        value = request.data.get('value')
        unit = request.data.get('unit', '')
        metadata = request.data.get('metadata', {})

        if not pid:
            return error_response(message="pid is required")

        pid_obj = OBDPID.objects.filter(pid=pid).first()
        if not pid_obj:
            pid_obj = OBDPID.objects.create(
                pid=pid,
                name=request.data.get('name', f'PID {pid}'),
                unit=unit
            )

        reading = OBDReading.objects.create(
            session=session,
            pid=pid_obj,
            raw_response=raw_response,
            value=value,
            unit=unit,
            metadata=metadata
        )

        return success_response(
            data=OBDReadingSerializer(reading).data,
            message="OBD reading added"
        )

    @action(detail=True, methods=['post'])
    def add_event(self, request, pk=None):
        session = self.get_object()
        event_type = request.data.get('event_type')
        message = request.data.get('message', '')
        payload = request.data.get('payload', {})

        if not event_type:
            return error_response(message="event_type is required")

        event = OBDScanEvent.objects.create(
            session=session,
            event_type=event_type,
            message=message,
            payload=payload
        )

        return success_response(
            data=OBDScanEventSerializer(event).data,
            message="Event added"
        )

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        session = self.get_object()
        session.status = 'COMPLETED'
        session.completed_at = timezone.now()
        session.summary = request.data.get('summary', session.summary)
        session.notes = request.data.get('notes', session.notes)
        session.save()

        return success_response(
            data=DiagnosisSessionSerializer(session).data,
            message="Session completed"
        )

    @action(detail=False, methods=['get'])
    def stats(self, request):
        queryset = self.get_queryset()
        stats = {
            'total': queryset.count(),
            'created': queryset.filter(status='CREATED').count(),
            'scanning': queryset.filter(status='SCANNING').count(),
            'completed': queryset.filter(status='COMPLETED').count(),
            'failed': queryset.filter(status='FAILED').count(),
            'cancelled': queryset.filter(status='CANCELLED').count(),
        }
        return success_response(data=stats, message="Statistics retrieved")


class DTCCodeViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing DTC codes"""
    queryset = DTCCode.objects.filter(is_active=True)
    serializer_class = DTCCodeSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['code', 'title', 'system']
    ordering_fields = ['code', 'system']
    ordering = ['code']


class OBDPIDViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing OBD PIDs"""
    queryset = OBDPID.objects.all()
    serializer_class = OBDPIDSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['pid', 'name']
    ordering_fields = ['pid']
    ordering = ['pid']

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def diagnose(request):
    symptoms = request.data.get('symptoms', '').lower()
    if 'zima ghafla' in symptoms:
        return Response({
            'issue': 'Engine stalling',
            'causes': ['Fuel pump failure', 'Crankshaft sensor', 'ECU issue'],
            'solutions': ['Check fuel pressure', 'Scan for error codes', 'Replace faulty sensor']
        })
    elif 'overheat' in symptoms:
        return Response({
            'issue': 'Overheating',
            'causes': ['Coolant leak', 'Thermostat failure', 'Water pump failure'],
            'solutions': ['Refill coolant', 'Replace thermostat', 'Inspect water pump']
        })
    return Response({
        'issue': 'General issue',
        'causes': ['Unknown'],
        'solutions': ['Visit a certified mechanic']
    })
