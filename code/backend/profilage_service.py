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



@app.route("/profilage", methods=["POST"])
def profilage():
    data = request.get_json()

    uid = data.get("uid")
    movement = data.get("movement")
    previous_profile = data.get("previous_profile", {})
    action = data.get("action")

    if not previous_profile:
        previous_profile = init_profile()

    if not movement:
        return jsonify({
            "uid": uid,
            "profile": previous_profile,
            "message": "Aucun mouvement valide trouvé."
        })

    profile = update_profile(previous_profile, movement, action)

    return jsonify({
        "uid": uid,
        "profile": profile
    }), 200

if __name__ == "__main__":
    app.run(debug=True, port=5002)