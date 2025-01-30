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