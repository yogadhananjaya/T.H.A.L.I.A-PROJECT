import os
import logging
from typing import Dict, Any, Optional
from app.core.config import settings

logger = logging.getLogger("thalia_backend")

class FCMService:
    """
    Firebase Cloud Messaging (FCM) Service for instant emergency notifications to Flutter Mobile App.
    Includes mock fallback for offline development & competition demos.
    """
    _initialized = False

    @classmethod
    def _resolve_credentials_path(cls) -> str:
        raw_path = settings.FIREBASE_CREDENTIALS_PATH
        if os.path.exists(raw_path):
            return raw_path
        backend_dir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        )
        candidate = os.path.join(backend_dir, raw_path)
        return candidate if os.path.exists(candidate) else raw_path

    @classmethod
    def _init_firebase(cls):
        if cls._initialized:
            return True

        cred_path = cls._resolve_credentials_path()
        if not os.path.exists(cred_path):
            logger.warning(
                f"FCM credentials file '{cred_path}' not found. "
                "FCM will run in Mock Mode (simulated broadcast for hackathon demo)."
            )
            return False

        try:
            import firebase_admin
            from firebase_admin import credentials
            if not firebase_admin._apps:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            cls._initialized = True
            logger.info("Firebase Admin SDK initialized successfully.")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            return False

    @classmethod
    def send_emergency_alert(
        cls,
        severity: str,
        location: str,
        reason: str,
        safety_instructions: str,
        topic: str = "disaster_alerts"
    ) -> Dict[str, Any]:
        """
        Sends push notification to all subscribed residents and BPBD officials in the area.
        """
        title = f"⚠️ PERINGATAN BENCANA: {severity.upper()}!" if severity.lower() == "danger" else f"⚡ WASPADA: {severity.upper()}"
        body = f"{location} - {reason}. {safety_instructions}"

        if cls._init_firebase():
            try:
                from firebase_admin import messaging
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data={
                        "severity": severity,
                        "location": location,
                        "reason": reason,
                        "safety_instructions": safety_instructions,
                        "click_action": "FLUTTER_NOTIFICATION_CLICK"
                    },
                    topic=topic,
                )
                response = messaging.send(message)
                logger.info(f"FCM Notification sent successfully to topic '{topic}': {response}")
                return {"status": "SENT", "message_id": response, "title": title, "body": body}
            except Exception as e:
                logger.error(f"Failed to send FCM message: {e}")
                return {"status": "FAILED", "error": str(e), "title": title, "body": body}

        # Mock broadcast for demo without active Google cloud service account
        mock_id = f"mock-fcm-{severity.lower()}-msg-001"
        logger.info(f"[MOCK FCM BROADCAST] Topic: '{topic}' | Title: '{title}' | Body: '{body}'")
        return {
            "status": "MOCKED",
            "message_id": mock_id,
            "title": title,
            "body": body,
            "note": "Simulated push notification dispatched to mobile clients."
        }
