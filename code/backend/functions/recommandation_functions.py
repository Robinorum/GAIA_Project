import firebase_admin
import random
import json
import redis
from flask import Flask, jsonify
from firebase_admin import credentials, firestore

db = firestore.client()

r = redis.Redis(host='localhost', port=6379, decode_responses=True)


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


def update(uid, previous_recommendations, new_recommendations):
    updated_reco = previous_recommendations[-5:] + [art['id'] for art in new_recommendations]
    new_recommendationsid = [art['id'] for art in new_recommendations]

    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    doc_ref.update({'reco': new_recommendationsid})

    return updated_reco