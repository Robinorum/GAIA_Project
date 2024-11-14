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
    """
    Transforme une image en embedding à l'aide du modèle ResNet18.
    """
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model(input_tensor)
    return embedding.squeeze().cpu().numpy()

def find_most_similar_image(image, index, titles, artists, model, device, k=1):
    """
    Trouve les images les plus similaires dans l'index FAISS.
    """
    input_embedding = get_embedding(image, model, device).astype("float32")
    _, indices = index.search(np.array([input_embedding]), k)
    closest_image_info = [(titles[i], artists[i]) for i in indices[0]]
    return closest_image_info
