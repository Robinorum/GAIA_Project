import json
import random
from flask import Flask, jsonify
from common import initialize_firebase
from firebase_admin import firestore


app = Flask(__name__)
initialize_firebase()

db = firestore.client()

def get_user_preferences(uid):
    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            movements = data.get('preferences', {}).get('movements', {})
            for movement, score in movements.items():
                print(f"User {uid} likes {movement} with score {score}")
            return movements  # Retourne un dictionnaire des mouvements et scores
        else:
            print(f"Document for UID {uid} does not exist.")
            return {}
    except Exception as e:
        print(f"Error retrieving user preferences for UID {uid}: {e}")
        return {}

    
def get_previous_recommendations(uid):

    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('previous_reco', [])
            if isinstance(collection, list):
                print(f"Previous recommendations for user {uid}: {collection}")
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []

def get_user_collection(uid):
    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('collection', [])
            if isinstance(collection, list):
                print(f"collection for user {uid}: {collection}")
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []


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


def update(uid, previous_recommendations, new_recommendations):

    # Ajouter les nouvelles recommandations aux anciennes
    updated_reco = previous_recommendations[-2:] + [art['id'] for art in new_recommendations]
    
    
    # Limiter à un nombre raisonnable de recommandations (par exemple 20)
    # plus tard on mettra 20 
    
    # Mettre à jour Firestore avec les nouvelles recommandations
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    
    return updated_reco

@app.route("/api/recom_maj/", methods=["POST"])
def maj_recommendation(uid):
    
    user_preferences = get_user_preferences(uid)
    previous_recommendations = get_previous_recommendations(uid)
    user_collection = get_user_collection(uid)
    artworks = get_artworks()

    new_artworks = [art for art in artworks if art["id"] not in previous_recommendations and art["id"] not in user_collection]
    
    
    scored_artworks = []
    for art in new_artworks:
        style = art["movement"]  
        score = user_preferences.get(style, 0) 
        scored_artworks.append({"art": art, "score": score})
     

    recommendations = []

    relevant_artworks = sorted(scored_artworks, key=lambda x: x["score"], reverse=True)
    recommendations.extend([art["art"] for art in relevant_artworks[:2]])  # 2 œuvres pertinentes
    print("new_artworks")
    for art in new_artworks:
        print(art["id"])
    
    print("Recommandations pertinentes")
    for art in recommendations:
        print(art["id"])

    recommendationsid = [art["id"] for art in recommendations]  # Liste des IDs des recommandations
    
    new_artworks2 = [art for art in new_artworks if art["id"] not in recommendationsid]
    
    # Recommandations créatives (exploration de nouveaux styles)
    unexplored_movements = [movement for movement, score in user_preferences.items() if score <= 0.3]
    print("Mouvements peu explorés")
    for movement in unexplored_movements:
        print(movement)
    for art in new_artworks2:
        print(art["movement"])
    creative_artworks = [art for art in new_artworks2 if art["movement"] in unexplored_movements]
    if creative_artworks:
        recommendations.append(random.choice(creative_artworks))  # 1 œuvre aléatoire d'un mouvement peu exploré

    print("new_artworks2")
    for art in new_artworks2:  
        print(art["id"])

    print("Recommandations all")
    for art in recommendations:
        print(art["id"])
        

    update(uid, previous_recommendations, recommendations)

    return 0

@app.route("/api/recom_get/<uid>", methods=["GET"])
def get_recommendations(uid):
    try:
        # Connexion à Firestore
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        # Vérifier si le document existe
        if doc.exists:
            print("User found:", doc.to_dict())

            data = doc.to_dict()
            collection = data.get('reco', [])
            print("Recommendations:", collection)

            # Charger les recommandations en fonction des préférences
            recommendations = []

            for artwork_id in collection:
                # Charger l'œuvre d'art à partir de la base de données (supposons qu'il existe une collection "artworks")
                artwork_ref = db.collection('artworks').document(artwork_id)
                artwork_doc = artwork_ref.get()

                if artwork_doc.exists:
                    artwork_data = artwork_doc.to_dict()
                    recommendations.append(artwork_data)

            # Répondre avec les recommandations
            return jsonify({"success": True, "data": recommendations})
        else:
            return jsonify({"success": False, "message": "Utilisateur non trouvé"}), 404
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route("/api/artworks", methods=["GET"])
def get_artworks():
    # Connexion à Firestore
    db = firestore.client()

    # Récupérer toutes les œuvres d'art depuis la collection 'artworks'
    artworks_ref = db.collection('artworks')
    artworks = artworks_ref.stream()

    # Préparer une liste des artworks
    artworks_list = []
    for artwork in artworks:
        artwork_data = artwork.to_dict()
        artwork_data['id'] = artwork.id  # Ajouter l'ID de l'œuvre d'art

        artworks_list.append(artwork_data)

    return jsonify({"success": True, "data": artworks_list})

if __name__ == "__main__":
    app.run(debug=True, port=5003)
