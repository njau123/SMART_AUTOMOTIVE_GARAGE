from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

from .managers import UserManager


tanzania_phone_validator = RegexValidator(
    regex=r"^\+255[67]\d{8}$",
    message="Phone number must be in Tanzania format, e.g. +255712345678.",
)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        USER = "USER", "User"
        MECHANIC = "MECHANIC", "Mechanic"
        ADMIN = "ADMIN", "Admin"
        SUPER_ADMIN = "SUPER_ADMIN", "Super Admin"

    id = models.BigAutoField(primary_key=True)

    email = models.EmailField(
        unique=True,
        db_index=True,
    )

    first_name = models.CharField(max_length=100)
    middle_name = models.CharField(
        max_length=100,
        blank=True,
    )
    last_name = models.CharField(max_length=100)

    phone_number = models.CharField(
        max_length=13,
        unique=True,
        validators=[tanzania_phone_validator],
        db_index=True,
    )

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.USER,
        db_index=True,
    )

    profile_image = models.ImageField(
        upload_to="profiles/%Y/%m/",
        blank=True,
        null=True,
    )

    is_email_verified = models.BooleanField(default=False)

    is_phone_verified = models.BooleanField(default=False)

    is_active = models.BooleanField(default=True)

    is_staff = models.BooleanField(default=False)

    is_superuser = models.BooleanField(default=False)

    firebase_uid = models.CharField(
        max_length=255,
        unique=True,
        null=True,
        blank=True,
        db_index=True,
    )

    last_login_ip = models.GenericIPAddressField(
        null=True,
        blank=True,
    )

    last_activity = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        default=timezone.now,
        editable=False,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    USERNAME_FIELD = "email"

    REQUIRED_FIELDS = [
        "first_name",
        "last_name",
        "phone_number",
    ]

    objects = UserManager()

    class Meta:
        db_table = "users"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["email"]),
            models.Index(fields=["phone_number"]),
            models.Index(fields=["role"]),
            models.Index(fields=["created_at"]),
        ]

    def get_full_name(self):
        """Full name ya user."""
        parts = [self.first_name or '', self.middle_name or '', self.last_name or '']
        return ' '.join(p for p in parts if p).strip() or self.email
    
    def get_short_name(self):
        """First name pekee."""
        return self.first_name or self.email
    
    def __str__(self):
        return self.email

    @property
    def full_name(self):
        names = [
            self.first_name,
            self.middle_name,
            self.last_name,
        ]

        return " ".join(
            name for name in names if name
        ).strip()

    def is_admin_user(self):
        return self.role in {
            self.Role.ADMIN,
            self.Role.SUPER_ADMIN,
        }

    def save(self, *args, **kwargs):
        self.email = self.email.lower().strip()
        self.first_name = self.first_name.strip()
        self.last_name = self.last_name.strip()

        if self.middle_name:
            self.middle_name = self.middle_name.strip()

        super().save(*args, **kwargs)


class EmailVerificationCode(models.Model):
    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="email_verification_codes",
    )

    code = models.CharField(max_length=6)

    expires_at = models.DateTimeField()

    is_used = models.BooleanField(default=False)

    attempts = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "email_verification_codes"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["user", "is_used"]
            ),
            models.Index(
                fields=["expires_at"]
            ),
        ]

    def is_expired(self):
        return timezone.now() >= self.expires_at


class PasswordResetCode(models.Model):
    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="password_reset_codes",
    )

    code = models.CharField(max_length=6)

    expires_at = models.DateTimeField()

    is_used = models.BooleanField(default=False)

    attempts = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "password_reset_codes"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["user", "is_used"]
            ),
            models.Index(
                fields=["expires_at"]
            ),
        ]

    def is_expired(self):
        return timezone.now() >= self.expires_at