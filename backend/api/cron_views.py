"""
Cron endpoints — external cron inaita hizi.
"""
import os
from django.core.management import call_command
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET


@csrf_exempt
@require_GET
def expire_payments_cron(request):
    """Expire payments zilizopitwa na muda — requires secret token."""
    secret = request.GET.get('secret', '')
    expected = os.environ.get('CRON_SECRET', '')

    if not expected or secret != expected:
        return JsonResponse(
            {'success': False, 'message': 'Unauthorized'},
            status=401,
        )

    try:
        call_command('expire_payments')
        return JsonResponse({'success': True, 'message': 'Expired payments checked'})
    except Exception as e:
        return JsonResponse(
            {'success': False, 'message': str(e)},
            status=500,
        )
