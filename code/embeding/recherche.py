import torch
from torchvision import transforms
from PIL import Image
import numpy as np

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

def find_most_similar_image(image, index, titles, artists, model, device, k=1, threshold=0.90):
    """
    Trouve les images les plus similaires dans l'index FAISS.
    Si la distance minimale dépasse le seuil, renvoie "Pas de correspondance".
    """
    input_embedding = get_embedding(image, model, device).astype("float32")
    
    # Recherche dans l'index avec FAISS
    distances, indices = index.search(np.array([input_embedding]), k)
    
    # Vérifier la distance minimale
    if distances[0][0] < threshold:
        return False
    
    # Retourner les informations de l'image la plus proche
    closest_image_info = [(titles[i], artists[i]) for i in indices[0]]
    return closest_image_info
