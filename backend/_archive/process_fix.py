    @action(detail=True, methods=['post'])
    def process(self, request, pk=None):
        session = self.get_object()
        responses = request.data.get('responses', {})
        live_data = request.data.get('live_data', {})

        try:
            # Save DTCs from raw response
            raw_dtc = responses.get('raw_dtc_response', '')
            dtc_codes = []

            if raw_dtc:
                # Simple DTC decoding example
                # '430300' -> P0300
                if len(raw_dtc) >= 6:
                    # Extract the DTC code
                    dtc_hex = raw_dtc[2:6]  # '0300'
                    if dtc_hex:
                        # Convert to P-code (simplified)
                        dtc_code = f"P{dtc_hex[1:]}"  # 'P300' -> P0300
                        if len(dtc_code) == 4:
                            dtc_code = f"P0{dtc_code[1:]}"  # P300 -> P0300
                        dtc, created = DTCCode.objects.get_or_create(
                            code=dtc_code,
                            defaults={
                                'description': f'DTC {dtc_code} detected',
                                'possible_causes': 'Check engine, fuel system, or ignition system',
                                'solutions': 'Diagnose with OBD scanner'
                            }
                        )
                        DiagnosisDTC.objects.create(
                            session=session,
                            dtc_code=dtc,
                            status='ACTIVE'
                        )
                        dtc_codes.append(dtc)

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
                        print(f"Error saving {pid}: {e}")

            # Update session
            session.dtc_count = len(dtc_codes)
            session.status = 'COMPLETED_WITH_DTC' if dtc_codes else 'COMPLETED'
            session.completed_at = now()
            if session.started_at:
                session.duration_seconds = (session.completed_at - session.started_at).seconds
            session.save()

            return Response({
                'session': DiagnosisSessionSerializer(session).data,
                'dtcs': DiagnosisDTCSerializer(DiagnosisDTC.objects.filter(session=session), many=True).data,
                'readings': OBDReadingSerializer(OBDReading.objects.filter(session=session), many=True).data
            })

        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({
                'success': False,
                'message': 'An unexpected error occurred.',
                'data': None,
                'errors': {'detail': str(e)}
            }, status=500)
