# app.py

from flask import Flask, jsonify, request
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from models import Order, Carrier, Business

app = Flask(__name__)
CORS(app)  # allow cross‐origin requests (useful during development)

# 1. Initialize Firebase Admin SDK
cred = credentials.Certificate('firebase_admin.json')
firebase_admin.initialize_app(cred)
db = firestore.client()


# ------------------------
# ORDERS ENDPOINTS
# ------------------------

@app.route('/getOrders', methods=['GET'])
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
