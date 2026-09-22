"""
Secure Google Login using Firebase Admin SDK.
Verifies Firebase ID token from Flutter client.
"""
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
import logging

User = get_user_model()
logger = logging.getLogger(__name__)


class GoogleLoginView(APIView):
    """
    Google Sign-In via Firebase ID token.

    Client (Flutter) sends Firebase ID token in 'id_token' field.
    Server verifies token with Firebase Admin SDK.
    If valid, creates/returns user + JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')

        if not id_token:
            return Response(
                {"success": False, "message": "ID token required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # Verify with Firebase Admin SDK
            from firebase_admin import auth as firebase_auth

            decoded_token = firebase_auth.verify_id_token(id_token)

            email = decoded_token.get('email')
            name = decoded_token.get('name', '')
            picture = decoded_token.get('picture', '')

            if not email:
                return Response(
                    {"success": False, "message": "Email not provided by Google"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Create or get user
            first_name = ''
            last_name = ''
            if name:
                parts = name.strip().split(' ')
                first_name = parts[0]
                last_name = ' '.join(parts[1:]) if len(parts) > 1 else ''
            else:
                # Fallback: email prefix
                first_name = email.split('@')[0]

            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'first_name': first_name,
                    'last_name': last_name,
                    'phone_number': '+255000000000',  # Placeholder (user ana-update)
                    'is_active': True,
                    'is_email_verified': True,  # Google email ni verified
                },
            )

            # Save Google picture URL kama user hana profile_image
            if picture:
                if not user.profile_image and not user.profile_image_url:
                    user.profile_image_url = picture
                    user.save(update_fields=['profile_image_url'])
                # Return picture kwenye response
            else:
                picture = None

            if not user.is_active:
                return Response(
                    {"success": False, "message": "Account is deactivated"},
                    status=status.HTTP_403_FORBIDDEN,
                )

            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            access_token = str(refresh.access_token)

            logger.info(
                "Google login successful for email=%s created=%s",
                email, created,
            )

            return Response({
                "success": True,
                "message": "Login successful",
                "access": access_token,
                "refresh": str(refresh),
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "role": getattr(user, 'role', 'USER'),
                    "picture": picture,
                },
                "created": created,
            })

        except Exception as e:
            logger.warning("Google login failed: %s", str(e))
            return Response(
                {
                    "success": False,
                    "message": "Invalid or expired ID token",
                    "detail": str(e),
                },
                status=status.HTTP_401_UNAUTHORIZED,
            )
