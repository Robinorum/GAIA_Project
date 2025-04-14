from flask import Flask, jsonify, request
from firebase_admin import firestore, credentials
import firebase_admin

app = Flask(__name__)

cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

@app.route("/api/general_quests/", methods=["GET"])
def get_general_quests():
    quests_ref = db.collection('quests')
    quests = quests_ref.stream()

    all_quests = []
    for quest in quests:
        quest_data = quest.to_dict()
        quest_data['id'] = quest.id
        all_quests.append(quest_data)
    
    for quest in all_quests:
        print(quest)
    return jsonify({"success": True, "data": all_quests})

@app.route("/api/get_quests/<userId>", methods=["GET"])
def get_quests(userId):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(userId)
    doc = doc_ref.get()
    
    if not doc.exists:
        return {"error": "Utilisateur non trouvé"}, 404
    
    user_data = doc.to_dict()
    user_quests = user_data.get('quests', {})  
    
    if not isinstance(user_quests, dict):  
        user_quests = {}  # Correction si c'est mal initialisé
    
    return {"quests": user_quests}, 200


if __name__ == "__main__":
    app.run(debug=True, port=5006)
