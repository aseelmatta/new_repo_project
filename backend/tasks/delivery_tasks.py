# backend/tasks/delivery_tasks.py

from celery_app import celery
import math
from firebase_admin import firestore
from firebase_init import db  # make sure firebase is initialized here

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
    Find the nearest courier for the given delivery_id and update Firestore.
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
        # Update the delivery document to assign the courier
        delivery_ref.update({
            'assignedCourier': best_courier,
            'status': 'accepted',
            'timestampUpdated': firestore.SERVER_TIMESTAMP
        })

    return {'assignedCourier': best_courier or None}
