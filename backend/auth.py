# auth.py

from functools import wraps
from flask import request, jsonify
from firebase_init import firebase_auth  # your initialized Admin SDK

def require_token(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        # 1) Extract and validate the Authorization header
        auth_header = request.headers.get("Authorization", None)
        if not auth_header:
            return jsonify(success=False, error="Missing Authorization header"), 401

        parts = auth_header.split()
        if parts[0].lower() != "bearer" or len(parts) != 2:
            return jsonify(success=False, error="Malformed Authorization header"), 401

        id_token = parts[1]

        # 2) Verify the Firebase ID token
        try:
            decoded = firebase_auth.verify_id_token(id_token)
        except firebase_auth.ExpiredIdTokenError:
            return jsonify(success=False, error="Token expired"), 401
        except firebase_auth.InvalidIdTokenError:
            return jsonify(success=False, error="Invalid token"), 401
        except Exception as e:
            return jsonify(success=False, error=f"Token verification failed: {e}"), 401

        # 3) Inject the UID for downstream use
        request.uid = decoded.get("uid")

        # 4) Call the protected route
        return f(*args, **kwargs)

    return wrapper
