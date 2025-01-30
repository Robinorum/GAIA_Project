import torch
import clip
from PIL import Image
import numpy as np
import faiss
import pickle
import json
import base64
import io

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



# Load JSON file as dictionary
with open('../API_tableaux/artwork.json', 'r', encoding='utf-8') as f:
    artwork_data = json.load(f)

embeddings = []


# Process each artwork
for artwork_id, artwork_info in artwork_data.items():
    # Get image bytes and convert to PIL Image
    image_bytes = artwork_info['image']['bytes']
    image_data = base64.b64decode(image_bytes)
    image = Image.open(io.BytesIO(image_data))
    

    
    # Calculate embedding
    embedding = get_embedding(image)
    embeddings.append(embedding)

# Convert to numpy array
embeddings_np = np.array(embeddings).astype("float32")
dimension = embeddings_np.shape[1]

# Create FAISS index
index = faiss.IndexFlatIP(dimension)
index.add(embeddings_np)

# Save index and metadata
faiss.write_index(index, "index_artwork.faiss")
