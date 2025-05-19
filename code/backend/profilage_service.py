import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

ALL_MOVEMENTS = [
    "Abstraction", "Art déco", "Art naïf", "Art nouveau", "Baroque", "Byzantin",
    "Calligraphie", "Cubisme", "Dadaïsme", "Expressionnisme", "Fauvisme", "Hyperréalisme",
    "Impressionnisme", "Inconnu", "Maniérisme", "Néoclassicisme", "Pop art", "Post-impressionnisme",
    "Primitif", "Pré-raphaélisme", "Renaissance", "Rococo", "Romantisme", "Réalisme", "Surréalisme",
    "Symbolisme"
]

def init_profile():
    return {m: 1.0 for m in ALL_MOVEMENTS}

def update_profile(profile, movement, action, alpha=0.1):
    if movement not in profile:
        print(f"Mouvement inconnu : {movement}. Ajout au profil.")
        profile[movement] = 0.0

    for m in profile:
        if m == movement:
            if action == "like":
                profile[m] += alpha * (1 - profile[m])
            elif action == "dislike":
                profile[m] -= alpha * profile[m]
        else:
            profile[m] *= (1 - alpha * 0.2)

    total = sum(profile.values())
    if total > 0:
        profile = {k: round(v / total, 4) for k, v in profile.items()}

    return profile



@app.route("/api/profilage", methods=["POST"])
def profilage():
    data = request.get_json()
    print(f"Received data: {data}")

    uid = data.get("uid")
    artwork_id = data.get("artwork_id")
    movement = data.get("movement")
    previous_profile = data.get("previous_profile", {})
    action = data.get("action")  # "like" ou "dislike"

    if not previous_profile:
        print("Aucun profil précédent trouvé, initialisation d'un nouveau profil")
        previous_profile = init_profile()

    if not movement:
        print(f"Aucun mouvement valide trouvé, renvoi du profil précédent : {previous_profile}")
        return jsonify({
            "uid": uid,
            "profile": previous_profile,
            "message": "Aucun mouvement valide trouvé."
        })

    profile = update_profile(previous_profile, movement, action)
    print(f"Profil mis à jour pour {uid} après {action} sur {movement} : {profile}")

    try:
        print(f"Sending PUT request to update profile for UID: {uid}")
        response = requests.put(
            f"http://localhost:5001/api/put-profile/{uid}",
            json={"movements": profile, "liked_artworks": artwork_id, "action": action},
            timeout=10
        )
        response.raise_for_status()

    except requests.exceptions.RequestException as e:
        return jsonify({
            "uid": uid,
            "profile": profile,
            "error": f"Erreur lors de la mise à jour du profil dans le monolithe : {str(e)}"
        }), 500

    return jsonify({
        "uid": uid,
        "updated_profile": profile,
        "message": "Profil mis à jour avec succès via le monolithe."
    }), 200

if __name__ == "__main__":
    app.run(debug=True, port=5002)