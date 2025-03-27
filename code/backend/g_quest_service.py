from flask import Flask, jsonify, request
from firebase_admin import firestore, credentials
import firebase_admin

app = Flask(__name__)

# Initialisation Firebase
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
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

@app.route("/api/general_quests/<quest_id>", methods=["GET"])
def get_quest_by_id(quest_id):
    quest_ref = db.collection('quests').document(quest_id)
    quest = quest_ref.get()

    if quest.exists:
        quest_data = quest.to_dict()
        quest_data['id'] = quest.id
        return jsonify(quest_data), 200
    else:
        return jsonify({"error": "Quest not found"}), 404

# @app.route("/api/general_quests/<quest_id>/progress", methods=["POST"])
# def update_quest_progress(quest_id):
#     data = request.get_json()
#     new_progress = data.get("progress")

#     if new_progress is None or not isinstance(new_progress, int):
#         return jsonify({"error": "Invalid progress value"}), 400

#     quest_ref = db.collection('quests').document(quest_id)
#     quest = quest_ref.get()

#     if quest.exists:
#         quest_ref.update({"progress": new_progress})
#         return jsonify({"message": "Progress updated successfully"}), 200
#     else:
#         return jsonify({"error": "Quest not found"}), 404

if __name__ == "__main__":
    app.run(debug=True, port=5006)
