from firebase_admin import firestore


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




def get_artworks_by_ids(artwork_ids):
    try:
        db = firestore.client()
        artworks_ref = db.collection('artworks')
        
        # Firestore permet de faire une requête avec "in" pour jusqu'à 10 IDs à la fois
        # Si plus de 10 IDs, on doit diviser en plusieurs requêtes
        result = []
        batch_size = 10 
        
        for i in range(0, len(artwork_ids), batch_size):
            batch_ids = artwork_ids[i:i + batch_size]
            query = artworks_ref.where(field_path='__name__', op_string='in', value=[artworks_ref.document(art_id) for art_id in batch_ids])
            artworks = query.stream()
            
            for artwork in artworks:
                artwork_data = artwork.to_dict()
                artwork_data['id'] = artwork.id
                result.append(artwork_data)
        
        print(f"Successfully retrieved {len(result)} artworks for IDs.")
        return result
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return []
    
def get_artwork_by_id(artwork_id):
    try:
        db = firestore.client()
        doc = db.collection('artworks').document(artwork_id).get()
        
        if doc.exists:
            artwork_data = doc.to_dict()
            artwork_data['id'] = doc.id
            print(f"Successfully retrieved artwork with ID: {artwork_id}")
            return artwork_data
        else:
            print(f"No artwork found with ID: {artwork_id}")
            return None
    except Exception as e:
        print(f"Error retrieving artwork: {e}")
        return None
