import firebase_admin
import random
from flask import Flask, jsonify
from firebase_admin import credentials, firestore


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
    """
    Met à jour les recommandations dans Firestore en ajoutant de nouvelles recommandations.
    
    Args:
        uid (str): ID de l'utilisateur.
        previous_recommendations (list): Liste des recommandations précédentes.
        new_recommendations (list): Liste des nouvelles recommandations.
    """
    # Ajouter les nouvelles recommandations aux anciennes
    updated_reco = previous_recommendations[-5:] + [art['id'] for art in new_recommendations]
    
    new_recommendationsid= [art['id'] for art in new_recommendations]
    # Limiter à un nombre raisonnable de recommandations (par exemple 20)
    # plus tard on mettra 20 
    
    # Mettre à jour Firestore avec les nouvelles recommandations
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    doc_ref.update({'reco': new_recommendationsid})
    
    return updated_reco

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
