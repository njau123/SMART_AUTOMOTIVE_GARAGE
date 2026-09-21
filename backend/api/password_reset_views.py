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
    """Tuma email kwa SendGrid API (HTTP). Inafanya kazi Render Free."""
    api_key = os.environ.get('SENDGRID_API_KEY', '')
    from_email = os.environ.get('SENDGRID_FROM_EMAIL', 'njaufredrick0@gmail.com')

    if not api_key:
        raise Exception('SENDGRID_API_KEY haipo')

    try:
        from sendgrid import SendGridAPIClient
        from sendgrid.helpers.mail import Mail

        sg_message = Mail(
            from_email=from_email,
            to_emails=to_email,
            subject=subject,
            plain_text_content=message,
        )
        sg = SendGridAPIClient(api_key)
        response = sg.send(sg_message)
        return True, response.status_code
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
            # Security: don't reveal kama email haipo
            return Response({
                'success': True,
                'message': 'If this email is registered, you will receive a reset code.',
            })

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

        email_sent = False
        email_error = None
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@smartautomotivegarage.com'),
                recipient_list=[email],
                fail_silently=False,
            )
            email_sent = True
        except Exception as e:
            email_error = str(e)
            # Fallback: print to console for development
            print(f"\n{'='*50}")
            print(f"EMAIL FAILED: {email_error}")
            print(f"Password reset code for {email}: {code}")
            print(f"{'='*50}\n")

        return Response({
            'success': True,
            'message': 'Reset code sent. Check your email inbox.',
            'email_sent': email_sent,
            'expires_in_minutes': 10,
            # Remove in production:
            **({'debug_code': code} if not email_sent else {}),
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
