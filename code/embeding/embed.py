import base64
from io import BytesIO
import json
import torch
from torchvision import models, transforms
from PIL import Image
from datasets import load_dataset
import numpy as np
import faiss  # Assurez-vous d'avoir installé FAISS

# Charger le modèle et le placer sur le GPU si disponible
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = models.resnet18(pretrained=True).to(device)
model.eval()

# Prétraitement pour les images
preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# Fonction pour obtenir l'embedding d'une image
def get_embedding(image):
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model(input_tensor)
    return embedding.squeeze().cpu().numpy()

# Charger le dataset
dataset = load_dataset("Artificio/WikiArt_Full", split="train[:5%]")

# Calculer et stocker les embeddings
embeddings = []
titles = []
artists = []

for entry in dataset:
    image = entry['image']
    title = entry['title']
    artist = entry['artist']
    
    # Calcul de l'embedding
    embedding = get_embedding(image)
    embeddings.append(embedding)
    titles.append(title)
    artists.append(artist)

# Convertir les embeddings en tableau numpy pour FAISS
embeddings_np = np.array(embeddings).astype("float32")

# Créer et remplir l'index FAISS pour une recherche rapide
dimension = embeddings_np.shape[1]
index = faiss.IndexFlatL2(dimension)  # Index basé sur la distance L2 (euclidienne)
index.add(embeddings_np)

# Fonction pour trouver l'image la plus similaire avec FAISS
def find_most_similar_image(input_image_path, index, titles, artists, k=1):
    input_image = Image.open(input_image_path).convert("RGB")
    input_embedding = get_embedding(input_image).astype("float32")
    
    # Recherche des k voisins les plus proches
    _, indices = index.search(np.array([input_embedding]), k)
    
    # Récupérer le titre et le nom de l'artiste de l'image la plus similaire
    closest_image_info = [(titles[i], artists[i]) for i in indices[0]]
    
    return closest_image_info

# Exemple d'utilisation
input_image_path = "mount-cassis.jpg"
most_similar_images = find_most_similar_image(input_image_path, index, titles, artists, k=1)

if most_similar_images:
    title, artist = most_similar_images[0]
    print(f"L'image la plus proche dans le dataset est : '{title}' par {artist}")
else:
    print("Aucune image similaire trouvée.")

