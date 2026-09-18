from django.conf import settings
from django.db import models


class ContactStatus(models.TextChoices):
    NEW = "NEW", "New"
    READ = "READ", "Read"
    REPLIED = "REPLIED", "Replied"
    ARCHIVED = "ARCHIVED", "Archived"


class ContactMessage(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="contact_messages",
    )
    full_name = models.CharField(max_length=200)
    email = models.EmailField()
    phone = models.CharField(max_length=20, blank=True)
    subject = models.CharField(max_length=255, blank=True)
    message = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=ContactStatus.choices,
        default=ContactStatus.NEW,
        db_index=True,
    )
    admin_reply = models.TextField(blank=True)
    replied_at = models.DateTimeField(null=True, blank=True)
    replied_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="replied_contact_messages",
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "contact_messages"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.full_name} - {(self.subject or self.message)[:50]}"
