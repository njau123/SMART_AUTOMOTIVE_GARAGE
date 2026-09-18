from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DiagnosisSession
from .serializers import (
    CreateDiagnosisSerializer,
    DiagnosisSessionSerializer,
)


def generate_preliminary_diagnosis(vehicle, symptoms, description):
    text = f"{description} {' '.join(symptoms)}".lower()

    causes = []
    actions = []
    severity = "LOW"

    if any(x in text for x in ["zima", "stalls", "stalling", "uzima", "engine"]):
        causes.extend([
            "Fuel delivery problem",
            "Ignition system problem",
            "Air intake problem",
            "Engine timing or sensor problem",
        ])
        actions.extend([
            "Check fuel supply and fuel filter.",
            "Check spark plugs and ignition coils.",
            "Check the air intake system.",
            "Perform an OBD-II scan.",
        ])
        severity = "MEDIUM"

    if any(x in text for x in ["smoke", "overheat", "overheating", "temperature", "oil pressure"]):
        severity = "HIGH"
        actions.append(
            "Stop driving if the condition is severe and arrange professional inspection."
        )

    if any(x in text for x in ["brake", "brakes", "breki"]):
        severity = "HIGH"
        causes.append("Possible brake system fault.")
        actions.append(
            "Avoid driving until the braking system has been inspected."
        )

    if not causes:
        causes = [
            "Several mechanical or electrical causes may produce these symptoms.",
            "A physical inspection may be required.",
        ]

    if not actions:
        actions = [
            "Provide additional symptoms.",
            "Run an OBD-II scan.",
            "Book a qualified mechanic.",
        ]

    summary = (
        f"Preliminary assessment for {vehicle.make} {vehicle.model}. "
        "The reported symptoms require further inspection."
    )

    return {
        "summary": summary,
        "causes": causes,
        "actions": actions,
        "severity": severity,
    }


class DiagnosisCreateView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = CreateDiagnosisSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)

        session = serializer.save(
            user=request.user,
            source=DiagnosisSession.Source.AI,
            status=DiagnosisSession.Status.PROCESSING,
        )

        result = generate_preliminary_diagnosis(
            session.vehicle,
            session.symptoms,
            session.user_description,
        )

        session.ai_summary = result["summary"]
        session.possible_causes = result["causes"]
        session.recommended_actions = result["actions"]
        session.severity = result["severity"]
        session.raw_response = result
        session.status = DiagnosisSession.Status.COMPLETED
        session.save()

        return Response(
            DiagnosisSessionSerializer(session).data,
            status=status.HTTP_201_CREATED,
        )


class DiagnosisHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sessions = (
            DiagnosisSession.objects
            .filter(user=request.user)
            .select_related("vehicle")
        )
        return Response(
            DiagnosisSessionSerializer(
                sessions,
                many=True,
            ).data
        )


class DiagnosisDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        session = (
            DiagnosisSession.objects
            .filter(
                pk=pk,
                user=request.user,
            )
            .select_related("vehicle")
            .first()
        )

        if not session:
            return Response(
                {"detail": "Diagnosis session not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            DiagnosisSessionSerializer(session).data
        )
