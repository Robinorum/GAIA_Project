from multiprocessing import Process
import secrets
from flask import Flask, json, request, jsonify
import firebase_admin
from firebase_admin import auth, credentials, firestore

import os

import pika
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
from functions.recommandation_functions import get_user_preferences, get_all_artworks_from_cache, get_previous_recommendations, get_user_collection, update
from functions.user_functions import get_artworks_by_ids, get_collection, get_artwork_by_id

import redis

#INITIALISATION DE FLASK

key = os.getenv("GEMINI_KEY")

genai.configure(api_key=key)

app = Flask(__name__)
r = redis.Redis(host='localhost', port=6379, decode_responses=True)
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
        cached_museums = r.get("museums_cache")
        if cached_museums:
            print("Récupéré depuis le cache Redis.")
            return jsonify(json.loads(cached_museums))

        museums_ref = db.collection('museums')
        museums = museums_ref.stream()
        
        museums_list = []
        for museum in museums:
            museum_data = museum.to_dict()
            museum_data['id'] = museum.id
            museums_list.append(museum_data)
        
        r.set("museums_cache", json.dumps(museums_list), ex=3600)

        print("Récupéré depuis Firestore et mis en cache.")
        return jsonify(museums_list)

    except Exception as e:
        print(f"Error retrieving museums: {e}")
        return jsonify([])
# @app.route("/museums-in-bounds", methods=["GET"])
# def get_museums_in_bounds():
#     try:
#         sw_lat = float(request.args.get("sw_lat"))
#         sw_lng = float(request.args.get("sw_lng"))
#         ne_lat = float(request.args.get("ne_lat"))
#         ne_lng = float(request.args.get("ne_lng"))
#         search = request.args.get('search', '').lower().strip()

#         if not (-90 <= sw_lat <= 90 and -90 <= ne_lat <= 90 and -180 <= sw_lng <= 180 and -180 <= ne_lng <= 180):
#             return jsonify({"error": "Invalid coordinates"}), 400

#         museums_ref = db.collection('museums')
#         museums = museums_ref.stream()

#         museums_list = []
#         for museum in museums:
#             data = museum.to_dict()
#             lat = data.get("location", {}).get("latitude")
#             lng = data.get("location", {}).get("longitude")
#             title = data.get("title", "").lower()
#             city = data.get("city", "").lower()

#             if lat is not None and lng is not None:
#                 # Check bounds
#                 in_bounds = sw_lat <= lat <= ne_lat and sw_lng <= lng <= ne_lng

#                 # Check search query presence in title or city
#                 matches_search = True  # Par défaut vrai si search vide
#                 if search:
#                     matches_search = (search in title) or (search in city)

#                 if in_bounds and matches_search:
#                     data['id'] = museum.id
#                     museums_list.append(data)

#         return jsonify(museums_list)
#     except Exception as e:
#         print(f"Error retrieving museums in bounds: {e}")
#         return jsonify([]), 500


@app.route("/museums/<museum_id>/artworks", methods=["GET"])
def get_artworks_by_museum(museum_id):
    try:
        cache_key = f"artworks_cache:{museum_id}"
        cached_artworks = r.get(cache_key)

        if cached_artworks:
            print(f"Artworks du musée {museum_id} récupérés depuis le cache Redis.")
            return jsonify(json.loads(cached_artworks))

        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.where("id_museum", "==", museum_id).stream()

        artworks_list = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id
            artworks_list.append(artwork_data)

        r.set(cache_key, json.dumps(artworks_list), ex=3600)

        print(f"Artworks du musée {museum_id} récupérés depuis Firestore et mis en cache.")
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
        user_preferences = get_user_preferences(uid, db)
        previous_recommendations = get_previous_recommendations(uid, db)
        user_collection = get_user_collection(uid, db)
        artworks = get_all_artworks_from_cache(db)

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
            creative_artwork = secrets.choice(creative_artworks)
            # creative_artwork = random.choice(creative_artworks)
            recommendations.append(creative_artwork)
        elif new_artworks2:
            random_artwork = secrets.choice(new_artworks2)
            # random_artwork = random.choice(new_artworks2)
            recommendations.append(random_artwork)

        update(uid, previous_recommendations, recommendations, db)
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
@app.route("/users/<uid>/username", methods=["PUT"])
def update_user_username(uid):
    try:
        data = request.get_json()
        new_username = data.get("username")

        if not new_username:
            return jsonify({"error": "Le nom d'utilisateur est requis."}), 400

        user_ref = db.collection("accounts").document(uid)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return jsonify({"error": f"Utilisateur {uid} introuvable dans Firestore."}), 404

        user_ref.update({"username": new_username})

        return jsonify({"message": "Nom d'utilisateur mis à jour avec succès."}), 200

    except Exception as e:
        return jsonify({"error": f"Erreur lors de la mise à jour : {str(e)}"}), 500

@app.route('/users/<uid>/email', methods=['PUT'])
def update_user_email(uid):
    try:
        data = request.get_json()
        new_email = data.get('email')

        if not new_email:
            return jsonify({"error": "Email is required"}), 400

        auth.update_user(uid, email=new_email)

        user_ref = db.collection("accounts").document(uid)
        if user_ref.get().exists:
            user_ref.update({"email": new_email})
        else:
            return jsonify({"error": f"User {uid} not found in Firestore"}), 404

        return jsonify({"message": "Email updated successfully"}), 200

    except auth.EmailAlreadyExistsError:
        return jsonify({"error": "Email already in use"}), 400
    except auth.UserNotFoundError:
        return jsonify({"error": f"User {uid} not found in Firebase"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/users/<uid>/password", methods=["PUT"])
def update_user_password(uid):
    data = request.get_json()
    new_password = data.get("new_password")

    # Password requirements:
    # - At least 14 characters
    # - At least one uppercase letter
    # - At least one lowercase letter
    # - At least one digit
    # - At least one special character (@$!%*?&)
    if (
        not new_password
        or len(new_password) < 14
        or not any(c.isupper() for c in new_password)
        or not any(c.islower() for c in new_password)
        or not any(c.isdigit() for c in new_password)
        or not any(c in "@$!%*?&" for c in new_password)
    ):
        return jsonify({"error": "Le mot de passe ne respecte pas les exigences (14 caractères, majuscule, minuscule, chiffre, caractère spécial)."}), 400

    try:
        auth.update_user(uid, password=new_password)

        # db.collection("accounts").document(uid).update({
        #     "password_changed_at": firestore.SERVER_TIMESTAMP
        # })

        return jsonify({"message": "Mot de passe mis à jour avec succès."}), 200
    except auth.UserNotFoundError:
        return jsonify({"error": "Utilisateur introuvable."}), 404
    except Exception as e:
        return jsonify({"error": f"Erreur lors de la mise à jour : {str(e)}"}), 500


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

@app.route("/users/<uid>/liked-artworks", methods=["GET"])
def get_liked_artworks(uid):
    try:
        account_doc = db.collection("accounts").document(uid).get()
        if not account_doc.exists:
            return jsonify([]), 404
        
        account_data = account_doc.to_dict()
        liked_ids = account_data.get("brands", [])
        if not liked_ids:
            return jsonify([])

        artworks_list = []
        for art_id in liked_ids:
            artwork_doc = db.collection("artworks").document(art_id).get()
            if artwork_doc.exists:
                artwork_data = artwork_doc.to_dict()
                artwork_data['id'] = artwork_doc.id
                artworks_list.append(artwork_data)

        return jsonify(artworks_list)

    except Exception as e:
        print(f"Error retrieving brands artworks for user {uid}: {e}")
        return jsonify([]), 500

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

@app.route("/users/<uid>/top-movements", methods=["GET"])
def top_brands(uid):
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

@app.route("/users/<uid>/like/<artworkId>", methods=["POST"])
def toggle_like(uid, artworkId):
    data = request.get_json()
    action = data.get("action")
    movement = data.get("movement")

    if action not in ["like", "dislike"]:
        return jsonify({"error": "Invalid action"}), 400

    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404

    user_data = doc.to_dict()
    current_likes = user_data.get("brands", [])
    previous_profile = user_data.get("preferences", {}).get("movements", {})
    updated = False
    if action == "like" and artworkId not in current_likes:
        current_likes.append(artworkId)
        updated = True
    elif action == "dislike" and artworkId in current_likes:
        current_likes.remove(artworkId)
        updated = True

    if updated:
        doc_ref.update({"brands": current_likes})
        publish_profiling_message(uid, action, movement, previous_profile)
        # try:
        #     response = requests.post(
        #         "http://localhost:5002/profilage",
        #         json={
        #             "uid": uid,
        #             "action": action,
        #             "movement": movement,
        #             "previous_profile": previous_profile
        #         },
        #         timeout=5
        #     )
        #     response.raise_for_status()
        #     new_profile = response.json().get("profile")
        #     doc_ref.update({
        #         "brands": current_likes,
        #         "preferences.movements": new_profile
        #     })
        # except Exception as e:
        #     app.logger.error(f"Error calling profiling service: {e}")
        #     return jsonify({"error": "Profiling failed"}), 500

    return jsonify({"likes": current_likes}), 200

def publish_profiling_message(uid, action, movement, previous_profile):
    message = {
        "uid": uid,
        "action": action,
        "movement": movement,
        "previous_profile": previous_profile
    }

    connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
    channel = connection.channel()
    channel.queue_declare(queue='profiling_requested')
    channel.basic_publish(exchange='', routing_key='profiling_requested', body=json.dumps(message))
    connection.close()


def handle_profiling_completed(ch, method, properties, body):
    data = json.loads(body)
    uid = data["uid"]
    profile = data["new_profile"]

    db.collection("accounts").document(uid).update({
        "preferences.movements": profile
    })

    print(f"[✔] Profil mis à jour pour {uid}")

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

@app.route('/users/<uid>/museum-collection', methods=['GET'])
def get_user_museum_artworks(uid):
    try:
        print(f" Récupération des données pour l'utilisateur : {uid}")
        
        # 1. Récupérer la collection de l'utilisateur
        user_doc = db.collection('accounts').document(uid).get()
        if not user_doc.exists:
            print(" Utilisateur non trouvé.")
            return jsonify({"message": "User not found"}), 404


        user_data = user_doc.to_dict()
        user_collection_ids = set(user_data.get('collection', []))
        print(f" IDs des œuvres dans la collection utilisateur : {user_collection_ids}")

        if not user_collection_ids:
            print(" Aucune œuvre dans la collection utilisateur.")
            return jsonify({"message": "No artworks in user collection"}), 404


        artworks_ref = db.collection('artworks')

        # 2. Associer les œuvres aux musées
        user_artworks = artworks_ref.where('__name__', 'in', list(user_collection_ids)).stream()
        museum_to_artworks = {}
        for artwork in user_artworks:
            data = artwork.to_dict()
            museum_id = data.get('id_museum')
            if museum_id:
                museum_to_artworks.setdefault(museum_id, set()).add(artwork.id)

        if not museum_to_artworks:
            print(" Aucun musée associé aux œuvres de l'utilisateur.")
            return jsonify({"message": "No museums associated with user artworks"}), 404

        # 3. Récupérer les données des musées via official_id et ne garder que title, image, official_id
        museums_data = {}
        for museum_id in museum_to_artworks.keys():
            museum_query = db.collection('museums').where("official_id", "==", museum_id).stream()
            museum_docs = list(db.collection('museums').where("official_id", "==", museum_id).stream())
            if museum_docs:
                data = museum_docs[0].to_dict()
                filtered_data = {
                    "title": data.get("title"),
                    "image": data.get("image"),
                    "official_id": museum_id,
                    "department": data.get("departement"),
                    "place": data.get("place"),
                    "histoire": data.get("histoire"),
                }
                museums_data[museum_id] = filtered_data
            else:
                print(f"❌ Musée non trouvé pour official_id = {museum_id}")

        # 4. Construire le résultat final : pour chaque musée, inclure les infos filtrées + artworks (id + completed)
        result = {}
        for museum_id, museum_data in museums_data.items():
            artworks_stream = artworks_ref.where("id_museum", "==", museum_id).stream()

            artworks_list = []
            for artwork in artworks_stream:
                artworks_list.append({
                    "id": artwork.id,
                    "completed": artwork.id in user_collection_ids
                })

            museum_obj = museum_data.copy()
            museum_obj["artworks"] = artworks_list

            result[museum_id] = museum_obj

        # Print final clair
        print("\n📢 Résumé final des musées et leurs œuvres :")
        for mid, mdata in result.items():
            print(f"Musée {mid} ({mdata.get('title')}) a ces œuvres :")
            for art in mdata.get("artworks", []):
                print(f"  - Œuvre {art['id']} | complétée : {art['completed']}")

        print(result)
        return jsonify({"result": result}), 200


    except Exception as e:
        print(f"❌ Erreur inattendue : {e}")
        return jsonify({"message": "Internal server error", "error": str(e)}), 500


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

@app.route("/users/<uid>/verif-quests", methods=["POST"])
def get_verif_museum(uid):
    data = request.get_json()
    artwork_id = data.get("artwork_id")
    museum_id = data.get("museum_id")

    print(f"Artwork ID: {artwork_id}, Museum ID: {museum_id}")

    doc_ref = db.collection('accounts').document(uid)
    user_db = doc_ref.get()
    
    if not user_db.exists:
        return jsonify({"message": "Utilisateur introuvable"}), 404

    user_data = user_db.to_dict()
    quete_museum = user_data.get('quete_museum', [])
    quest = next((q for q in quete_museum if q.get("id") == museum_id), None)

    if not quest:
        return jsonify({"message": "Not_Initialized"}), 200

    artworks = quest.get("artworks", [])
    if not artworks:
        print(f"Aucune œuvre à valider pour le musée {museum_id}.")
        return jsonify({"message": "Vide"}), 200

    if artworks[0] == artwork_id:
        return jsonify({"message": "Correct"}), 200
    else:
        print("Ce n'est pas la bonne œuvre à valider.")
        return jsonify({"message": "Incorrect"}), 200

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
                if liste_recommendations:
                    artworks.sort(key=lambda aid: 0 if aid in liste_recommendations else 1)
                print("Artwork to validate :", artworks[0])
                artwork= get_artwork_by_id(artworks[0])
                print(artwork)
                #return artwork
                return jsonify({"image_url": artwork.get("image_url")}), 200
        
        else :
            liste_artworks_museum = db.collection('artworks').where('id_museum', '==', museum_id).get()
            if not any(liste_artworks_museum):
                print(f"Le musée {museum_id} ne contient aucune œuvre d'art.")
                return jsonify({"message": "Ce musée ne contient aucune œuvre d'art."}), 404
                
            liste_artworks = [doc for doc in liste_artworks_museum if doc.id not in collection_user]
            if not liste_artworks:
                print(f"Toutes les œuvres du musée {museum_id} sont dans votre collection.")
                return jsonify({"message": "Vous avez déjà collecté toutes les œuvres de ce musée !"}), 208

            artwork_ids = [doc.id for doc in liste_artworks]

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
    data = request.get_json()
    artworkId = data.get("artworkId")
    museum_id = data.get("museum_id")

    doc_ref = db.collection('accounts').document(uid)
    user_db = doc_ref.get()
    
    if not user_db.exists:
        return jsonify({"error": "Utilisateur introuvable."}), 404

    user_data = user_db.to_dict()
    quete_museum = user_data.get('quete_museum', [])

    if not quete_museum:
        return jsonify({"message": "Pas de quêtes en cours."}), 400

    quest = next((q for q in quete_museum if q.get("id") == museum_id), None)
    if not quest:
        return jsonify({"message": f"Aucune quête trouvée pour le musée {museum_id}."}), 400

    artworks = quest.get("artworks", [])
    if not artworks:
        return jsonify({"message": f"Aucune œuvre à valider pour le musée {museum_id}."}), 400

    if artworkId == artworks[0]:
        artworks.pop(0)

        updated_quete_museum = [
            {**q, "artworks": artworks} if q.get("id") == museum_id else q
            for q in quete_museum
        ]
        doc_ref.set({"quete_museum": updated_quete_museum}, merge=True)

        return jsonify({"message": "Œuvre validée, quête mise à jour."}), 200
    else:
        return jsonify({"message": "Ce n'est pas la bonne œuvre à valider."}), 400
    
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
    
    ids = [str(secrets.randbelow(40000)) for _ in range(5)]
    artworks = get_artworks_by_ids(ids)

    if artworks:
        return jsonify({"success": True, "data": artworks})
    else:
        return jsonify({"success": False, "message": "Artworks pas générés"}), 404
    

@app.route("/users/<uid>/current-museum", methods=["GET"])
def get_current_museum(uid):
    try:
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            actual_museum = data.get('visited_museum', None)

            if actual_museum:
                return jsonify({"actual_museum": actual_museum}), 200
            else:
                return "", 204  # Pas de musée actuel
        else:
            return jsonify({"error": "Utilisateur non trouvé"}), 404
    except Exception as e:
        print("Erreur lors de la récupération du musée actuel:", e)
        return jsonify({"error": "Erreur serveur"}), 500

@app.route("/users/<uid>/current-museum", methods=["PUT"])
def set_current_museum(uid):
    try:
        data = request.get_json()
        actual_museum = data.get('visited_museum', None)

        if actual_museum is not None and not isinstance(actual_museum, str):
            return jsonify({"error": "actual_museum doit être une string ou null"}), 400

        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if not doc.exists:
            return jsonify({"error": "Utilisateur non trouvé"}), 404

        doc_ref.update({'visited_museum': actual_museum})
        return jsonify({
            "message": "Musée actuel mis à jour",
            "actual_museum": actual_museum
        }), 200

    except Exception as e:
        print("Erreur lors de la mise à jour du musée actuel:", e)
        return jsonify({"error": "Erreur serveur"}), 500


def start_worker():
    connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
    channel = connection.channel()
    channel.queue_declare(queue='profiling_completed')
    channel.basic_consume(queue='profiling_completed',
                          on_message_callback=handle_profiling_completed,
                          auto_ack=True)
    print("Listening for messages...")
    channel.start_consuming()


    
if __name__ == "__main__":
    rabbit_process = Process(target=start_worker)
    rabbit_process.start()
    
    app.run(debug=False, port=5001)
    rabbit_process.join()