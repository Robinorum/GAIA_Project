from flask import Flask, jsonify
import json

app = Flask(__name__)

# Chargement des données
with open("API_Tableaux/museums.json", "r") as file:
    museums = json.load(file)

@app.route("/api/museums", methods=["GET"])
def get_museums():
    # Transmettre directement les données en base64
    return jsonify({"success": True, "data": museums})

if __name__ == "__main__":
    app.run(debug=True, port=5004)
