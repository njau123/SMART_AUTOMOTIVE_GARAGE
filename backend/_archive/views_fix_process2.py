
    @action(detail=True, methods=['post'])
    def process(self, request, pk=None):
        session = self.get_object()
        responses = request.data.get('responses', {})
        live_data = request.data.get('live_data', {})

        raw_dtc = responses.get('raw_dtc_response', '')
        dtc_created = False
        error_messages = []

        if raw_dtc:
            try:
                dtc, created = DTCCode.objects.get_or_create(
                    code='P0300',
                    defaults={
                        'title': 'Random/Multiple Cylinder Misfire',
                        'description': 'Random/Multiple Cylinder Misfire Detected',
                        'possible_causes': 'Faulty spark plugs, ignition coils, fuel injectors',
                        'symptoms': 'Check engine light, rough idle, misfire',
                        'severity': 'MEDIUM',
                        'system': 'ENGINE',
                        'is_common': True,
                        'is_active': True,
                    }
                )
                dtc_created = True
            except Exception as e:
                error_messages.append(f"DTCCode error: {str(e)}")

            if dtc_created:
                try:
                    DiagnosisDTC.objects.create(
                        session=session,
                        dtc=dtc,
                        raw_code=raw_dtc,
                        status='ACTIVE',
                        detected_at=now()
                    )
                except Exception as e:
                    error_messages.append(f"DiagnosisDTC error: {str(e)}")

        for pid, value in live_data.items():
            if value is not None:
                try:
                    OBDReading.objects.create(
                        session=session,
                        pid=pid,
                        value=float(value),
                        unit=''
                    )
                except Exception as e:
                    error_messages.append(f"OBDReading error: {str(e)}")

        if error_messages:
            return Response(
                {"success": False, "message": "Errors occurred", "errors": error_messages},
                status=500
            )

        session.status = 'COMPLETED_WITH_DTC' if dtc_created else 'COMPLETED'
        session.completed_at = now()
        session.save()

        return Response({
            'session': DiagnosisSessionSerializer(session).data,
            'dtcs': DiagnosisDTCSerializer(DiagnosisDTC.objects.filter(session=session), many=True).data,
            'readings': OBDReadingSerializer(OBDReading.objects.filter(session=session), many=True).data
        })
