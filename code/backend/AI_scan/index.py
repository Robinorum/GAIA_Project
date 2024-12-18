import torch
import clip
from PIL import Image
from datasets import load_dataset
import numpy as np
import faiss
import pickle

# Chargement du modèle CLIP et de la transformation d'image associée
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model, preprocess = clip.load("ViT-B/32", device=device)
model.eval()

# Fonction pour obtenir les embeddings d'images avec CLIP
def get_embedding(image):
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model.encode_image(input_tensor)
        embedding = embedding / embedding.norm(dim=-1, keepdim=True)  # Normalisation
    return embedding.squeeze().cpu().numpy()

# Chargement du dataset
dataset = load_dataset("Artificio/WikiArt_Full", split="train[:50%]")

embeddings = []
titles = []
artists = []

# Boucle de traitement pour chaque entrée du dataset
for entry in dataset:
    image = entry['image']
    title = entry['title']
    artist = entry['artist']
    
    # Calcul de l'embedding
    embedding = get_embedding(image)
    embeddings.append(embedding)
    titles.append(title)
    artists.append(artist)

# Conversion des embeddings en tableau numpy float32
embeddings_np = np.array(embeddings).astype("float32")
dimension = embeddings_np.shape[1]

# Création de l'index FAISS avec produit scalaire interne pour des vecteurs normalisés
index = faiss.IndexFlatIP(dimension)
index.add(embeddings_np)

# Sauvegarde de l'index FAISS
faiss.write_index(index, "index.faiss")

# Sauvegarde des titres et artistes
with open("titles_artists.pkl", "wb") as f:
    pickle.dump((titles, artists), f)

print("Index FAISS et métadonnées sauvegardés.")
