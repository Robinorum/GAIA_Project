import json
import redis

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_user_preferences(uid, db):
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

def get_previous_recommendations(uid, db):
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
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []

def get_user_collection(uid, db):
    try:
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

def cache_all_artworks(db, ttl=3600):
    """
    Charge toutes les œuvres en cache Redis avec un TTL (1h par défaut).
    """
    try:
        cache_key = "all_artworks"
        cached = r.get(cache_key)
        if cached:
            print("Loaded artworks from Redis cache.")
            return json.loads(cached)

        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.stream()
        result = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id
            result.append(artwork_data)

        print(f"Successfully retrieved {len(result)} artworks from Firestore.")
        r.setex(cache_key, 3600, json.dumps(result))  # Cache pendant 1 heure
        return result
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return []

def get_all_artworks_from_cache(db):
    cached = r.get('all_artworks')
    if cached:
        return json.loads(cached)
    else:
        return cache_all_artworks(db)

def filter_artworks_by_preferences(artworks, preferences):
    if not preferences:
        return artworks
    preferred_movements = set(preferences.keys())
    filtered = [art for art in artworks if art.get('movement') in preferred_movements]
    return filtered

def update(uid, previous_recommendations, new_recommendations, db):
    """
    Met à jour les recommandations dans Firestore.
    """

    updated_reco = previous_recommendations[-20000:] + [art['id'] for art in new_recommendations]
    new_recommendations_ids = [art['id'] for art in new_recommendations]

    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    doc_ref.update({'reco': new_recommendations_ids})

    return updated_reco