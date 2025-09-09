# backend/tasks/delivery_tasks.py

from celery_app import celery
import math
import os
import time
import requests
from firebase_admin import firestore
from firebase_init import db  # firebase app initialized elsewhere

# Configure where to send internal WS notifications.
# If Celery runs in a separate container, DO NOT use 127.0.0.1 here.
# Point to the Flask service host, e.g., http://app:5001/internal/ws/notify
WS_NOTIFY_URL = os.environ.get(
    "WS_NOTIFY_URL",
    "http://127.0.0.1:5001/internal/ws/notify",
)

def haversine_distance(lat1, lng1, lat2, lng2) -> float:
    R = 6371.0  # km
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lng2 - lng1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def _ws_notify(uid: str, message: dict) -> None:
    """Best-effort HTTP notify to the Flask /internal/ws/notify endpoint."""
    if not uid:
        print("[WS notify] skipped: empty uid")
        return
    try:
        r = requests.post(
            WS_NOTIFY_URL,
            json={"uid": uid, "message": message},
            timeout=3.0,
        )
        print(f"[WS notify] -> {WS_NOTIFY_URL} uid={uid} ev={message.get('event')} "
              f"delivery_id={message.get('delivery_id')} status={r.status_code}")
        r.raise_for_status()
    except Exception as e:
        print(f"[WS notify] failed for uid={uid}: {e}")

def _resolve_business_uids(delivery: dict) -> list[str]:
    """
    Determine which business user(s) to notify.
    Prefers explicit user UID; falls back to creator; optionally expands an org.
    """
    uids: list[str] = []
    # Common fields: businessUid or createdBy
    business_uid = delivery.get("businessUid") or delivery.get("createdBy")
    if business_uid:
        uids.append(business_uid)

    # Optional: if you store an org id and have a sub-collection of users
    business_id = delivery.get("businessId")
    if business_id:
        try:
            q = db.collection("business_users").where("businessId", "==", business_id).stream()
            for doc in q:
                # assume document id is the uid
                uids.append(doc.id)
        except Exception as e:
            print(f"[WS notify] could not resolve business users for businessId={business_id}: {e}")

    # Deduplicate
    return list(dict.fromkeys([u for u in uids if u]))

@celery.task(name="delivery_tasks.match_and_assign_courier")
def match_and_assign_courier(delivery_id: str):
    """
    Find the nearest available courier for the given delivery_id and assign it.
    Then notify:
      - the assigned courier with 'delivery_assigned'
      - the business with 'delivery_status_updated' (status: 'accepted')
    """
    try:
        delivery_ref = db.collection("deliveries").document(delivery_id)
        delivery_doc = delivery_ref.get()
        if not delivery_doc.exists:
            return {"error": "Delivery not found"}

        data = delivery_doc.to_dict() or {}
        pickup = data.get("pickupLocation") or {}
        lat1 = pickup.get("lat")
        lng1 = pickup.get("lng")
        if lat1 is None or lng1 is None:
            return {"error": "Invalid pickupLocation"}

        # Choose the best courier (capacity < 2 active jobs)
        best_dist = None
        best_courier = None

        for loc_doc in db.collection("courier_locations").stream():
            courier_uid = loc_doc.id
            loc = loc_doc.to_dict() or {}
            lat2 = loc.get("lat")
            lng2 = loc.get("lng")
            if lat2 is None or lng2 is None:
                continue

            # Capacity check: accepted or in_progress
            active_cursor = (
                db.collection("deliveries")
                .where("assignedCourier", "==", courier_uid)
                .where("status", "in", ["accepted", "in_progress"])
                .stream()
            )
            # Count without materializing full list
            active_count = sum(1 for _ in active_cursor)
            if active_count >= 2:
                continue

            dist = haversine_distance(float(lat1), float(lng1), float(lat2), float(lng2))
            if best_dist is None or dist < best_dist:
                best_dist = dist
                best_courier = courier_uid

        if not best_courier:
            print(f"[assign] No eligible courier for delivery {delivery_id}")
            return {"assignedCourier": None}

        # Persist assignment
        delivery_ref.update(
            {
                "assignedCourier": best_courier,
                "status": "accepted",
                "timestampUpdated": firestore.SERVER_TIMESTAMP,
            }
        )

        # Build notify payloads
        dropoff = data.get("dropoffLocation") or {}
        courier_msg = {
            "event": "delivery_assigned",
            "delivery_id": delivery_id,
            "courier_id": best_courier,
            "pickup": {
                "lat": lat1,
                "lng": lng1,
                "address": data.get("pickupAddress"),
            },
            "dropoff": {
                "lat": dropoff.get("lat"),
                "lng": dropoff.get("lng"),
                "address": data.get("dropoffAddress"),
            },
            "created_by": data.get("createdBy"),
        }

        business_msg = {
            "event": "delivery_status_updated",
            "delivery_id": delivery_id,
            "status": "accepted",
            "assignedCourier": best_courier,
        }

        # Notify courier
        _ws_notify(best_courier, courier_msg)

        # Small delay can help if the courier app is still registering its WS
        time.sleep(0.2)

        # Notify business (one or many)
        for buid in _resolve_business_uids(data):
            _ws_notify(buid, business_msg)

        return {"assignedCourier": best_courier}

    except Exception as e:
        print(f"[assign] error for {delivery_id}: {e}")
        return {"error": str(e)}
"""# backend/tasks/delivery_tasks.py

from celery_app import celery
import math
import os
import requests
from firebase_admin import firestore
from firebase_init import db  # make sure firebase is initialized here

# Optional: configure where to send the internal notify
WS_NOTIFY_URL = os.environ.get(
    "WS_NOTIFY_URL",
    "http://127.0.0.1:5001/internal/ws/notify"
)

def haversine_distance(lat1, lng1, lat2, lng2):
    R = 6371.0  # Earth radius in km
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lng2 - lng1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

@celery.task(name='delivery_tasks.match_and_assign_courier')
def match_and_assign_courier(delivery_id):
    """
""" Find the nearest courier for the given delivery_id and update Firestore.
    Then notify ONLY the assigned courier via the app's internal WS notify endpoint.
    """
"""
    delivery_ref = db.collection('deliveries').document(delivery_id)
    delivery_doc = delivery_ref.get()
    if not delivery_doc.exists:
        return {'error': 'Delivery not found'}

    data = delivery_doc.to_dict()
    pickup = data.get('pickupLocation')
    if not pickup:
        return {'error': 'No pickupLocation'}

    lat1 = pickup.get('lat')
    lng1 = pickup.get('lng')
    if lat1 is None or lng1 is None:
        return {'error': 'Invalid pickupLocation'}

    best_dist = None
    best_courier = None

    # Stream all courier locations
    for loc_doc in db.collection('courier_locations').stream():
        loc = loc_doc.to_dict()
        courier_uid = loc_doc.id
        lat2 = loc.get('lat')
        lng2 = loc.get('lng')
        if lat2 is None or lng2 is None:
            continue

        active_deliveries = db.collection('deliveries') \
            .where('assignedCourier', '==', courier_uid) \
            .where('status', 'in', ['accepted', 'in_progress']) \
            .stream()
        delivery_count = sum(1 for _ in active_deliveries)
        if delivery_count >= 2:
            continue

        dist = haversine_distance(lat1, lng1, lat2, lng2)
        if best_dist is None or dist < best_dist:
            best_dist = dist
            best_courier = courier_uid

    if best_courier:
        # 1) Persist the assignment
        delivery_ref.update({
            'assignedCourier': best_courier,
            'status': 'accepted',
            'timestampUpdated': firestore.SERVER_TIMESTAMP
        })

        # 2) Prepare payload for the driver
        dropoff = data.get('dropoffLocation') or {}
        payload = {
            "event": "delivery_assigned",
            "delivery_id": delivery_id,
            "courier_id": best_courier,
            "pickup": {
                "lat": lat1, "lng": lng1,
                "address": data.get("pickupAddress")
            },
            "dropoff": {
                "lat": dropoff.get("lat"),
                "lng": dropoff.get("lng"),
                "address": data.get("dropoffAddress")
            },
            "created_by": data.get("createdBy"),
        }
        business_msg = {
            "event": "delivery_status_updated",   # frontend also listens to this
            "delivery_id": delivery_id,
            "status": "accepted",
            "assignedCourier": best_courier,
                }

        # 3) Notify ONLY the assigned courier via internal HTTP endpoint in app.py
        #    (Avoids starting a second WS server in the Celery process.)
        try:
            resp = requests.post(
                WS_NOTIFY_URL,
                json={"uid": best_courier, "message": payload},
                timeout=3.0,
            )
            resp.raise_for_status()
        except Exception as e:
            # Best-effort: don't fail the task if notify fails
            print(f"[WS notify] failed for courier {best_courier}: {e}")
        
        try:
            resp = requests.post(
                WS_NOTIFY_URL,
                json={"uid": data.get('createdBy'), "message": business_msg},
                timeout=3.0,
            )
            resp.raise_for_status()
        except Exception as e:
            # Best-effort: don't fail the task if notify fails
            print(f"[WS notify] failed for bussiness {data.get('createdBy')}: {e}")

        # (Old direct WS call for reference; keep commented)
        # from websocket_manager import manager
        # manager.send_to_user(best_courier, payload)

    return {'assignedCourier': best_courier or None}
"""