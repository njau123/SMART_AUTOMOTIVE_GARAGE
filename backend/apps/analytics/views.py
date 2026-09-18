from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AnalyticsEventType
from .serializers import AnalyticsEventSerializer
from .services import AnalyticsService


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


class AnalyticsEventCreateView(APIView):
    permission_classes = [
        IsAuthenticated
    ]

    def post(self, request):
        serializer = AnalyticsEventSerializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )

        event = AnalyticsService.record_event(
            event_type=serializer.validated_data[
                "event_type"
            ],
            user=request.user,
            session_id=serializer.validated_data.get(
                "session_id",
                "",
            ),
            ip_address=request.META.get(
                "REMOTE_ADDR"
            ),
            platform=serializer.validated_data.get(
                "platform",
                "",
            ),
            app_version=serializer.validated_data.get(
                "app_version",
                "",
            ),
            device=serializer.validated_data.get(
                "device",
                "",
            ),
            metadata=serializer.validated_data.get(
                "metadata",
                {},
            ),
        )

        return success_response(
            "Analytics event recorded successfully.",
            AnalyticsEventSerializer(
                event
            ).data,
            status.HTTP_201_CREATED,
        )


class AnalyticsOverviewView(APIView):
    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request):
        if getattr(
            request.user,
            "role",
            None,
        ) not in {
            "ADMIN",
            "SUPER_ADMIN",
        }:
            return error_response(
                "Analytics access denied.",
                status_code=403,
            )

        try:
            days = int(
                request.query_params.get(
                    "days",
                    30,
                )
            )
        except ValueError:
            days = 30

        days = max(
            1,
            min(days, 365),
        )

        return success_response(
            "Analytics overview retrieved successfully.",
            AnalyticsService.overview(
                days=days
            ),
        )


class UserAnalyticsView(APIView):
    permission_classes = [
        IsAuthenticated
    ]

    def get(self, request):
        try:
            days = int(
                request.query_params.get(
                    "days",
                    30,
                )
            )
        except ValueError:
            days = 30

        days = max(
            1,
            min(days, 365),
        )

        return success_response(
            "User analytics retrieved successfully.",
            AnalyticsService.user_activity(
                request.user,
                days=days,
            ),
        )