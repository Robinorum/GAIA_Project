from flask import Flask, request, jsonify
from torchvision import transforms
import numpy as np
from PIL import Image
import io
import pickle
import torch
import clip
import faiss
#from AI_scan.recherche import find_most_similar_image

app = Flask(__name__)

# Initialisation du modèle
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model, preprocess = clip.load("ViT-B/32", device=device)
index = faiss.read_index("AI_scan/index.faiss")

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400

    # Récupération et préparation de l'image envoyée
    file = request.files['file']
    image = Image.open(io.BytesIO(file.read())).convert("RGB")

    # Recherche des images similaires
    index_similar_images = find_most_similar_image(image, index, model, device, k=1)

    # Renvoie la réponse avec les informations de l'image la plus proche
    result = {
        "index_prediction": index_similar_images[0] if index_similar_images else {"error": "Aucune image similaire trouvee"}
    }
    return jsonify(result)

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





def find_most_similar_image(image, index, model, device, k=1, threshold=0.75):

    results = []
    
    for angle in [0, 90, 180, 270]:
        
        rotated_image = image.rotate(angle, expand=True)
        
        input_embedding = get_embedding(rotated_image, model, device).astype("float32")
        distances, indices = index.search(np.array([input_embedding]), k)
        
        
        results.append({
            'distance': distances[0][0],
            'indices': indices[0],
            'angle': angle
        })
    
    results.sort(key=lambda x: x['distance'], reverse=True)
    print(f"Meilleure distance: {results[0]['distance']} (angle: {results[0]['angle']}°)")
    
    if results[0]['distance'] > threshold:
        return [results[0]['indices']]
    
    return False

if __name__ == "__main__":
    app.run(debug=True, port=5001)
