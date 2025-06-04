# app.py

from flask import Flask, jsonify, request
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from models import Order, Carrier, Business
from auth import require_token

app = Flask(__name__)
CORS(app)  # allow cross‐origin requests (useful during development)

# 1. Initialize Firebase Admin SDK
cred = credentials.Certificate('firebase_admin.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

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
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        # Expected fields in JSON: role (required), displayName (optional), phone (optional)
        role = data.get('role')
        display_name = data.get('displayName')
        phone = data.get('phone')

        if role not in ('business', 'courier'):
            return jsonify({'success': False, 'error': 'Invalid or missing role'}), 400

        # Get the authenticated user's UID:
        uid = request.uid
        #uid = 'TEST_UID'   # same dummy ID
        # Also you can grab email from token if you like: decoded token’s "email"
        # But for simplicity, let’s store whatever Flutter passes:
        email = data.get('email')  # optional

        user_doc_ref = db.collection('users').document(uid)
        # Check if profile already exists
        if user_doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'Profile already exists'}), 400

        # Build the profile dict
        profile = {
            'role': role,
        }
        if display_name:
            profile['displayName'] = display_name
        if email:
            profile['email'] = email
        if phone:
            profile['phone'] = phone

        # Save to Firestore
        user_doc_ref.set(profile)

        return jsonify({'success': True}), 201

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/getUserProfile', methods=['GET'])
@require_token
def get_user_profile():
    try:
        uid = request.uid
        #uid = 'TEST_UID'   # same dummy ID

        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            return jsonify({'success': False, 'error': 'Profile not found'}), 404

        data = user_doc.to_dict()
        # Always include the uid so client knows who it is
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
       # uid = 'TEST_UID'   # same dummy ID
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
        # You can also allow updating email if you like:
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

@app.route('/getOrders', methods=['GET'])
@require_token
def get_orders():
    try:
        orders_ref = db.collection('orders')
        docs = orders_ref.stream()

        orders_list = []
        for doc in docs:
            o = Order.from_dict(doc.to_dict(), doc.id)
            orders_list.append({'id': o.id, **o.to_dict()})

        return jsonify({'success': True, 'orders': orders_list}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/getOrder/<order_id>', methods=['GET'])
@require_token
def get_order(order_id):
    try:
        doc_ref = db.collection('orders').document(order_id)
        doc = doc_ref.get()
        if not doc.exists:
            return jsonify({'success': False, 'error': 'Order not found'}), 404

        o = Order.from_dict(doc.to_dict(), doc.id)
        return jsonify({'success': True, 'order': {'id': o.id, **o.to_dict()}}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/createOrder', methods=['POST'])
@require_token
def create_order():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        # Required fields: customer (str), items (list)
        customer = data.get('customer')
        items = data.get('items')
        status = data.get('status', 'pending')
        carrier_id = data.get('carrier_id')
        business_id = data.get('business_id')

        if not customer or items is None:
            return jsonify({'success': False, 'error': 'Missing required fields'}), 400

        new_order = Order(
            customer = customer,
            items = items,
            status = status,
            carrier_id = carrier_id,
            business_id = business_id
        )
        _, doc_ref = db.collection('orders').add(new_order.to_dict())
        return jsonify({'success': True, 'order_id': doc_ref.id}), 201

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/updateOrder/<order_id>', methods=['PUT'])
@require_token
def update_order(order_id):
    try:
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        doc_ref = db.collection('orders').document(order_id)
        snapshot = doc_ref.get()
        if not snapshot.exists:
            return jsonify({'success': False, 'error': 'Order not found'}), 404

        updates = {}
        if 'customer' in data:
            updates['customer'] = data['customer']
        if 'items' in data:
            updates['items'] = data['items']
        if 'status' in data:
            updates['status'] = data['status']
        if 'carrier_id' in data:
            updates['carrier_id'] = data['carrier_id']
        if 'business_id' in data:
            updates['business_id'] = data['business_id']

        if not updates:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        doc_ref.update(updates)
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/deleteOrder/<order_id>', methods=['DELETE'])
@require_token
def delete_order(order_id):
    try:
        doc_ref = db.collection('orders').document(order_id)
        if not doc_ref.get().exists:
            return jsonify({'success': False, 'error': 'Order not found'}), 404

        doc_ref.delete()
        return jsonify({'success': True}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


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


# ------------------------
# RUN THE APP
# ------------------------

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
