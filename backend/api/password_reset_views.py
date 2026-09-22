"""
Password reset flow with real email sending.
"""
import os
import random
import string
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.conf import settings
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.response import Response

from apps.accounts.models import PasswordResetCode

User = get_user_model()


def _generate_code():
    return ''.join(random.choices(string.digits, k=6))


def _send_email(to_email, subject, message):
    """Tuma email kwa Resend API (HTTP). Inafanya kazi Render Free."""
    import json
    import urllib.request
    import urllib.error

    api_key = os.environ.get('RESEND_API_KEY', '')
    from_email = os.environ.get('RESEND_FROM_EMAIL', 'onboarding@resend.dev')

    if not api_key:
        return False, 'RESEND_API_KEY haipo'

    try:
        payload = json.dumps({
            'from': from_email,
            'to': [to_email],
            'subject': subject,
            'text': message,
        }).encode('utf-8')

        req = urllib.request.Request(
            'https://api.resend.com/emails',
            data=payload,
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
                'User-Agent': 'SmartGarage/1.0 (Django)',
                'Accept': 'application/json',
            },
            method='POST',
        )

        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode('utf-8')
            return True, resp.status
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else str(e)
        return False, f'HTTP {e.code}: {error_body[:200]}'
    except Exception as e:
        return False, str(e)


class RequestPasswordResetView(generics.GenericAPIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        email = (request.data.get('email') or '').strip().lower()

        if not email:
            return Response(
                {'success': False, 'message': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({
                'success': False,
                'message': 'No account found with that email',
            }, status=status.HTTP_404_NOT_FOUND)

        # Futa codes za zamani
        PasswordResetCode.objects.filter(user=user).delete()

        # Tengeneza code mpya
        code = _generate_code()
        expires_at = timezone.now() + timedelta(minutes=10)
        reset_code = PasswordResetCode.objects.create(
            user=user,
            code=code,
            expires_at=expires_at,
        )

        # Tuma email
        subject = 'Smart Automotive Garage - Password Reset Code'
        message = f"""Hello {user.first_name},

You requested to reset your password for Smart Automotive Garage.

Your verification code is:

    {code}

This code is valid for 10 minutes.

If you did not request this, please ignore this email.

Best regards,
Smart Automotive Garage Team
"""

        email_sent, email_result = _send_email(email, subject, message)
        error_info = None
        if not email_sent:
            error_info = str(email_result)[:200]
            print(f"[EMAIL FAILED] {email_result}")
            print(f"[FALLBACK] Password reset code for {email}: {code}")

        return Response({
            'success': True,
            'message': 'Reset code sent. Check your email inbox.',
            'email_sent': email_sent,
            'error_info': error_info,
            'expires_in_minutes': 10,
        })


class VerifyResetCodeView(generics.GenericAPIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        email = (request.data.get('email') or '').strip().lower()
        code = (request.data.get('code') or '').strip()

        if not email or not code:
            return Response(
                {'success': False, 'message': 'Email and code are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email=email)
            reset_code = PasswordResetCode.objects.get(
                user=user, code=code, is_used=False
            )
        except (User.DoesNotExist, PasswordResetCode.DoesNotExist):
            return Response(
                {'success': False, 'message': 'Invalid email or code'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Angalia expiry
        if reset_code.expires_at and timezone.now() > reset_code.expires_at:
            return Response(
                {'success': False, 'message': 'Code has expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({'success': True, 'message': 'Code verified'})


class ResetPasswordView(generics.GenericAPIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        email = (request.data.get('email') or '').strip().lower()
        code = (request.data.get('code') or '').strip()
        new_password = request.data.get('new_password') or ''

        if not all([email, code, new_password]):
            return Response(
                {'success': False, 'message': 'All fields are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if len(new_password) < 6:
            return Response(
                {'success': False, 'message': 'Password must be at least 6 characters'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email=email)
            reset_code = PasswordResetCode.objects.get(
                user=user, code=code, is_used=False
            )
        except (User.DoesNotExist, PasswordResetCode.DoesNotExist):
            return Response(
                {'success': False, 'message': 'Invalid email or code'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if reset_code.expires_at and timezone.now() > reset_code.expires_at:
            return Response(
                {'success': False, 'message': 'Code has expired'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(new_password)
        user.save()

        reset_code.is_used = True
        reset_code.save()

        return Response({
            'success': True,
            'message': 'Password reset successfully. You may now login.',
        })
