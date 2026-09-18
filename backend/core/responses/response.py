from rest_framework.response import Response
from rest_framework import status


def success_response(data=None, message="Success", status_code=status.HTTP_200_OK):
    return Response(
        {
            "success": True,
            "message": message,
            "data": data,
            "errors": None,
            "status": status_code,
        },
        status=status_code,
    )


def error_response(message="Error", errors=None, status_code=status.HTTP_400_BAD_REQUEST):
    return Response(
        {
            "success": False,
            "message": message,
            "data": None,
            "errors": errors,
            "status": status_code,
        },
        status=status_code,
    )


def created_response(data=None, message="Created successfully"):
    return success_response(data, message, status.HTTP_201_CREATED)


def bad_request_response(message="Bad request", errors=None):
    return error_response(message, errors, status.HTTP_400_BAD_REQUEST)


def unauthorized_response(message="Authentication required"):
    return error_response(message, status_code=status.HTTP_401_UNAUTHORIZED)


def forbidden_response(message="Permission denied"):
    return error_response(message, status_code=status.HTTP_403_FORBIDDEN)


def not_found_response(message="Resource not found"):
    return error_response(message, status_code=status.HTTP_404_NOT_FOUND)


def validation_error_response(errors, message="Validation failed"):
    return error_response(message, errors, status.HTTP_422_UNPROCESSABLE_ENTITY)


def server_error_response(message="Internal server error"):
    return error_response(message, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
