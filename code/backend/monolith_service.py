from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

import os

import requests
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
from PIL import Image
import io
import faiss
import torch
from torchvision.models import efficientnet_b3, EfficientNet_B3_Weights

import random
import google.generativeai as genai

from functions.prediction_functions import crop_image_with_yolo, find_most_similar_image, get_link_with_id, get_by_url
from functions.recommandation_functions import get_user_preferences, get_artworks, get_previous_recommendations, get_user_collection, update
from functions.user_functions import get_artworks_by_ids, get_collection, get_artwork_by_id

#INITIALISATION DE FLASK

key = os.getenv("GEMINI_KEY")

genai.configure(api_key=key)

app = Flask(__name__)

cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)

db = firestore.client()


# SETUP DES IAs


device = torch.device("cpu")
model = efficientnet_b3(weights=EfficientNet_B3_Weights.IMAGENET1K_V1)
model.classifier = torch.nn.Identity()
model.eval()
model.to(device)



index = faiss.read_index("AI_tools/index_joconde2.faiss")
faiss.omp_set_num_threads(1)







#MUSEUM_FUNCTIONS


@app.route("/museums", methods=["GET"])
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

@app.route("/museums-in-bounds", methods=["GET"])
def get_museums_in_bounds():
    try:
        sw_lat = float(request.args.get("sw_lat"))
        sw_lng = float(request.args.get("sw_lng"))
        ne_lat = float(request.args.get("ne_lat"))
        ne_lng = float(request.args.get("ne_lng"))
        search = request.args.get('search', '').lower().strip()

        if not (-90 <= sw_lat <= 90 and -90 <= ne_lat <= 90 and -180 <= sw_lng <= 180 and -180 <= ne_lng <= 180):
            return jsonify({"error": "Invalid coordinates"}), 400

        museums_ref = db.collection('museums')
        museums = museums_ref.stream()

        museums_list = []
        for museum in museums:
            data = museum.to_dict()
            lat = data.get("location", {}).get("latitude")
            lng = data.get("location", {}).get("longitude")
            title = data.get("title", "").lower()
            city = data.get("city", "").lower()

            if lat is not None and lng is not None:
                # Check bounds
                in_bounds = sw_lat <= lat <= ne_lat and sw_lng <= lng <= ne_lng

                # Check search query presence in title or city
                matches_search = True  # Par défaut vrai si search vide
                if search:
                    matches_search = (search in title) or (search in city)

                if in_bounds and matches_search:
                    data['id'] = museum.id
                    museums_list.append(data)

        return jsonify(museums_list)
    except Exception as e:
        print(f"Error retrieving museums in bounds: {e}")
        return jsonify([]), 500


@app.route("/museums/<museum_id>/artworks", methods=["GET"])
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
    


# PREDICTION_SERVICE


@app.route('/prediction', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400
    try:
        file = request.files['file']
        with Image.open(io.BytesIO(file.read())) as image:
            if image.mode != 'RGB':
                image = image.convert('RGB')
            cropped_image = crop_image_with_yolo(image)
            result = find_most_similar_image(cropped_image, index, model, device)
            if result:
                artwork_link = get_link_with_id(result)
                artwork_data = get_by_url(artwork_link)
                return jsonify(artwork_data)
            return jsonify({"message": "Aucune correspondance trouvée"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

#QUIZZ_FUNCTIONS - NOT HERE ANYMORE MOUAHAHAH




#RECO_FUNCTIONS

@app.route("/users/<uid>/recommendations", methods=["PUT"])
def update_recommendations(uid):
    try:
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
        recommendations.extend([art["art"] for art in relevant_artworks[:2]])

        recommendationsid = [art["id"] for art in recommendations]
        
        new_artworks2 = [art for art in new_artworks if art["id"] not in recommendationsid]
        
        unexplored_movements = [movement for movement, score in user_preferences.items() if score <= 0.3]

        creative_artworks = [art for art in new_artworks2 if art["movement"] in unexplored_movements]

        if creative_artworks:
            creative_artwork = random.choice(creative_artworks)
            recommendations.append(creative_artwork)
        elif new_artworks2:
            random_artwork = random.choice(new_artworks2)
            recommendations.append(random_artwork)

        update(uid, previous_recommendations, recommendations)
        return {
            "success": True,
            "recommendations": [art["id"] for art in recommendations]
        }, 200
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }, 500


@app.route("/users/<uid>/recommendations", methods=["GET"])
def get_recommendations(uid):
    try:
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
                    artwork_data["id"] = artwork_id  
                    recommendations.append(artwork_data)

            # Répondre avec les recommandations
            return jsonify({"success": True, "data": recommendations})
        else:
            return jsonify({"success": False, "message": "Utilisateur non trouvé"}), 404
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    


#USER_FUNCTIONS



@app.route("/users/<uid>/artworks/<artworkId>", methods=["POST"])
def add_collection(uid, artworkId):
    doc_ref = db.collection('accounts').document(uid)
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
        return "Artwork added successfully", 200
    return f"Document for user {uid} does not exist.", 404

@app.route("/users/<uid>/like/<artworkId>", methods=["GET"])
def get_like_state(uid, artworkId):
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if doc.exists:
        data = doc.to_dict()
        brands = data.get('brands', [])
        
        if artworkId in brands:
            print("tableau liké")
            return jsonify({"result": True}), 200
    print("tableau non liké")
    return jsonify({"result": False}), 200

@app.route("/users/<uid>/like/<artworkId>", methods=["POST"])
def toggle_like(uid, artworkId):
    data = request.get_json()
    action = data.get("action")
    movement = data.get("movement")
    previous_profile = data.get("previous_profile", {})

    if action not in ["like", "dislike"]:
        return jsonify({"error": "Invalid action"}), 400

    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404

    user_data = doc.to_dict()
    current_likes = user_data.get("brands", [])

    updated = False
    if action == "like" and artworkId not in current_likes:
        current_likes.append(artworkId)
        updated = True
    elif action == "dislike" and artworkId in current_likes:
        current_likes.remove(artworkId)
        updated = True

    if updated:
        try:
            response = requests.post(
                "http://localhost:5002/profilage",
                json={
                    "uid": uid,
                    "action": action,
                    "movement": movement,
                    "previous_profile": previous_profile
                }
            )
            response.raise_for_status()
            new_profile = response.json().get("profile")
            doc_ref.update({
                "brands": current_likes,
                "preferences.movements": new_profile
            })
        except Exception as e:
            app.logger.error(f"Error calling profiling service: {e}")
            return jsonify({"error": "Profiling failed"}), 500

    return jsonify({"likes": current_likes}), 200

@app.route("/users/<uid>/collection", methods=["GET"])
def fetch_collection(uid):
    collection_ids = get_collection(uid)
    
    if collection_ids:
        print(f"Collection for UID {uid} contains {len(collection_ids)} artworks.")
        artworks = get_artworks_by_ids(collection_ids)
        return jsonify({"success": True, "data": artworks or []}), 200

    # Même si aucune œuvre ou aucune collection
    print(f"No collection found for UID {uid}.")
    return jsonify({"success": True, "data": []}), 200

@app.route("/users/<uid>/quests", methods=["PUT"])
def update_general_quest_progress(uid):
    data = request.get_json()
    movement = data.get("movement")

    doc_ref = db.collection('accounts').document(uid)
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

        if quest_data.get('movement') == movement or quest_data.get('movement') == "All":
            if quest_id in user_quests:
                user_quests[quest_id]['progression'] += 1  
            else:
                user_quests[quest_id] = {
                    'progression': 1,
                    'movement': quest_data.get('movement')
                }

    doc_ref.update({'quests': user_quests}) 
    return  200    
    
@app.route("/users/<uid>/quests", methods=["GET"])
def get_general_quests(uid):
    
    doc_ref = db.collection('accounts').document(uid)
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


@app.route("/users/<uid>/museum-quests", methods=["POST"])
def init_quest_museum(uid):
    
    artwork_ids = []

    data = request.get_json()
    museum_id = data.get("museum_id")
    
    doc_ref = db.collection('accounts').document(uid)
    user_db =doc_ref.get()

    if user_db.exists:
        user_data = user_db.to_dict()
        liste_recommendations = user_data.get('reco', [])
        quete_museum = user_data.get('quete_museum', [])
        collection_user= user_data.get('collection', [])
        quest = next((q for q in quete_museum if q.get("id") == museum_id), None)
        
        if quest:
            artworks = quest.get("artworks", [])
            if not artworks:
                print(f"Aucune œuvre à valider pour le musée {museum_id}.")
                return '', 204
            else:
                print("Artwork to validate :", artworks[0])
                artwork= get_artwork_by_id(artworks[0])
                print(artwork)
                #return artwork
                return jsonify({"image_url": artwork.get("image_url")}), 200
        
        else :
            for reco in liste_recommendations:
                print("Reco :", reco)
        
        
            liste_artworks_museum = firestore.client().collection('artworks').where('id_museum', '==', museum_id).get()
            liste_artworks = [doc for doc in liste_artworks_museum if doc.id not in collection_user]

            
            if liste_artworks:
                artwork_ids = [doc.id for doc in liste_artworks]
            else:
                print(" Aucun artwork trouvé pour le musée :", museum_id)
                return '', 204

            random.shuffle(artwork_ids)
            artwork_ids.sort(key=lambda doc_id: 0 if doc_id in liste_recommendations else 1)
            nouvelle_quete = {
                "id": museum_id,
                "artworks": artwork_ids
            }

            quete_museum = [q for q in quete_museum if q.get("id") != museum_id]
            quete_museum.append(nouvelle_quete)

            doc_ref.set({
                "quete_museum": quete_museum
            }, merge=True)
            print(artwork_ids[0]) 
            artwork= get_artwork_by_id(artwork_ids[0])
            print(artwork)
            #return artwork
            return jsonify({"image_url": artwork.get("image_url")}), 200
            
    else:
        print(f" Le document avec l'UID '{uid}' n'existe pas dans 'accounts'.")


@app.route("/users/<uid>/museum-quests", methods=["PUT"])
def update_quest_museum(uid): 
    
    data= request.get_json()
    artworkId = data.get("artworkId")
    museum_id = data.get("museum_id")

    
    doc_ref = firestore.client().collection('accounts').document(uid)
    user_db = doc_ref.get()
    
    if user_db.exists:
        user_data = user_db.to_dict()
        quete_museum = user_data.get('quete_museum', [])

        if not quete_museum:
            print("Pas de quêtes en cours.")
            return 0
        quest = next((q for q in quete_museum if q.get("id") == museum_id), None)
        if not quest:
            print(f"Aucune quête trouvée pour le musée {museum_id}.")
            return 0

        artworks = quest.get("artworks", [])
        if not artworks:
            print(f"Aucune œuvre à valider pour le musée {museum_id}.")
            return 0

        if artworkId == artworks[0]:
            artworks.pop(0)

            updated_quete_museum = [
                {**q, "artworks": artworks} if q.get("id") == museum_id else q
                for q in quete_museum
            ]
            doc_ref.set({"quete_museum": updated_quete_museum}, merge=True)

            print("Œuvre validée, quête mise à jour.")
            return 1
        else:
            print("Ce n'est pas la bonne œuvre à valider.")
            return 0
    else:
        print("Utilisateur introuvable.")
        return 0

@app.route("/users/<uid>/profile", methods=["PUT"])
def update_profile(uid):
    try:
        # Récupérer les données JSON envoyées dans la requête
        data = request.get_json()
        movements = data.get("movements", {})
        artwork_id = data.get("liked_artworks")
        action = data.get("action")
        print(f"artwork id : {artwork_id}")
        
        if not isinstance(movements, dict):  # On vérifie que 'movements' est un dictionnaire
            return jsonify({"error": "Invalid profile format. 'movements' should be a dictionary."}), 400

        # Accès à la collection Firestore
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if not doc.exists:
            app.logger.error(f"User with UID {uid} not found.")
            return jsonify({"error": "User not found"}), 404

        current_data = doc.to_dict()
        current_likes = current_data.get("brands", [])

        if action == "like":

            if artwork_id not in current_likes:
                current_likes.append(artwork_id)
        
        if action == "dislike":

            if artwork_id in current_likes:
                current_likes.remove(artwork_id)
                print("TABLEAU SUPPR")

        doc_ref.update({
            "preferences.movements": movements,
            "brands": current_likes
        })
        
        updated_doc = doc_ref.get()
        updated_data = updated_doc.to_dict()

        return jsonify({
            "uid": uid,
            "movements": updated_data.get('preferences', {}).get('movements', {}),
            "message": "Profile updated successfully."
        }), 200
    except Exception as e:
        app.logger.error(f"Error updating profile for {uid}: {str(e)}")
        return jsonify({
            "uid": uid,
            "error": f"An error occurred while updating the profile: {str(e)}"
        }), 500
    

@app.route("/users/<uid>", methods=["GET"])
def get_user(uid):
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if doc.exists:
        user_data = doc.to_dict()
        user_data['uid'] = uid
        return jsonify({"success": True, "user": user_data}), 200
    return jsonify({"success": False, "error": f"User {uid} not found"}), 404
    


@app.route("/profiling/artworks", methods=["GET"])
def get_5_artworks():
    
    ids = [str(random.randint(0, 40000)) for _ in range(5)]
    artworks = get_artworks_by_ids(ids)

    if artworks:
        return jsonify({"success": True, "data": artworks})
    else:
        return jsonify({"success": False, "message": "Artworks pas générés"}), 404
    



    
    




if __name__ == "__main__":
    app.run(debug=True, port=5001)