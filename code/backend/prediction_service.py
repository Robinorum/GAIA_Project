import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
from flask import Flask, request, jsonify
import numpy as np
from PIL import Image
import io
import faiss
import torch
import torchvision.transforms as transforms
import firebase_admin
from firebase_admin import credentials, firestore
from torchvision import models

app = Flask(__name__)

# 🔹 Initialisation Firebase
cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# 🔹 Configuration du modèle
device = torch.device("cpu")
model = models.resnet18(pretrained=True)
model.fc = torch.nn.Identity()  # Supprime la dernière couche
model.eval()
model.to(device)

# 🔹 Chargement de l’index FAISS
index = faiss.read_index("AI_scan/index_joconde.faiss")
faiss.omp_set_num_threads(1)

# 🔹 Prétraitement de l'image
preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def get_embedding(image, model, device):
    """ Convertit une image en embedding normalisé """
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model(input_tensor)
        embedding = embedding / embedding.norm(dim=-1, keepdim=True)
    return embedding.squeeze().cpu().numpy().astype("float32")



def get_link_with_id(id):
    """Récupère le lien de la photo situé à la ligne `id` dans link_id.txt (ligne 0 = id 0)"""
    try:
        with open("AI_scan/link_id.txt", "r", encoding="utf-8") as f:
            lines = f.readlines()
            index = int(id)  # FAISS renvoie un index entier
            if 0 <= index < len(lines):
                line = lines[index].strip()
                parts = line.split(",")
                if len(parts) == 2:
                    print(parts[1])
                    return parts[1]  # URL
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier link_id.txt : {e}")
    return None



def get_by_url(url):
    """ Récupère un tableau dans Firestore par son image_url """
    try:
        query = db.collection('artworks').where("image_url", "==", url).limit(1).stream()
        for doc in query:
            data = doc.to_dict()
            data['id'] = doc.id
            return data
    except Exception as e:
        print(f"Erreur lors de la récupération dans Firestore : {e}")
    return None


def find_most_similar_image(image, index, model, device, k=1, threshold=0.3):
    results = []
    
    for angle in [0, 90, 180, 270]:
        rotated_image = image.rotate(angle, expand=True)
        input_embedding = get_embedding(rotated_image, model, device).astype("float32")
        del rotated_image
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
    else:
        return None  # Aucun résultat trouvé

@app.route('/api/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400

    try:
        file = request.files['file']
        with Image.open(io.BytesIO(file.read())) as image:
            image = image.resize((224, 224))  # Assurer une taille cohérente
            result = find_most_similar_image(image, index, model, device)

        if result:
            artwork_link = get_link_with_id(result)
            artwork_data = get_by_url(artwork_link)
            return jsonify(artwork_data)
            
        return jsonify({"message": "Aucune correspondance trouvée"})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
