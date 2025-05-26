from flask import Flask, jsonify, request
from firebase_admin import firestore, credentials
import firebase_admin

app = Flask(__name__)

cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

@app.route("/quests", methods=["GET"])
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

if __name__ == "__main__":
    app.run(debug=False, port=5006)
