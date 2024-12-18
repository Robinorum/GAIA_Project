from flask import Flask, jsonify
import json

app = Flask(__name__)

# Charger les données JSON avec les images encodées en base64
with open("code/backend/API_tableaux/artworks.json", "r") as file:
    artworks = json.load(file)

@app.route("/api/artworks", methods=["GET"])
def get_artworks():
    # Transmettre directement les données en base64
    for key, artwork in artworks.items():
        if isinstance(artwork["image"], str):
            # Charger l'objet JSON dans le champ image
            artwork["image"] = json.loads(artwork["image"])
    return jsonify({"success": True, "data": artworks})

if __name__ == "__main__":
    app.run(debug=True)
