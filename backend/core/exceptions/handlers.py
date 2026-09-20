from django.core.exceptions import ValidationError as DjangoValidationError

from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    NotAuthenticated,
    PermissionDenied,
    ValidationError,
)
from rest_framework.response import Response
from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(
        exc,
        context,
    )

    if response is None:
        return Response(
            {
                "success": False,
                "message": "An unexpected server error occurred.",
                "data": None,
                "errors": {
                    "detail": str(exc),
                },
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    if isinstance(exc, ValidationError):
        message = "Validation failed."

    elif isinstance(
        exc,
        (
            AuthenticationFailed,
            NotAuthenticated,
        ),
    ):
        message = "Authentication failed."

    elif isinstance(
        exc,
        PermissionDenied,
    ):
        message = "Permission denied."

    elif isinstance(
        exc,
        APIException,
    ):
        message = exc.default_detail

    elif isinstance(
        exc,
        DjangoValidationError,
    ):
        message = "Validation failed."

    else:
        message = "Request failed."

    errors = response.data

    response.data = {
        "success": False,
        "message": str(message),
        "data": None,
        "errors": errors,
    }

    return response

    from django.core.exceptions import (
    PermissionDenied,
    ValidationError as DjangoValidationError,
)

from rest_framework import status
from rest_framework.exceptions import (
    APIException,
    AuthenticationFailed,
    NotAuthenticated,
    NotFound,
    PermissionDenied as DRFPermissionDenied,
    ValidationError,
)

from rest_framework.response import Response

from rest_framework.views import (
    exception_handler as drf_exception_handler,
)


def _normalize_errors(detail):
    """
    Convert DRF/Django validation details into
    JSON-friendly error structures.
    """

    if isinstance(detail, dict):
        return {
            str(key): _normalize_errors(value)
            for key, value in detail.items()
        }

    if isinstance(detail, list):
        return [
            _normalize_errors(item)
            for item in detail
        ]

    if isinstance(detail, tuple):
        return [
            _normalize_errors(item)
            for item in detail
        ]

    if hasattr(detail, "detail"):
        return _normalize_errors(
            detail.detail
        )

    return str(detail)


def _get_exception_message(exception):
    if isinstance(
        exception,
        AuthenticationFailed,
    ):
        return "Authentication failed."

    if isinstance(
        exception,
        NotAuthenticated,
    ):
        return "Authentication credentials were not provided."

    if isinstance(
        exception,
        (
            PermissionDenied,
            DRFPermissionDenied,
        ),
    ):
        return "You do not have permission to perform this action."

    if isinstance(
        exception,
        NotFound,
    ):
        return "The requested resource was not found."

    if isinstance(
        exception,
        ValidationError,
    ):
        return "Validation failed."

    if isinstance(
        exception,
        DjangoValidationError,
    ):
        return "Validation failed."

    if isinstance(
        exception,
        APIException,
    ):
        return str(
            getattr(
                exception,
                "default_detail",
                "Request failed.",
            )
        )

    return "An unexpected error occurred."


def custom_exception_handler(
    exc,
    context,
):
    response = drf_exception_handler(
        exc,
        context,
    )

    if response is not None:
        message = _get_exception_message(
            exc
        )

        errors = _normalize_errors(
            response.data
        )

        if isinstance(errors, list):
            errors = {
                "detail": errors
            }

        response.data = {
            "success": False,
            "message": message,
            "data": None,
            "errors": errors,
        }

        return response

    if isinstance(
        exc,
        DjangoValidationError,
    ):
        if hasattr(
            exc,
            "message_dict",
        ):
            errors = exc.message_dict

        else:
            errors = {
                "detail": exc.messages
            }

        return Response(
            {
                "success": False,
                "message": (
                    "Validation failed."
                ),
                "data": None,
                "errors": errors,
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    # === TEMPORARY DEBUG — ondoa baada ya kumaliza ===
    import traceback
    import os
    debug_enabled = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    if debug_enabled:
        return Response(
            {
                "success": False,
                "message": "An unexpected error occurred.",
                "data": None,
                "errors": {
                    "detail": str(exc),
                    "type": type(exc).__name__,
                    "traceback": traceback.format_exc().split('\n'),
                },
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
    
    return Response(
        {
            "success": False,
            "message": (
                "An unexpected error occurred."
            ),
            "data": None,
            "errors": {
                "detail": (
                    "Internal server error."
                )
            },
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )