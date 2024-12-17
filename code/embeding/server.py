from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
import io
import torch
from torchvision import models
from torchvision.models import ResNet18_Weights
import faiss
import clip
import pickle
import os
import subprocess

# Import des fonctions de recherche
from recherche import find_most_similar_image

def configure_adb_reverse():
    try:
        subprocess.run(["adb", "reverse", "tcp:5000", "tcp:5000"], check=True)
        print("Configuration adb reverse réussie : port 5000 redirigé.")
    except subprocess.CalledProcessError:
        print("Erreur lors de la configuration d'adb reverse")
    except FileNotFoundError:
        print("ADB n'est pas installé ou accessible dans le PATH.")

# Configuration de l'environnement pour éviter les problèmes liés à faiss
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

# Initialisation de l'application Flask
app = Flask(__name__)
CORS(app)

# Configuration du modèle et de l'appareil
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model, preprocess = clip.load("ViT-B/32", device=device)
model.eval()

# Chargement de l'index FAISS
index = faiss.read_index("index.faiss")

# Chargement des métadonnées (titres et artistes)
with open("titles_artists.pkl", "rb") as f:
    titles, artists = pickle.load(f)

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400

    # Récupération et préparation de l'image envoyée
    file = request.files['file']
    image = Image.open(io.BytesIO(file.read())).convert("RGB")

    # Recherche des images similaires
    similar_images = find_most_similar_image(image, index, titles, artists, model, device, k=1)

    # Renvoie la réponse avec les informations de l'image la plus proche
    result = {
        "prediction": similar_images[0] if similar_images else {"error": "Aucune image similaire trouvee"}
    }
    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1')
