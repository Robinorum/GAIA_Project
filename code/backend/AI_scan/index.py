import torch
import torchvision.transforms as transforms
from torchvision import models
from PIL import Image
import numpy as np
import faiss
import json
import base64
import io

# Charger le modèle ResNet-18 pré-entraîné
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = models.resnet18(pretrained=True)
model.fc = torch.nn.Identity()  # Supprime la dernière couche
model.eval()
model.to(device)

# Prétraitement des images
preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def get_embedding(image):
    """Extrait un embedding à partir d'une image avec ResNet-18."""
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model(input_tensor).cpu().numpy().squeeze()
    return embedding / np.linalg.norm(embedding)  # Normalisation

# Charger les données JSON
with open('../API_tableaux/artworksV2.json', 'r', encoding='utf-8') as f:
    artwork_data = json.load(f)

embeddings = []

# Processus d'indexation
for artwork_id, artwork_info in artwork_data.items():
    image_bytes = artwork_info['image']['bytes']
    image_data = base64.b64decode(image_bytes)
    image = Image.open(io.BytesIO(image_data)).convert("RGB")

    embedding = get_embedding(image)
    embeddings.append(embedding)

# Convertir en numpy array
embeddings_np = np.array(embeddings).astype("float32")
dimension = embeddings_np.shape[1]

# Créer un index FAISS (distance euclidienne)
index = faiss.IndexFlatL2(dimension)
index.add(embeddings_np)

# Sauvegarde de l'index
faiss.write_index(index, "index_artwork_big.faiss")
