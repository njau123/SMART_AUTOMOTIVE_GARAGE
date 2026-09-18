import firebase_admin
from firebase_admin import messaging
from django.conf import settings
from apps.notifications.models import Notification, NotificationDevice

def send_push_notification(device_token, title, message, data=None):
    """
    Send push notification to a device using FCM
    """
    if not device_token:
        return None

    try:
        # Create message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=message,
            ),
            token=device_token,
            data=data or {},
            android=messaging.AndroidConfig(
                priority='high',
            ),
            apns=messaging.APNSConfig(
                headers={
                    'apns-priority': '10',
                },
            ),
        )

        # Send message
        response = messaging.send(message)
        return response
    except Exception as e:
        print(f"Error sending push notification: {e}")
        return None

def send_notification_to_user(user, title, message, notification_type=None, action_url=None):
    """
    Send notification to all devices of a user
    """
    devices = NotificationDevice.objects.filter(user=user, is_active=True)
    results = []

    for device in devices:
        response = send_push_notification(
            device_token=device.device_token,
            title=title,
            message=message,
            data={'type': notification_type, 'url': action_url}
        )
        results.append({'device': device.id, 'success': response is not None})

    # Save notification to database
    notification = Notification.objects.create(
        recipient=user,
        title=title,
        message=message,
        notification_type=notification_type or 'SYSTEM',
        action_url=action_url,
        is_sent=True,
        sent_at=now()
    )

    return {
        'notification_id': notification.id,
        'devices_notified': results
    }
