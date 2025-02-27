import json
from firebase_admin import credentials, initialize_app, firestore

# Initialiser Firebase avec les credentials
cred = credentials.Certificate("../logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json")  # Remplacer par votre fichier de clé JSON
initialize_app(cred)

# Fonction pour transférer les artworks vers Firestore
def upload_artworks_to_firestore():
    # Charger les données du fichier JSON
    with open('museumsV3.json', 'r', encoding="utf-8") as f:
        museums_data = json.load(f)
    
    # Connexion à Firestore
    db = firestore.client()

    # Parcourir chaque œuvre d'art dans le fichier JSON
    for museum_id, museum in museums_data.items():
        image_link = museum.get('image', '')

        # Vérifier si l'image existe et est un lien valide
        if image_link:
            # Vous pouvez ajouter une vérification pour tester si l'URL est valide ici si nécessaire
            pass
        else:
            print(f"⚠ Pas d'image disponible pour le musée '{museum_id}' ({museum.get('title')}). Elle sera ignorée.")
            continue  # Si aucune image, on passe au musée suivant

        # Créer un dictionnaire avec les données du musée
        museum_data = {
            'official_id': museum.get('official_id'),
            'title': museum.get('title'),
            'themes': museum.get('themes'),
            'city': museum.get('city'),
            'region': museum.get('region'),
            'departement': museum.get('departement'),
            'code_postal': museum.get('code_postal'),
            'image': image_link,  # Utiliser le lien de l'image
            'place': museum.get('place'),
            'location': {
                'latitude': museum.get('location', {}).get('latitude'),
                'longitude': museum.get('location', {}).get('longitude')
            },
            'official_link': museum.get('official_link'),
            'telephone': museum.get('telephone'),
            'histoire': museum.get('histoire'),
            'atout': museum.get('atout'),
            'interet': museum.get('interet')
        }

        # Ajouter chaque musée dans la collection 'museums'
        db.collection('museums').document(museum_id).set(museum_data)
        print(f"Musee '{museum_data['title']}' ajoutée avec succès!")

    print("Tous les musées ont été transférés sur Firestore.")

# Appeler la fonction pour transférer les artworks
upload_artworks_to_firestore()
