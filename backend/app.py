# app.py
from math import radians, sin, cos, sqrt, atan2
from firebase_admin import auth as firebase_auth

from flask import Flask, jsonify, request
from flask_cors import CORS

from models import Order, Carrier, Business
from auth import require_token

from firebase_init import db
from google.cloud import firestore

from tasks.delivery_tasks import match_and_assign_courier
from websocket_manager import manager
app = Flask(__name__)
CORS(app)  
@app.route('/health', methods=['GET'])
def health():
    return jsonify({"success": True, "status": "ok"}), 200

#-----------------------
# PROFILE ENDPOINTS
#-----------------------
@app.route('/createUserProfile', methods=['POST'])
@require_token
def create_user_profile():
    try:
        data = request.get_json()
        print('DATA RECEIVED AT /createUserProfile:', data)
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        role = data.get('role')
        display_name = data.get('displayName')
        phone = data.get('phone')

        if role not in ('business', 'courier'):
            return jsonify({'success': False, 'error': 'Invalid or missing role'}), 401

        uid = request.uid
        email = data.get('email')

        user_doc_ref = db.collection('users').document(uid)

        
        profile = {
            'role': role,
            'displayName': display_name,
            'email': email,
            'phone': phone,
        }
        
        for key, value in data.items():
            if key not in profile or not profile[key]:
                profile[key] = value

        # Save to Firestore 
        user_doc_ref.set(profile, merge=True)

        return jsonify({'success': True}), 201

    except Exception as e:
        import traceback
        print('EXCEPTION IN /createUserProfile:', e)
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500
    

@app.route('/getUserProfile', methods=['GET'])
@require_token
def get_user_profile():
    try:
        uid = request.uid
        #uid = 'TEST_UID'  

        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            return jsonify({'success': False, 'error': 'Profile not found'}), 404

        data = user_doc.to_dict()
        
        data['uid'] = uid

        return jsonify({'success': True, 'profile': data}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/updateUserProfile', methods=['PUT'])
@require_token
def update_user_profile():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        uid = request.uid
       # uid = 'TEST_UID'  
        user_doc_ref = db.collection('users').document(uid)
        if not user_doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'Profile not found'}), 404

        updates = {}
        if 'displayName' in data:
            updates['displayName'] = data['displayName']
        if 'phone' in data:
            updates['phone'] = data['phone']
        if 'role' in data:
            # Allow changing role only if it’s valid
            if data['role'] not in ('business', 'courier'):
                return jsonify({'success': False, 'error': 'Invalid role'}), 400
            updates['role'] = data['role']
       
        if 'email' in data:
            updates['email'] = data['email']

        if not updates:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        user_doc_ref.update(updates)
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ------------------------
# ORDERS ENDPOINTS
# ------------------------

# @app.route('/getOrders', methods=['GET'])
# @require_token
# def get_orders():
#     try:
#         orders_ref = db.collection('orders')
#         docs = orders_ref.stream()

#         orders_list = []
#         for doc in docs:
#             o = Order.from_dict(doc.to_dict(), doc.id)
#             orders_list.append({'id': o.id, **o.to_dict()})

#         return jsonify({'success': True, 'orders': orders_list}), 200

#     except Exception as e:
#         return jsonify({'success': False, 'error': str(e)}), 500


# @app.route('/getOrder/<order_id>', methods=['GET'])
# @require_token
# def get_order(order_id):
#     try:
#         doc_ref = db.collection('orders').document(order_id)
#         doc = doc_ref.get()
#         if not doc.exists:
#             return jsonify({'success': False, 'error': 'Order not found'}), 404

#         o = Order.from_dict(doc.to_dict(), doc.id)
#         return jsonify({'success': True, 'order': {'id': o.id, **o.to_dict()}}), 200

#     except Exception as e:
#         return jsonify({'success': False, 'error': str(e)}), 500


# @app.route('/createOrder', methods=['POST'])
# @require_token
# def create_order():
#     try:
#         data = request.get_json()
#         if not data:
#             return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

#         # Required fields: customer (str), items (list)
#         customer = data.get('customer')
#         items = data.get('items')
#         status = data.get('status', 'pending')
#         carrier_id = data.get('carrier_id')
#         business_id = data.get('business_id')

#         if not customer or items is None:
#             return jsonify({'success': False, 'error': 'Missing required fields'}), 400

#         new_order = Order(
#             customer = customer,
#             items = items,
#             status = status,
#             carrier_id = carrier_id,
#             business_id = business_id
#         )
#         _, doc_ref = db.collection('orders').add(new_order.to_dict())
#         return jsonify({'success': True, 'order_id': doc_ref.id}), 201

#     except Exception as e:
#         return jsonify({'success': False, 'error': str(e)}), 500


# @app.route('/updateOrder/<order_id>', methods=['PUT'])
# @require_token
# def update_order(order_id):
#     try:
#         data = request.get_json()
#         if not data:
#             return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

#         doc_ref = db.collection('orders').document(order_id)
#         snapshot = doc_ref.get()
#         if not snapshot.exists:
#             return jsonify({'success': False, 'error': 'Order not found'}), 404

#         updates = {}
#         if 'customer' in data:
#             updates['customer'] = data['customer']
#         if 'items' in data:
#             updates['items'] = data['items']
#         if 'status' in data:
#             updates['status'] = data['status']
#         if 'carrier_id' in data:
#             updates['carrier_id'] = data['carrier_id']
#         if 'business_id' in data:
#             updates['business_id'] = data['business_id']

#         if not updates:
#             return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

#         doc_ref.update(updates)
#         return jsonify({'success': True}), 200

#     except Exception as e:
#         return jsonify({'success': False, 'error': str(e)}), 500



# ------------------------
# CARRIERS ENDPOINTS
# ------------------------

@app.route('/getCarriers', methods=['GET'])
@require_token
def get_carriers():
    try:
        carriers_ref = db.collection('carriers')
        docs = carriers_ref.stream()
        carriers_list = []
        for doc in docs:
            c = Carrier.from_dict(doc.to_dict(), doc.id)
            carriers_list.append({'id': c.id, **c.to_dict()})
        return jsonify({'success': True, 'carriers': carriers_list}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/getCarrier/<carrier_id>', methods=['GET'])
@require_token
def get_carrier(carrier_id):
    try:
        doc_ref = db.collection('carriers').document(carrier_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({'success': False, 'error': 'Carrier not found'}), 404

        c = Carrier.from_dict(doc.to_dict(), doc.id)
        return jsonify({'success': True, 'carrier': {'id': c.id, **c.to_dict()}}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/createCarrier', methods=['POST'])
@require_token
def create_carrier():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        name = data.get('name')
        phone = data.get('phone')
        available = data.get('available', True)

        if not name or not phone:
            return jsonify({'success': False, 'error': 'Missing required fields'}), 400

        new_carrier = Carrier(name=name, phone=phone, available=available)
        _, doc_ref = db.collection('carriers').add(new_carrier.to_dict())
        return jsonify({'success': True, 'carrier_id': doc_ref.id}), 201

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/updateCarrier/<carrier_id>', methods=['PUT'])
@require_token
def update_carrier(carrier_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        doc_ref = db.collection('carriers').document(carrier_id)
        snapshot = doc_ref.get()
        if not snapshot.exists:
            return jsonify({'success': False, 'error': 'Carrier not found'}), 404

        updates = {}
        if 'name' in data:
            updates['name'] = data['name']
        if 'phone' in data:
            updates['phone'] = data['phone']
        if 'available' in data:
            updates['available'] = data['available']

        if not updates:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        doc_ref.update(updates)
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/deleteCarrier/<carrier_id>', methods=['DELETE'])
@require_token
def delete_carrier(carrier_id):
    try:
        doc_ref = db.collection('carriers').document(carrier_id)
        if not doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'Carrier not found'}), 404

        doc_ref.delete()
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ------------------------
# BUSINESSES ENDPOINTS
# ------------------------

@app.route('/getBusinesses', methods=['GET'])
@require_token
def get_businesses():
    try:
        businesses_ref = db.collection('businesses')
        docs = businesses_ref.stream()
        business_list = []
        for doc in docs:
            b = Business.from_dict(doc.to_dict(), doc.id)
            business_list.append({'id': b.id, **b.to_dict()})
        return jsonify({'success': True, 'businesses': business_list}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/getBusiness/<business_id>', methods=['GET'])
@require_token
def get_business(business_id):
    try:
        doc_ref = db.collection('businesses').document(business_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({'success': False, 'error': 'Business not found'}), 404

        b = Business.from_dict(doc.to_dict(), doc.id)
        return jsonify({'success': True, 'business': {'id': b.id, **b.to_dict()}}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/createBusiness', methods=['POST'])
@require_token
def create_business():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        name = data.get('name')
        address = data.get('address')
        phone = data.get('phone')

        if not name or not address or not phone:
            return jsonify({'success': False, 'error': 'Missing required fields'}), 400

        new_business = Business(name=name, address=address, phone=phone)
        _, doc_ref = db.collection('businesses').add(new_business.to_dict())
        return jsonify({'success': True, 'business_id': doc_ref.id}), 201

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/updateBusiness/<business_id>', methods=['PUT'])
@require_token
def update_business(business_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        doc_ref = db.collection('businesses').document(business_id)
        snapshot = doc_ref.get()
        if not snapshot.exists:
            return jsonify({'success': False, 'error': 'Business not found'}), 404

        updates = {}
        if 'name' in data:
            updates['name'] = data['name']
        if 'address' in data:
            updates['address'] = data['address']
        if 'phone' in data:
            updates['phone'] = data['phone']

        if not updates:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        doc_ref.update(updates)
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/deleteBusiness/<business_id>', methods=['DELETE'])
@require_token
def delete_business(business_id):
    try:
        doc_ref = db.collection('businesses').document(business_id)
        if not doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'Business not found'}), 404

        doc_ref.delete()
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500



# === DELIVERY ROUTES START HERE ===

@app.route('/getCourierLocations', methods=['GET'])
@require_token
def get_courier_locations():
    try:
        docs = db.collection('courier_locations').stream()
        locations = []
        for doc in docs:
            data = doc.to_dict()
            locations.append({
                'id': doc.id,
                'lat': data.get('lat'),
                'lng': data.get('lng'),
                'timestamp': data.get('timestamp').isoformat() if data.get('timestamp') else None
            })
        return jsonify({'success': True, 'locations': locations}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/updateLocation', methods=['PUT'])
@require_token
def update_location():
    data = request.get_json() or {}
    lat = data.get('lat')
    lng = data.get('lng')
    if lat is None or lng is None:
        return jsonify({'success': False, 'error': 'Missing lat or lng'}), 400

   #uid = 'test_uid'
    uid = request.uid
    db.collection('courier_locations').document(uid).set({
        'lat': lat,
        'lng': lng,
        'timestamp': firestore.SERVER_TIMESTAMP
    })
    return jsonify({'success': True}), 200



@app.route('/createDelivery', methods=['POST'])
@require_token
def create_delivery():
    data = request.get_json() or {}
    pickup = data.get('pickupLocation')
    dropoff = data.get('dropoffLocation')
    recipient_name = data.get('recipientName')
    recipient_phone = data.get('recipientPhone')
    instructions = data.get('instructions', "")

    if not pickup or 'lat' not in pickup or 'lng' not in pickup:
        return jsonify({'success': False, 'error': 'Missing pickupLocation'}), 400
    if not dropoff or 'lat' not in dropoff or 'lng' not in dropoff:
        return jsonify({'success': False, 'error': 'Missing dropoffLocation'}), 400
    if not recipient_name:
        return jsonify({'success': False, 'error': 'Missing recipientName'}), 400
    if not recipient_phone:
        return jsonify({'success': False, 'error': 'Missing recipientPhone'}), 400
    
    def haversine(lat1, lon1, lat2, lon2):
        R = 6371  # km
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat/2)**2 + cos(radians(lat1))*cos(radians(lat2))*sin(dlon/2)**2
        return 2*R*atan2(sqrt(a), sqrt(1-a))
    
    uid = request.uid
    dist_km = haversine(pickup['lat'], pickup['lng'], dropoff['lat'], dropoff['lng'])
    fee = round(2.0 * dist_km + 5.0, 2)
    #uid = 'test_uid'

    delivery_data = {
        'pickupLocation': {'lat': pickup['lat'], 'lng': pickup['lng']},
        'dropoffLocation': {'lat': dropoff['lat'], 'lng': dropoff['lng']},
        'recipientName': recipient_name,
        'recipientPhone': recipient_phone,
        'instructions': instructions,
        'status': 'pending',
        'createdBy': uid,
        'assignedCourier': None,
        'fee': fee,
        'rating': None,
        'timestampCreated': firestore.SERVER_TIMESTAMP,
        'timestampUpdated': firestore.SERVER_TIMESTAMP
    }
    doc_ref = db.collection('deliveries').add(delivery_data)[1]
    delivery_id = doc_ref.id

    # Enqueue the background task that finds & assigns the nearest courier
    match_and_assign_courier.delay(delivery_id)

    return jsonify({'success': True, 'delivery_id': delivery_id}), 201


@app.route('/getDeliveries', methods=['GET'])
@require_token
def get_deliveries():
    """
    Returns a list of deliveries:
      - If the user’s role is “business”, returns deliveries where createdBy == uid
      - If the user’s role is “courier”, returns deliveries where assignedCourier == uid
    """
    try:
        uid = request.uid
        
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            return jsonify({'success': False, 'error': 'Profile not found'}), 404

        profile = user_doc.to_dict()
        role = profile.get('role')

        if role == 'business':
            
            query = db.collection('deliveries').where('createdBy', '==', uid)
        elif role == 'courier':
           
            query = db.collection('deliveries').where('assignedCourier', '==', uid)
        else:
            return jsonify({'success': False, 'error': 'Invalid role'}), 400

        docs = query.stream()

        deliveries = []
        for doc in docs:
            data = doc.to_dict()
            
            deliveries.append({'id': doc.id, **data})

        return jsonify({'success': True, 'deliveries': deliveries}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/getDelivery/<delivery_id>', methods=['GET'])
@require_token
def get_delivery(delivery_id):
    """
    Return the delivery document with ID == delivery_id.
    """
    try:
        doc_ref = db.collection('deliveries').document(delivery_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({'success': False, 'error': 'Delivery not found'}), 404

        data = doc.to_dict()
        return jsonify({'success': True, 'delivery': {'id': doc.id, **data}}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    
@app.route('/updateDelivery/<delivery_id>', methods=['PUT'])
@require_token
def update_delivery_status(delivery_id):
    """
    Allows the assigned courier to update the status of their delivery.
    Expected JSON body: { "status": "<newStatus>" }
    """
    try:
        data = request.get_json() or {}
        new_status = data.get('status')
        if not new_status:
            return jsonify({'success': False, 'error': 'Missing status field'}), 400

        uid = request.uid
        #  Verify the delivery exists and that this user is actually the assigned courier
        doc_ref = db.collection('deliveries').document(delivery_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({'success': False, 'error': 'Delivery not found'}), 404

        delivery = doc.to_dict()
        assigned = delivery.get('assignedCourier')
        if assigned != uid:
            return jsonify({'success': False, 'error': 'Forbidden—You are not assigned to this delivery'}), 403

        
        doc_ref.update({
            'status': new_status,
            'timestampUpdated': firestore.SERVER_TIMESTAMP
        })

        if new_status == 'in_progress':
            doc_ref.update({
            'timestampPickedUp' : firestore.SERVER_TIMESTAMP
            })
        if new_status == 'completed':
            doc_ref.update({
            'timestampDelivered': firestore.SERVER_TIMESTAMP
            })

            pending = db.collection('deliveries') \
                .where('status', '==', 'pending') \
                .stream()
            for p in pending:
                match_and_assign_courier.delay(p.id)

        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    
    
    
    
@app.route('/deleteDelivery/<delivery_id>', methods=['DELETE'])
@require_token
def delete_delivery(delivery_id):
    try:
        doc_ref = db.collection('deliveries').document(delivery_id)
        if not doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'delivery not found'}), 404

        doc_ref.delete()
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


#---------------------------------------------------
#GOOGLE AND FACEBOOK 
#----------------------------------------------------
@app.route('/auth/google', methods=['POST'])
def auth_google():
    data = request.get_json() or {}
    print('GOT DATA:', data)
    id_token = data.get('id_token')
    if not id_token:
        return jsonify({'success': False, 'error': 'Missing id_token'}), 400

    try:
        
        decoded = firebase_auth.verify_id_token(id_token)
        uid = decoded['uid']

        
        user_ref = db.collection('users').document(uid)
        update_data = {}
        if decoded.get('email'):
            update_data['email'] = decoded['email']
        pic = decoded.get('picture')
        if pic:
            update_data['photoURL'] = pic
       

        if update_data:
           
            user_ref.set(update_data,merge=True)


        return jsonify({'success': True, 'uid': uid}), 200

    except Exception as e:
        print('GOOGLE AUTH ERROR:', e)
        return jsonify({'success': False, 'error': str(e)}), 401

@app.route('/auth/facebook', methods=['POST'])
def auth_facebook():
    data = request.get_json() or {}
    id_token = data.get('id_token')
    if not id_token:
        return jsonify({'success': False, 'error': 'Missing id_token'}), 400

    try:
        decoded = firebase_auth.verify_id_token(id_token)
        uid = decoded['uid']

        user_doc = db.collection('users').document(uid)
        user_doc.set({
            'email': decoded.get('email'),
            'displayName': decoded.get('name'),
            'photoURL': decoded.get('picture')
        }, merge=True)

        return jsonify({'success': True, 'uid': uid}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 401











@app.post("/internal/ws/notify")
def ws_notify():
    body = request.get_json(force=True) or {}
    uid = body.get("uid")
    msg = body.get("message")
    if uid and msg:
        manager.send_to_user(uid, msg)
        return {"ok": True}
    return {"ok": False, "error": "uid and message required"}, 400

# ------------------------
# RUN THE APP
# ------------------------

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
