import firebase_admin
from flask import Flask, jsonify
from firebase_admin import credentials, firestore


app = Flask(__name__)
cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
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


@app.route("/api/maj_quest/<userId>/<artworkMovement>", methods=["GET"])
def maj_quest_byId(userId, artworkMovement):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(userId)
    doc = doc_ref.get()
    
    if not doc.exists:
        return {"error": "Utilisateur non trouvé"}, 404
    
    user_data = doc.to_dict()
    
    user_quests = user_data.get('quests', {})  
    if not isinstance(user_quests, dict):  
        user_quests = {}  # Correction si c'est mal initialisé
    
    quests_data = db.collection('quests').get()
    
    for quest in quests_data:
        quest_data = quest.to_dict()
        quest_id = quest.id  

        if quest_data.get('movement') == artworkMovement or quest_data.get('movement') == "All":
            if quest_id in user_quests:
                user_quests[quest_id]['progression'] += 1  
            else:
                user_quests[quest_id] = {
                    'progression': 1,
                    'movement': quest_data.get('movement')
                }

    doc_ref.update({'quests': user_quests}) 
    return  200    
    
@app.route("/api/get_quest/<userId>", methods=["GET"])
def get_quests(userId):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(userId)
    doc = doc_ref.get()
    
    if not doc.exists:
        return {"error": "Utilisateur non trouvé"}, 404
    
    user_data = doc.to_dict()
    user_quests = user_data.get('quests', {})  
    
    if not isinstance(user_quests, dict):  
        user_quests = {}  # Correction si c'est mal initialisé
    
    # Extraire uniquement quest_id et progression
    filtered_quests = [{"id": quest_id, "progression": data.get("progression", 0)} for quest_id, data in user_quests.items()]
    print(filtered_quests)
    return {"quests": filtered_quests}, 200


  # if doc.exists:
    #     data = doc.to_dict()
    #     if 'quests' in data:
    #         quests = data['quests']
    #         if artworkMovement in quests:
    #             quests[artworkMovement] += 1
    #         else:
    #             quests[artworkMovement] = 1
    #     else:
    #         quests = {artworkMovement: 1}
        
    #     doc_ref.update({'quests': quests})
    #     return "Quest updated successfully", 200

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