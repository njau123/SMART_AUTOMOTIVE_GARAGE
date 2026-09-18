    @action(detail=True, methods=['post'])
    def process(self, request, pk=None):
        session = self.get_object()
        responses = request.data.get('responses', {})
        live_data = request.data.get('live_data', {})
        
        raw_dtc = responses.get('raw_dtc_response', '')
        dtc_created = False
        
        if raw_dtc:
            try:
                dtc, created = DTCCode.objects.get_or_create(
                    code='P0300',
                    defaults={
                        'description': 'Random/Multiple Cylinder Misfire Detected',
                        'possible_causes': 'Faulty spark plugs, ignition coils, fuel injectors',
                        'solutions': 'Replace spark plugs, check ignition coils'
                    }
                )
                dtc_created = True
                DiagnosisDTC.objects.create(
                    session=session,
                    dtc_code=dtc,
                    status='ACTIVE'
                )
            except Exception as e:
                print(f"Error saving DTC: {e}")
                return Response({"success": False, "message": f"Error saving DTC: {str(e)}"}, status=500)
        
        # Save live data
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
                    print(f"Error saving reading: {e}")
        
        session.status = 'COMPLETED_WITH_DTC' if dtc_created else 'COMPLETED'
        session.completed_at = now()
        session.save()
        
        return Response({
            'session': DiagnosisSessionSerializer(session).data,
            'dtcs': DiagnosisDTCSerializer(DiagnosisDTC.objects.filter(session=session), many=True).data,
            'readings': OBDReadingSerializer(OBDReading.objects.filter(session=session), many=True).data
        })
