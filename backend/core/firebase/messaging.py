from firebase_admin import messaging

from .client import get_firebase_app


class FirebaseMessagingService:

    @staticmethod
    def send_to_token(
        token,
        title,
        body,
        data=None,
    ):
        if not token:
            raise ValueError(
                "FCM device token is required."
            )

        get_firebase_app()

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                str(key): str(value)
                for key, value in (
                    data or {}
                ).items()
            },
            token=token,
        )

        return messaging.send(
            message
        )

    @staticmethod
    def send_to_tokens(
        tokens,
        title,
        body,
        data=None,
    ):
        valid_tokens = [
            token
            for token in tokens
            if token
        ]

        if not valid_tokens:
            return {
                "success_count": 0,
                "failure_count": 0,
            }

        get_firebase_app()

        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                str(key): str(value)
                for key, value in (
                    data or {}
                ).items()
            },
            tokens=valid_tokens,
        )

        response = (
            messaging.send_each_for_multicast(
                message
            )
        )

        return {
            "success_count": (
                response.success_count
            ),
            "failure_count": (
                response.failure_count
            ),
        }