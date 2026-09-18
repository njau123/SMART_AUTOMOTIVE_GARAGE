from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import (
    EmailVerificationCode,
    PasswordResetCode,
    User,
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ["-created_at"]

    list_display = [
        "email",
        "first_name",
        "last_name",
        "phone_number",
        "role",
        "is_email_verified",
        "is_active",
        "created_at",
    ]

    list_filter = [
        "role",
        "is_active",
        "is_email_verified",
        "is_phone_verified",
        "is_staff",
    ]

    search_fields = [
        "email",
        "first_name",
        "middle_name",
        "last_name",
        "phone_number",
    ]

    readonly_fields = [
        "created_at",
        "updated_at",
        "last_login",
    ]

    fieldsets = (
        (
            "Login Information",
            {
                "fields": (
                    "email",
                    "password",
                )
            },
        ),
        (
            "Personal Information",
            {
                "fields": (
                    "first_name",
                    "middle_name",
                    "last_name",
                    "phone_number",
                    "profile_image",
                )
            },
        ),
        (
            "Role & Permissions",
            {
                "fields": (
                    "role",
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        (
            "Verification",
            {
                "fields": (
                    "is_email_verified",
                    "is_phone_verified",
                    "firebase_uid",
                )
            },
        ),
        (
            "Security",
            {
                "fields": (
                    "last_login",
                    "last_login_ip",
                    "last_activity",
                )
            },
        ),
        (
            "Dates",
            {
                "fields": (
                    "created_at",
                    "updated_at",
                )
            },
        ),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": (
                    "wide",
                ),
                "fields": (
                    "email",
                    "first_name",
                    "last_name",
                    "phone_number",
                    "password1",
                    "password2",
                    "role",
                    "is_staff",
                    "is_active",
                ),
            },
        ),
    )


@admin.register(EmailVerificationCode)
class EmailVerificationCodeAdmin(admin.ModelAdmin):
    list_display = [
        "user",
        "code",
        "expires_at",
        "is_used",
        "attempts",
        "created_at",
    ]

    list_filter = [
        "is_used",
        "created_at",
    ]

    search_fields = [
        "user__email",
        "user__phone_number",
    ]

    readonly_fields = [
        "created_at",
    ]


@admin.register(PasswordResetCode)
class PasswordResetCodeAdmin(admin.ModelAdmin):
    list_display = [
        "user",
        "code",
        "expires_at",
        "is_used",
        "attempts",
        "created_at",
    ]

    list_filter = [
        "is_used",
        "created_at",
    ]

    search_fields = [
        "user__email",
        "user__phone_number",
    ]

    readonly_fields = [
        "created_at",
    ]