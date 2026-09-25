from django.conf import settings
from django.db import models


class DiagnosisSession(models.Model):
    class Source(models.TextChoices):
        SYMPTOMS = "SYMPTOMS", "Symptoms"
        OBD = "OBD", "OBD-II"
        AI = "AI", "AI Diagnosis"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSING = "PROCESSING", "Processing"
        COMPLETED = "COMPLETED", "Completed"
        FAILED = "FAILED", "Failed"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ai_diagnosis_sessions",
    )
    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="ai_diagnosis_sessions",
    )
    source = models.CharField(
        max_length=20,
        choices=Source.choices,
        default=Source.SYMPTOMS,
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    symptoms = models.JSONField(default=list, blank=True)
    user_description = models.TextField(blank=True)
    ai_summary = models.TextField(blank=True)
    possible_causes = models.JSONField(default=list, blank=True)
    recommended_actions = models.JSONField(default=list, blank=True)
    severity = models.CharField(max_length=20, blank=True)
    raw_response = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "ai_diagnosis_sessions"
        ordering = ["-created_at"]

    def __str__(self):
        return f"AI Diagnosis #{self.pk}"

# ==================== CONVERSATIONAL AI CHAT ====================
class ChatConversation(models.Model):
    """Mazungumzo ya user na AI mechanic — persistent."""
    user = models.ForeignKey(
        'accounts.User', on_delete=models.CASCADE,
        related_name='ai_conversations', null=True, blank=True,
    )
    title = models.CharField(max_length=200, blank=True)
    vehicle_make = models.CharField(max_length=100, blank=True)
    vehicle_model = models.CharField(max_length=100, blank=True)
    vehicle_year = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'ai_chat_conversations'
        ordering = ['-updated_at']

    def __str__(self):
        return f"Conv#{self.id} — {self.user.email if self.user else 'anon'}"


class ChatMessageLog(models.Model):
    """Ujumbe mmoja kwenye conversation."""
    ROLE_CHOICES = [
        ('user', 'User'),
        ('assistant', 'Assistant'),
    ]
    conversation = models.ForeignKey(
        ChatConversation, on_delete=models.CASCADE,
        related_name='messages',
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    content = models.TextField()
    has_image = models.BooleanField(default=False)
    image_url = models.URLField(blank=True)  # Cloudinary URL kama ipo
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_chat_messages'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.role}: {self.content[:50]}"

