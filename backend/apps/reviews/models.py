import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class ReviewStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    PUBLISHED = "PUBLISHED", "Published"
    HIDDEN = "HIDDEN", "Hidden"
    FLAGGED = "FLAGGED", "Flagged"


class Review(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        db_index=True,
    )

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reviews_given",
    )

    mechanic = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reviews_received",
        null=True,
        blank=True,
    )

    booking = models.ForeignKey(
        "bookings.Booking",
        on_delete=models.CASCADE,
        related_name="review",
        null=True,
        blank=True,
    )

    service = models.ForeignKey(
        "services.Service",
        on_delete=models.SET_NULL,
        related_name="reviews",
        null=True,
        blank=True,
    )

    overall_rating = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(5),
        ],
    )

    service_rating = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(5),
        ],
        null=True,
        blank=True,
    )

    mechanic_rating = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(5),
        ],
        null=True,
        blank=True,
    )

    communication_rating = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(5),
        ],
        null=True,
        blank=True,
    )

    value_rating = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(5),
        ],
        null=True,
        blank=True,
    )

    comment = models.TextField(
        blank=True,
    )

    status = models.CharField(
        max_length=20,
        choices=ReviewStatus.choices,
        default=ReviewStatus.PENDING,
        db_index=True,
    )

    is_verified = models.BooleanField(
        default=False,
    )

    is_anonymous = models.BooleanField(
        default=False,
    )

    helpful_count = models.PositiveIntegerField(
        default=0,
    )

    report_count = models.PositiveIntegerField(
        default=0,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "reviews"
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["customer", "booking"],
                name="unique_customer_booking_review",
            ),
        ]
        indexes = [
            models.Index(
                fields=["mechanic", "status"],
            ),
            models.Index(
                fields=["service", "status"],
            ),
            models.Index(
                fields=["overall_rating"],
            ),
            models.Index(
                fields=["created_at"],
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"REV-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def __str__(self):
        return self.reference


class ReviewImage(models.Model):
    review = models.ForeignKey(
        Review,
        on_delete=models.CASCADE,
        related_name="images",
    )

    image = models.ImageField(
        upload_to="reviews/%Y/%m/%d/",
    )

    caption = models.CharField(
        max_length=255,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "review_images"
        ordering = ["created_at"]

    def __str__(self):
        return f"Image for {self.review.reference}"


class ReviewHelpful(models.Model):
    review = models.ForeignKey(
        Review,
        on_delete=models.CASCADE,
        related_name="helpful_votes",
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="review_helpful_votes",
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "review_helpful_votes"
        constraints = [
            models.UniqueConstraint(
                fields=["review", "user"],
                name="unique_review_helpful_vote",
            ),
        ]

    def __str__(self):
        return f"{self.user_id} -> {self.review_id}"


class ReviewReport(models.Model):
    class Reason(models.TextChoices):
        SPAM = "SPAM", "Spam"
        ABUSE = "ABUSE", "Abusive"
        FAKE = "FAKE", "Fake"
        OFFENSIVE = "OFFENSIVE", "Offensive"
        IRRELEVANT = "IRRELEVANT", "Irrelevant"
        OTHER = "OTHER", "Other"

    review = models.ForeignKey(
        Review,
        on_delete=models.CASCADE,
        related_name="reports",
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="review_reports",
    )

    reason = models.CharField(
        max_length=20,
        choices=Reason.choices,
    )

    description = models.TextField(
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "review_reports"
        constraints = [
            models.UniqueConstraint(
                fields=["review", "user"],
                name="unique_review_report",
            ),
        ]

    def __str__(self):
        return f"Report {self.id}"