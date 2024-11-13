import torch
from torchvision import models, transforms
from datasets import load_dataset
import numpy as np
import faiss
import pickle

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = models.resnet18(pretrained=True).to(device)
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

dataset = load_dataset("Artificio/WikiArt_Full", split="train[:50%]")

embeddings = []
titles = []
artists = []

for entry in dataset:
    image = entry['image']
    title = entry['title']
    artist = entry['artist']
    
    embedding = get_embedding(image)
    embeddings.append(embedding)
    titles.append(title)
    artists.append(artist)

embeddings_np = np.array(embeddings).astype("float32")
dimension = embeddings_np.shape[1]
index = faiss.IndexFlatL2(dimension)
index.add(embeddings_np)

# Sauvegarde de l'index FAISS
faiss.write_index(index, "index.faiss")

# Sauvegarde des titres et artistes
with open("titles_artists.pkl", "wb") as f:
    pickle.dump((titles, artists), f)

print("Index FAISS et métadonnées sauvegardés.")
