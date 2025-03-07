import firebase_admin
from flask import Flask, jsonify
from firebase_admin import credentials, firestore


app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

db = firestore.client()


@app.route("/api/add_artwork/<userId>/<artworkId>", methods=["GET"])
def add_brand_byId(userId, artworkId):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(userId)
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        if 'collection' in data:
            collection = data['collection']
            if artworkId in collection:
                return "Already in collection", 200
            else:
                collection.append(artworkId)
            doc_ref.update({'collection': collection})
        else:
            doc_ref.update({'collection': [collection]})
        return "Artwork liked successfully", 200
    return f"Document for user {userId} does not exist.", 404

@app.route("/api/state_brand/<userId>/<artworkId>", methods=["GET"])
def state_brand_byId(userId, artworkId):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(userId)
    doc = doc_ref.get()    
    if doc.exists:
        data = doc.to_dict()
        brands = data.get('brands', [])
        
        if artworkId in brands:
            print("tableau liké")
            return jsonify({"result": True}), 200
    print("tableau non liké")
    return jsonify({"result": False}), 200


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
        artworks = artworks_ref.stream() 

        result = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id  
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
        return []



if __name__ == "__main__":
    app.run(debug=True, port=5005)