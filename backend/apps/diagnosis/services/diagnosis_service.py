"""
Diagnosis Service
Core business logic for diagnostic operations
"""

import uuid
from datetime import datetime
from django.utils import timezone
from django.db import transaction
from ..models import (
    DiagnosisSession,
    DTCCode,
    DiagnosisDTC,
    OBDReading,
    DiagnosisObservation,
)


class DiagnosisService:
    """Service for managing diagnosis operations"""

    @staticmethod
    def create_session(user, vehicle, data):
        """Create a new diagnosis session"""
        session = DiagnosisSession.objects.create(
            user=user,
            vehicle=vehicle,
            connection_type=data.get('connection_type', DiagnosisSession.ConnectionType.OBDII),
            adapter_name=data.get('adapter_name', ''),
            adapter_address=data.get('adapter_address', ''),
            protocol=data.get('protocol', ''),
            odometer_at_start=data.get('odometer_at_start'),
            status=DiagnosisSession.Status.CREATED,
        )
        return session

    @staticmethod
    def start_session(session):
        """Start a diagnosis session"""
        if session.status != DiagnosisSession.Status.CREATED:
            raise ValueError(f"Cannot start session with status: {session.status}")

        session.status = DiagnosisSession.Status.CONNECTING
        session.started_at = timezone.now()
        session.save()
        return session

    @staticmethod
    def connect_session(session):
        """Connect to OBD adapter"""
        if session.status != DiagnosisSession.Status.CONNECTING:
            raise ValueError(f"Cannot connect with status: {session.status}")

        session.status = DiagnosisSession.Status.CONNECTED
        session.save()
        return session

    @staticmethod
    def scan_session(session):
        """Start scanning"""
        if session.status != DiagnosisSession.Status.CONNECTED:
            raise ValueError(f"Cannot scan with status: {session.status}")

        session.status = DiagnosisSession.Status.SCANNING
        session.save()
        return session

    @staticmethod
    def complete_session(session, summary=None, recommendation=None):
        """Complete a diagnosis session"""
        if session.status not in [
            DiagnosisSession.Status.SCANNING,
            DiagnosisSession.Status.CONNECTED,
        ]:
            raise ValueError(f"Cannot complete with status: {session.status}")

        session.status = DiagnosisSession.Status.COMPLETED
        session.completed_at = timezone.now()
        if summary:
            session.summary = summary
        if recommendation:
            session.recommendation = recommendation
        session.save()
        return session

    @staticmethod
    def add_dtc(session, raw_code, dtc_code=None, status='ACTIVE', notes=None):
        """Add a DTC to a diagnosis session using the current DiagnosisDTC schema."""
        dtc = None

        if dtc_code:
            dtc = DTCCode.objects.filter(code=dtc_code).first()

        existing = DiagnosisDTC.objects.filter(
            session=session,
            raw_code=raw_code,
        ).first()

        if existing:
            if dtc is not None and existing.dtc_code_id != dtc.id:
                existing.dtc_code = dtc
                existing.save(update_fields=["dtc_code"])
            return existing

        return DiagnosisDTC.objects.create(
            session=session,
            dtc_code=dtc,
            raw_code=raw_code,
            status=status.upper(),
        )

    @staticmethod
    def add_reading(session, pid, name, value, unit='', raw_response=''):
        """Add an OBD reading to a diagnosis session"""
        return OBDReading.objects.create(
            session=session,
            pid=pid,
            name=name,
            value=value,
            unit=unit,
            raw_response=raw_response,
        )

    @staticmethod
    def add_observation(session, title, message, severity='info', source='system', confidence=100):
        """Add an observation to a diagnosis session"""
        return DiagnosisObservation.objects.create(
            session=session,
            title=title,
            message=message,
            severity=severity,
            source=source,
            confidence=confidence,
        )

    @staticmethod
    def get_session_summary(session):
        """Generate summary of diagnosis session"""
        dtc_count = session.dtcs.count()
        reading_count = session.obd_readings.count()
        observation_count = session.observations.count()

        # Get critical observations
        critical = session.observations.filter(severity='critical')
        high = session.observations.filter(severity='high')

        summary = {
            'id': str(session.id),
            'status': session.status,
            'dtc_count': dtc_count,
            'reading_count': reading_count,
            'observation_count': observation_count,
            'critical_observations': critical.count(),
            'high_observations': high.count(),
            'duration': None,
        }

        if session.started_at and session.completed_at:
            delta = session.completed_at - session.started_at
            summary['duration'] = delta.total_seconds()

        return summary
