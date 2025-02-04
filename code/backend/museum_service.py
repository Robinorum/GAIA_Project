from flask import Flask, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

@app.route("/api/museums", methods=["GET"])
def get_museums():
    try:
        museums_ref = db.collection('museums')
        museums = museums_ref.stream()
        
        museums_list = []
        for museum in museums:
            museum_data = museum.to_dict()
            museum_data['id'] = museum.id  # Ajouter l'ID du document
            museums_list.append(museum_data)
        
        return jsonify(museums_list)  
    except Exception as e:
        print(f"Error retrieving museums: {e}")
        return jsonify([])

@app.route("/api/museums/<museum_id>/artworks", methods=["GET"])
def get_artworks_by_museum(museum_id):
    try:
        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.where("id_museum", "==", museum_id).stream()

        artworks_list = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id  # Ajouter l'ID du document
            artworks_list.append(artwork_data)

        print(f"Artworks list: {artworks_list}")

        return jsonify(artworks_list)
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return jsonify([])

if __name__ == "__main__":
    app.run(debug=True, port=5004)
