from flask import Flask, request, jsonify
import requests

import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase Admin with the service account
cred = credentials.Certificate("logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json")
firebase_admin.initialize_app(cred)

app = Flask(__name__)

MICROSERVICES = {
    "scan": "http://localhost:5001",
    "profiling": "http://localhost:5002",
    "reco": "http://localhost:5003",
    "museum": "http://localhost:5004",
    #"artwork": "http://localhost:5005",
}

def verify_firebase_jwt(token):
    try:
        # Verify the Firebase ID token using the Firebase Admin SDK
        decoded_token = auth.verify_id_token(token)
        return decoded_token  # Returns the decoded token if valid
    except auth.InvalidIdTokenError:
        return None

@app.route('/<service>/<path:endpoint>', methods=["GET", "POST", "PUT", "DELETE"])
def proxy(service, endpoint):
    if service not in MICROSERVICES:
        return jsonify({"error": f"Service {service} not found"}), 404

    # Check for Authorization header
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Missing or invalid JWT token"}), 401

    token = auth_header.split(" ")[1]
    decoded_token = verify_firebase_jwt(token)
    if not decoded_token:
        return jsonify({"error": "Invalid JWT token"}), 401

    # Forward the request to the target microservice
    target_url = f"{MICROSERVICES[service]}/{endpoint}"
    try:
        response = requests.request(
            method=request.method,
            url=target_url,
            headers={key: value for key, value in request.headers.items() if key != "Host"},
            data=request.get_data(),
            params=request.args,
        )
        return (response.content, response.status_code, response.headers.items())
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Error communicating with {service}: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
