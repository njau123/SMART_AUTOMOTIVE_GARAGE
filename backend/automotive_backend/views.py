from django.http import JsonResponse


def home(request):
    return JsonResponse({
        "name": "Smart Automotive Garage API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "admin": "/admin/",
            "api": "/api/v1/",
        }
    })


def health(request):
    return JsonResponse({"status": "ok"})
