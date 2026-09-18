from django.conf import settings
from django.core.checks import (
    Error,
    Warning,
    register,
)


@register()
def production_security_check(
    app_configs,
    **kwargs,
):
    errors = []

    production = (
        getattr(
            settings,
            "APP_ENV",
            "development",
        ).lower()
        == "production"
    )

    if not production:
        return errors

    # =====================================================
    # DEBUG
    # =====================================================

    if settings.DEBUG:
        errors.append(
            Error(
                "DEBUG must be False in production.",
                id="security.E001",
            )
        )

    # =====================================================
    # SECRET KEY
    # =====================================================

    secret_key = getattr(
        settings,
        "SECRET_KEY",
        "",
    )

    if not secret_key:
        errors.append(
            Error(
                "SECRET_KEY is required.",
                id="security.E002",
            )
        )

    if len(secret_key) < 50:
        errors.append(
            Error(
                "Production SECRET_KEY is too short.",
                id="security.E003",
            )
        )

    # =====================================================
    # ALLOWED HOSTS
    # =====================================================

    if not settings.ALLOWED_HOSTS:
        errors.append(
            Error(
                "ALLOWED_HOSTS must not be empty.",
                id="security.E004",
            )
        )

    if "*" in settings.ALLOWED_HOSTS:
        errors.append(
            Error(
                "ALLOWED_HOSTS must not contain '*'.",
                id="security.E005",
            )
        )

    # =====================================================
    # JWT
    # =====================================================

    jwt_key = getattr(
        settings,
        "JWT_SIGNING_KEY",
        "",
    )

    if not jwt_key:
        errors.append(
            Error(
                "JWT_SIGNING_KEY is required.",
                id="security.E006",
            )
        )

    if len(jwt_key) < 50:
        errors.append(
            Error(
                "Production JWT_SIGNING_KEY is too short.",
                id="security.E007",
            )
        )

    # =====================================================
    # HTTPS
    # =====================================================

    if not settings.SECURE_SSL_REDIRECT:
        errors.append(
            Error(
                "SECURE_SSL_REDIRECT must be True in production.",
                id="security.E008",
            )
        )

    # =====================================================
    # COOKIES
    # =====================================================

    if not settings.SESSION_COOKIE_SECURE:
        errors.append(
            Error(
                "SESSION_COOKIE_SECURE must be True.",
                id="security.E009",
            )
        )

    if not settings.CSRF_COOKIE_SECURE:
        errors.append(
            Error(
                "CSRF_COOKIE_SECURE must be True.",
                id="security.E010",
            )
        )

    # =====================================================
    # HSTS
    # =====================================================

    if settings.SECURE_HSTS_SECONDS < 31536000:
        errors.append(
            Error(
                "SECURE_HSTS_SECONDS must be at least one year.",
                id="security.E011",
            )
        )

    if not settings.SECURE_HSTS_INCLUDE_SUBDOMAINS:
        errors.append(
            Error(
                "SECURE_HSTS_INCLUDE_SUBDOMAINS must be True.",
                id="security.E012",
            )
        )

    if not settings.SECURE_HSTS_PRELOAD:
        errors.append(
            Error(
                "SECURE_HSTS_PRELOAD must be True.",
                id="security.E013",
            )
        )

    # =====================================================
    # FIREBASE
    # =====================================================

    firebase_values = [
        "FIREBASE_PROJECT_ID",
        "FIREBASE_CLIENT_EMAIL",
        "FIREBASE_PRIVATE_KEY",
        "FIREBASE_STORAGE_BUCKET",
    ]

    for setting_name in firebase_values:
        value = getattr(
            settings,
            setting_name,
            None,
        )

        if not value:
            errors.append(
                Error(
                    f"{setting_name} must be configured.",
                    id="security.E014",
                )
            )

    # =====================================================
    # CORS
    # =====================================================

    cors_origins = getattr(
        settings,
        "CORS_ALLOWED_ORIGINS",
        [],
    )

    if "*" in cors_origins:
        errors.append(
            Error(
                "CORS_ALLOWED_ORIGINS must not contain '*'.",
                id="security.E015",
            )
        )

    return errors