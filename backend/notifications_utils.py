# notification_utils.py

from firebase_admin import messaging

def send_push_to_token(token: str, title: str, body: str, data: dict = None):
    """
    Send a simple notification to a single device token.
    - token: the FCM device token (string) for one user’s device.
    - title, body: the human‐readable text.
    - data: optional key/value payload.
    """
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        token=token,
        data=data or {}
    )
    # This will return a message ID string or raise an exception if invalid.
    response = messaging.send(message)
    return response
