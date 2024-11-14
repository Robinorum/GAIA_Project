import torch
from torchvision import models, transforms
from torchvision.models import ResNet18_Weights
from PIL import Image
import numpy as np
import faiss
import pickle

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = models.resnet18(weights=ResNet18_Weights.IMAGENET1K_V1).to(device)
model.eval()

preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def get_embedding(image):
    input_tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        embedding = model(input_tensor)
    return embedding.squeeze().cpu().numpy()


index = faiss.read_index("index.faiss")


with open("titles_artists.pkl", "rb") as f:
    titles, artists = pickle.load(f)

def find_most_similar_image(input_image_path, index, titles, artists, k=1):
    input_image = Image.open(input_image_path).convert("RGB")
    input_embedding = get_embedding(input_image).astype("float32")
    
    _, indices = index.search(np.array([input_embedding]), k)
    
    closest_image_info = [(titles[i], artists[i]) for i in indices[0]]
    
    return closest_image_info


input_image_path = "nuit.jpg"
most_similar_images = find_most_similar_image(input_image_path, index, titles, artists, k=1)

if most_similar_images:
    title, artist = most_similar_images[0]
    print(f"L'image la plus proche dans le dataset est : '{title}' par {artist}")
else:
    print("Aucune image similaire trouvée.")
