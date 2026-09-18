import logging

from django.contrib.auth import get_user_model
from django.utils.timezone import now
from firebase_admin import messaging

from .models import Notification, NotificationDevice


logger = logging.getLogger(__name__)

User = get_user_model()


def _prepare_fcm_data(data=None):
    """
    FCM data payload values must be strings.
    Converts all provided values safely to strings.
    """
    if not data:
        return {}

    prepared = {}

    for key, value in data.items():
        if value is None:
            prepared[str(key)] = ""
        elif isinstance(value, bool):
            prepared[str(key)] = "true" if value else "false"
        else:
            prepared[str(key)] = str(value)

    return prepared


def send_push_notification(
    device_token,
    title,
    message,
    data=None,
    image=None,
):
    """
    Send a single push notification through Firebase Cloud Messaging.

    Returns:
        True  -> FCM accepted the message
        False -> FCM sending failed
    """
    if not device_token:
        logger.warning("FCM send skipped: device token is empty")
        return False

    try:
        fcm_data = _prepare_fcm_data(data)

        notification_payload = messaging.Notification(
            title=title,
            body=message,
            image=image,
        )

        android_config = messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                title=title,
                body=message,
                image=image,
                sound="default",
            ),
        )

        apns_config = messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(
                        title=title,
                        body=message,
                    ),
                    sound="default",
                    badge=1,
                )
            )
        )

        message_obj = messaging.Message(
            notification=notification_payload,
            data=fcm_data,
            token=device_token,
            android=android_config,
            apns=apns_config,
        )

        response = messaging.send(message_obj)

        logger.info(
            "FCM sent successfully. token=%s response=%s",
            device_token,
            response,
        )

        return True

    except Exception as exc:
        logger.exception(
            "FCM send failed for token=%s: %s",
            device_token,
            exc,
        )
        return False


def send_notification_to_user(
    user,
    title,
    message,
    notification_type="SYSTEM",
    data=None,
    image=None,
    subtitle=None,
    action_url=None,
    action_label=None,
):
    """
    Complete notification flow:

    1. Save notification in the database.
    2. Find all active user devices.
    3. Attempt FCM delivery.
    4. Update delivery information.
    5. Return a structured result.

    Database persistence is independent from FCM delivery.
    Therefore, a failed push does not delete the in-app notification.
    """

    try:
        action_data = data or {}

        # ---------------------------------------------------------
        # 1. SAVE NOTIFICATION TO DATABASE
        # ---------------------------------------------------------
        notification = Notification.objects.create(
            recipient=user,
            notification_type=notification_type,
            title=title,
            message=message,
            subtitle=subtitle,
            action_url=action_url,
            action_label=action_label,
            action_data=action_data,
            image=image,
            created_at=now(),
        )

        # ---------------------------------------------------------
        # 2. FIND ACTIVE DEVICES
        # ---------------------------------------------------------
        devices = NotificationDevice.objects.filter(
            user=user,
            is_active=True,
        )

        device_tokens = [
            device.device_token
            for device in devices
            if device.device_token
        ]

        total_devices = len(device_tokens)

        # ---------------------------------------------------------
        # 3. NO DEVICE -> KEEP DATABASE NOTIFICATION
        # ---------------------------------------------------------
        if total_devices == 0:
            logger.info(
                "Notification %s saved for user %s. "
                "No active FCM devices found.",
                notification.id,
                user.id,
            )

            return {
                "notification": notification,
                "devices_sent": 0,
                "total_devices": 0,
            }

        # ---------------------------------------------------------
        # 4. SEND TO ALL ACTIVE DEVICES
        # ---------------------------------------------------------
        sent_count = 0

        for token in device_tokens:
            success = send_push_notification(
                device_token=token,
                title=title,
                message=message,
                data=action_data,
                image=image,
            )

            if success:
                sent_count += 1

        # ---------------------------------------------------------
        # 5. UPDATE DATABASE DELIVERY STATUS
        # ---------------------------------------------------------
        if sent_count > 0:
            notification.is_sent = True
            notification.sent_at = now()

            # Keep existing model default unless your model later
            # explicitly defines a different delivery convention.
            notification.save(
                update_fields=[
                    "is_sent",
                    "sent_at",
                    "updated_at",
                ]
            )

        logger.info(
            "Notification %s: %s/%s FCM devices accepted the message.",
            notification.id,
            sent_count,
            total_devices,
        )

        return {
            "notification": notification,
            "devices_sent": sent_count,
            "total_devices": total_devices,
        }

    except Exception as exc:
        logger.exception(
            "Failed to create/send notification for user %s: %s",
            getattr(user, "id", None),
            exc,
        )

        return None


def send_notification_to_role(
    role,
    title,
    message,
    notification_type="SYSTEM",
    data=None,
    image=None,
    subtitle=None,
    action_url=None,
    action_label=None,
):
    """
    Send a notification to all users with a specific role.
    Example roles:
        USER
        MECHANIC
        ADMIN
        SUPER_ADMIN
    """

    users = User.objects.filter(role=role)

    results = []

    for user in users:
        result = send_notification_to_user(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            data=data,
            image=image,
            subtitle=subtitle,
            action_url=action_url,
            action_label=action_label,
        )

        if result is not None:
            results.append(result)

    logger.info(
        "Notifications processed for role=%s users=%s",
        role,
        len(results),
    )

    return results


def send_notification_to_all_users(
    title,
    message,
    notification_type="SYSTEM",
    data=None,
    image=None,
    subtitle=None,
    action_url=None,
    action_label=None,
):
    """
    Broadcast a notification to every user.
    """

    users = User.objects.all()

    results = []

    for user in users:
        result = send_notification_to_user(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            data=data,
            image=image,
            subtitle=subtitle,
            action_url=action_url,
            action_label=action_label,
        )

        if result is not None:
            results.append(result)

    logger.info(
        "Broadcast notification processed for %s users.",
        len(results),
    )

    return results


def mark_notification_as_read(notification_id, user):
    """
    Mark one notification as read for its recipient.
    """

    try:
        notification = Notification.objects.get(
            id=notification_id,
            recipient=user,
        )

        notification.is_read = True
        notification.read_at = now()

        notification.save(
            update_fields=[
                "is_read",
                "read_at",
                "updated_at",
            ]
        )

        return True

    except Notification.DoesNotExist:
        logger.warning(
            "Notification %s not found for user %s.",
            notification_id,
            getattr(user, "id", None),
        )
        return False


def mark_all_notifications_as_read(user):
    """
    Mark all unread notifications for a user as read.
    """

    updated = Notification.objects.filter(
        recipient=user,
        is_read=False,
    ).update(
        is_read=True,
        read_at=now(),
    )

    logger.info(
        "Marked %s notifications as read for user %s.",
        updated,
        getattr(user, "id", None),
    )

    return updated


def get_unread_count(user):
    """
    Return unread notification count for a user.
    """

    return Notification.objects.filter(
        recipient=user,
        is_read=False,
    ).count()


def mark_notification_as_clicked(notification_id, user):
    """
    Mark a notification as clicked.
    """

    try:
        notification = Notification.objects.get(
            id=notification_id,
            recipient=user,
        )

        notification.is_clicked = True
        notification.clicked_at = now()

        notification.save(
            update_fields=[
                "is_clicked",
                "clicked_at",
                "updated_at",
            ]
        )

        return True

    except Notification.DoesNotExist:
        return False


def dismiss_notification(notification_id, user):
    """
    Mark a notification as dismissed.
    """

    try:
        notification = Notification.objects.get(
            id=notification_id,
            recipient=user,
        )

        notification.is_dismissed = True
        notification.dismissed_at = now()

        notification.save(
            update_fields=[
                "is_dismissed",
                "dismissed_at",
                "updated_at",
            ]
        )

        return True

    except Notification.DoesNotExist:
        return False
