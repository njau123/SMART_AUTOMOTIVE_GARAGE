from django.db.models import Avg, Count

from .models import (
    Review,
    ReviewHelpful,
    ReviewReport,
    ReviewStatus,
)


class ReviewService:

    @staticmethod
    def publish_review(review):
        review.status = ReviewStatus.PUBLISHED
        review.is_verified = True

        review.save(
            update_fields=[
                "status",
                "is_verified",
                "updated_at",
            ]
        )

        return review

    @staticmethod
    def hide_review(review):
        review.status = ReviewStatus.HIDDEN

        review.save(
            update_fields=[
                "status",
                "updated_at",
            ]
        )

        return review

    @staticmethod
    def flag_review(review):
        review.status = ReviewStatus.FLAGGED

        review.save(
            update_fields=[
                "status",
                "updated_at",
            ]
        )

        return review

    @staticmethod
    def add_helpful_vote(
        *,
        review,
        user,
    ):
        vote, created = (
            ReviewHelpful.objects.get_or_create(
                review=review,
                user=user,
            )
        )

        if created:
            review.helpful_count += 1

            review.save(
                update_fields=[
                    "helpful_count",
                    "updated_at",
                ]
            )

        return vote, created

    @staticmethod
    def remove_helpful_vote(
        *,
        review,
        user,
    ):
        deleted, _ = (
            ReviewHelpful.objects.filter(
                review=review,
                user=user,
            ).delete()
        )

        if deleted:
            review.helpful_count = max(
                0,
                review.helpful_count - 1,
            )

            review.save(
                update_fields=[
                    "helpful_count",
                    "updated_at",
                ]
            )

        return deleted

    @staticmethod
    def report_review(
        *,
        review,
        user,
        reason,
        description="",
    ):
        report, created = (
            ReviewReport.objects.get_or_create(
                review=review,
                user=user,
                defaults={
                    "reason": reason,
                    "description": description,
                },
            )
        )

        if created:
            review.report_count += 1

            review.save(
                update_fields=[
                    "report_count",
                    "updated_at",
                ]
            )

        if review.report_count >= 3:
            ReviewService.flag_review(review)

        return report, created

    @staticmethod
    def get_mechanic_summary(mechanic):
        queryset = Review.objects.filter(
            mechanic=mechanic,
            status=ReviewStatus.PUBLISHED,
        )

        result = queryset.aggregate(
            average_rating=Avg(
                "overall_rating"
            ),
            total_reviews=Count("id"),
        )

        distribution = {
            f"{rating}_star": queryset.filter(
                overall_rating=rating
            ).count()
            for rating in range(1, 6)
        }

        return {
            "average_rating": round(
                result["average_rating"] or 0,
                2,
            ),
            "total_reviews": (
                result["total_reviews"] or 0
            ),
            "five_star": distribution[
                "5_star"
            ],
            "four_star": distribution[
                "4_star"
            ],
            "three_star": distribution[
                "3_star"
            ],
            "two_star": distribution[
                "2_star"
            ],
            "one_star": distribution[
                "1_star"
            ],
        }

    @staticmethod
    def get_service_summary(service):
        queryset = Review.objects.filter(
            service=service,
            status=ReviewStatus.PUBLISHED,
        )

        result = queryset.aggregate(
            average_rating=Avg(
                "overall_rating"
            ),
            total_reviews=Count("id"),
        )

        return {
            "average_rating": round(
                result["average_rating"] or 0,
                2,
            ),
            "total_reviews": (
                result["total_reviews"] or 0
            ),
        }