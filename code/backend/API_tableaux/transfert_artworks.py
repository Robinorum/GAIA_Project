import json
from firebase_admin import credentials, initialize_app, firestore

# Initialiser Firebase avec les credentials
cred = credentials.Certificate("../logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json")  # Remplacer par votre fichier de clé JSON
initialize_app(cred)

# Fonction pour transférer les artworks vers Firestore
def upload_artworks_to_firestore():
    # Charger les données du fichier JSON
    with open('artworksV2.json', 'r', encoding="utf-8") as f:
        artworks_data = json.load(f)
    
    # Connexion à Firestore
    db = firestore.client()

    # Parcourir chaque œuvre d'art dans le fichier JSON
    for artwork_id, artwork in artworks_data.items():
        # Créer un dictionnaire avec les données de l'œuvre
        artwork_data = {
            'title': artwork.get('title'),
            'artist': artwork.get('artist'),
            'date': artwork.get('date'),
            'description': artwork.get('description'),
            'dimensions': artwork.get('dimensions'),
            'techniques used': artwork.get('techniques used'),
            'movement': artwork.get('movement'),
            'image_url': artwork.get('image_url'),
            'id_museum': artwork.get('id_museum')
        }

        # Ajouter chaque œuvre d'art dans la collection 'artworks'
        db.collection('artworks').document(artwork_id).set(artwork_data)
        print(f"Œuvre d'art '{artwork_data['title']}' ajoutée avec succès!")

    print("Tous les artworks ont été transférés sur Firestore.")

# Appeler la fonction pour transférer les artworks
upload_artworks_to_firestore()