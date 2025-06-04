# auth.py

from functools import wraps
from flask import request, jsonify
from firebase_admin import auth

def require_token(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        # Expect header "Authorization: Bearer <Firebase_ID_Token>"
        id_token = request.headers.get("Authorization", "").replace("Bearer ", "")
        if not id_token:
            return jsonify({"success": False, "error": "Missing Authorization token"}), 401

        try:
            # Verify the Firebase ID token and set request.uid = the user’s UID
            decoded = auth.verify_id_token(id_token)
            request.uid = decoded.get("uid")
        except Exception:
            return jsonify({"success": False, "error": "Invalid or expired token"}), 401

        return f(*args, **kwargs)
    return wrapper
