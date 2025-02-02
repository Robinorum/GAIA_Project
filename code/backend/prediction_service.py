from flask import Flask, request, jsonify

import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'

from torchvision import transforms
import numpy as np
from PIL import Image
import io
import torch
import clip
import faiss
#from AI_scan.recherche import find_most_similar_image
import firebase_admin
from flask import Flask, jsonify
from firebase_admin import credentials, firestore

app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Initialisation du modèle
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model, preprocess = clip.load("ViT-B/32", device=device)
index = faiss.read_index("AI_scan/index_artwork.faiss")

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400

    file = request.files['file']
    image = Image.open(io.BytesIO(file.read()))

    
    index_similar_image = find_most_similar_image(image, index, model, device)

    print(f"ID retourné par find_most_similar_image: {index_similar_image}")  # Debug

    if index_similar_image:
        result = get_by_id(str(index_similar_image))  #on recup le tableau ENTIER
        print(f"Résultat de get_by_id: {result}")  
        return jsonify(result) #on l'envoie au fichier prediction_service.dart
    
    return jsonify({"message": "Aucune correspondance trouvée"}), 404





# Prétraitement de l'image pour le modèle
preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def get_embedding(image, model, device):
    
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model.encode_image(input_tensor)
        embedding = embedding / embedding.norm(dim=-1, keepdim=True)
    return embedding.squeeze().cpu().numpy()




def get_by_id(id):
    try:
        db = firestore.client()
        id_en_plus = int(id) + 1
        doc_ref = db.collection('artworks').document(str(id_en_plus))
        doc = doc_ref.get()

        print(f"tableau trouvé: {doc}")  # Debug

        if doc.exists:
            data = doc.to_dict()
            print(f"Artwork found: {data.get('title')}")
            return data
    except Exception as e:
        print(f"Error retrieving artwork: {e}")
        return None



def find_most_similar_image(image, index, model, device, k=1, threshold=0.75):
    results = []
    
    for angle in [0, 90, 180, 270]:
        rotated_image = image.rotate(angle, expand=True)
        input_embedding = get_embedding(rotated_image, model, device).astype("float32")
        distances, indices = index.search(np.array([input_embedding]), k)
        
        results.append({
            'distance': distances[0][0],
            'index': indices[0][0],  
            'angle': angle
        })

    
    results.sort(key=lambda x: x['distance'])

    print(f"Meilleure distance: {results[0]['distance']} (angle: {results[0]['angle']}°)")

    
    if results[0]['distance'] <= threshold:
        print(f"Index sélectionné: {results[0]['index']}")
        return str(results[0]['index'])  #J'envoie l'index du tableau le plus similaire ICI

    return None  # Aucun résultat trouvé


if __name__ == "__main__":
    app.run(debug=True, port=5001)
