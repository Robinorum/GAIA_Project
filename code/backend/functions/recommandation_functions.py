import json
import random
import redis
import firebase_admin
from flask import Flask, jsonify, request
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)
db = firestore.client()

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

app = Flask(__name__)

def get_user_preferences(uid):
    try:
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            movements = data.get('preferences', {}).get('movements', {})
            for movement, score in movements.items():
                print(f"User {uid} likes {movement} with score {score}")
            return movements
        else:
            print(f"Document for UID {uid} does not exist.")
            return {}
    except Exception as e:
        print(f"Error retrieving user preferences for UID {uid}: {e}")
        return {}

def get_previous_recommendations(uid):
    try:
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('previous_reco', [])
            if isinstance(collection, list):
                print(f"Previous recommendations for user {uid}: {collection}")
                return collection
            else:
                print(f"'previous_reco' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []

def get_user_collection(uid):
    try:
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('collection', [])
            if isinstance(collection, list):
                print(f"Collection for user {uid}: {collection}")
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving collection for UID {uid}: {e}")
        return []

def cache_all_artworks(ttl=3600):
    """
    Charge toutes les œuvres en cache Redis avec un TTL (1h par défaut).
    """
    try:
        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.stream()
        result = []
        for artwork in artworks:
            data = artwork.to_dict()
            data['id'] = artwork.id
            result.append(data)
        r.setex('all_artworks', ttl, json.dumps(result))
        print(f"Cached {len(result)} artworks in Redis.")
        return result
    except Exception as e:
        print(f"Error caching artworks: {e}")
        return []

def get_all_artworks_from_cache():
    cached = r.get('all_artworks')
    if cached:
        return json.loads(cached)
    else:
        # Cache absent, on recharge
        return cache_all_artworks()

def filter_artworks_by_preferences(artworks, preferences):
    if not preferences:
        return artworks
    preferred_movements = set(preferences.keys())
    filtered = [art for art in artworks if art.get('movement') in preferred_movements]
    return filtered

def update(uid, previous_recommendations, new_recommendations):
    """
    Met à jour les recommandations dans Firestore.
    """

    updated_reco = previous_recommendations[-20000:] + [art['id'] for art in new_recommendations]
    new_recommendations_ids = [art['id'] for art in new_recommendations]

    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    doc_ref.update({'reco': new_recommendations_ids})

    return updated_reco

@app.route('/recommendations/<uid>', methods=['GET'])
def get_recommendations(uid):
    preferences = get_user_preferences(uid)
    artworks = get_all_artworks_from_cache()
    filtered_artworks = filter_artworks_by_preferences(artworks, preferences)

    previous_reco = get_previous_recommendations(uid)
    user_collection = get_user_collection(uid)
    exclude_ids = set(previous_reco + user_collection)

    final_candidates = [art for art in filtered_artworks if art['id'] not in exclude_ids]

    if not final_candidates:
        return jsonify({'recommendations': []})

    recommendations = random.sample(final_candidates, min(10, len(final_candidates)))

    update(uid, previous_reco, recommendations)

    return jsonify({'recommendations': recommendations})

if __name__ == '__main__':
    cache_all_artworks(ttl=3600)
    app.run(debug=True)
