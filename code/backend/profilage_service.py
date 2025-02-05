from flask import Flask, request, jsonify
from collections import Counter
from firebase_admin import firestore, credentials
import firebase_admin

app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

@app.route("/api/profilage/", methods=["POST"])
def modify_brands_by_id():
    data = request.get_json()
    
    if 'artworkId' not in data or 'uid' not in data:
        return "Missing artworkId or uid", 400 

    artworkId = data['artworkId']
    uid = data['uid']
    
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        if 'brands' in data:
            brands = data['brands']
            if artworkId in brands:
                brands.remove(artworkId)
            else:
                brands.append(artworkId)
            doc_ref.update({'brands': brands})
        else:
            doc_ref.update({'brands': [artworkId]})
        profilage(uid)
    else:
        return f"Le document pour l'utilisateur {uid} n'existe pas.", 404
    return "Brands updated successfully", 200


def get_all_movements():
    db = firestore.client()
    artworks_ref = db.collection('artworks')
    artworks = artworks_ref.stream()

    movements = []
    for artwork in artworks:
        artwork_data = artwork.to_dict()
        if 'movement' in artwork_data:
            movements.append(artwork_data['movement'])
    
    return movements
        
def profilage(uid):
    db = firestore.client()

    # Récupérer tous les mouvements et les initialiser à 0
    all_movements = get_all_movements()
    initial_movements = {movement: 0.0 for movement in all_movements}

    # Référence au document utilisateur
    doc_ref = db.collection('accounts').document(uid)
    
    # Vérifier si le document existe
    doc = doc_ref.get()

    if doc.exists:
        data = doc.to_dict()

        if 'brands' in data:
            brands = data['brands']
            movements = []

            # Récupérer les mouvements des tableaux aimés
            for brand in brands:
                artwork = get_artwork_by_id(brand)
                if artwork and "movement" in artwork:
                    movements.append(artwork["movement"])

            # Calculer les ratios pour les mouvements aimés
            movement_counts = Counter(movements)
            total_movements = len(movements)
            liked_ratios = {movement: count / total_movements for movement, count in movement_counts.items()}

            # Fusionner avec les mouvements initialisés à 0
            updated_movements = initial_movements.copy()
            updated_movements.update(liked_ratios)

            # Mettre à jour les préférences dans Firestore
            doc_ref.update({'preferences.movements': updated_movements})
            print(f"Updated movements for user {uid}: {updated_movements}")
        else:
            print(f"No brands found for user {uid}")
    else:
        # Si le document n'existe pas, initialiser les mouvements
        doc_ref.set({'preferences': {'movements': initial_movements}}, merge=True)
        print(f"Initialized movements for new user {uid}: {initial_movements}")


@app.route("/api/artworks/<artwork_id>", methods=["GET"])
def get_artwork_by_id(artwork_id):
    db = firestore.client()

    artwork_ref = db.collection('artworks').document(artwork_id)
    artwork = artwork_ref.get()

    if artwork.exists:
        artwork_data = artwork.to_dict()
        artwork_data['id'] = artwork.id
        return artwork_data
    
@app.route("/api/artworks/", methods=["GET"])
def get_all_artworks():
    db = firestore.client()

    artworks_ref = db.collection('artworks')
    artworks = artworks_ref.stream()

    all_artworks = []
    for artwork in artworks:
        artwork_data = artwork.to_dict()
        artwork_data['id'] = artwork.id
        all_artworks.append(artwork_data)

    return jsonify({"success": True, "data": all_artworks})


@app.route("/api/top_brands/<uid>", methods=["GET"])
def top_brands(uid):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        if 'preferences' in data and 'movements' in data['preferences']:
            movements = data['preferences']['movements']                
            filtered_movements = {movement: score for movement, score in movements.items() if isinstance(score, (int, float)) and score > 0}
            sorted_movements = sorted(filtered_movements.items(), key=lambda x: x[1], reverse=True)
            top_3_movements = [movement for movement, score in sorted_movements[:3]]
            
            return jsonify({"top_movements": top_3_movements}), 200
        
        else:
            return jsonify({"message": "No movements data available."}), 404
    else:
        return jsonify({"error": "User document not found."}), 404


if __name__ == "__main__":
    app.run(debug=True, port=5002)
