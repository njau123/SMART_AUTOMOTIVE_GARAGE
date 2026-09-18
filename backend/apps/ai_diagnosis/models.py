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
