import firebase_admin
import random
from flask import Flask, jsonify
from firebase_admin import credentials, firestore


app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

@app.route("/api/fetch_col/<uid>", methods=["GET"])
def fetch_collection(uid):
    
    collection_id = get_collection(uid)
    
    if collection_id:
        print(f"Collection for UID {uid} already exists.")
        artworks = get_artworks()
        collection_user = []
        if artworks:
            collection_user = [art for art in artworks if art["id"] in collection_id]
            return jsonify({"success": True, "data": collection_user})
        else:
            print("No matching artworks found in Firestore.")



def get_artworks():
    try:
        db = firestore.client()
        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.stream()  # Récupère tous les documents de la collection

        result = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id  # Inclure l'ID du document si nécessaire
            result.append(artwork_data)
        print(f"Successfully retrieved {len(result)} artworks.")
        return result
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return []

def get_collection(uid):
    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('collection', [])
            
            print(f"Collection IDs for user {uid}: {collection}")  # Debug

            if isinstance(collection, list):
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving collection for UID {uid}: {e}", file=sys.stderr)
        return []



if __name__ == "__main__":
    app.run(debug=True, port=5005)