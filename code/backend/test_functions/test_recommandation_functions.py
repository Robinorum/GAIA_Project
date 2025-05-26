import firebase_admin
import pytest
from firebase_admin import firestore, credentials
from unittest.mock import patch, MagicMock
from functions.recommandation_functions import (
    get_user_preferences,
    get_previous_recommendations,
    get_user_collection,
    update,
)

cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

@pytest.fixture
def fake_firestore_doc():
    mock_doc = MagicMock()
    mock_doc.exists = True
    return mock_doc

def test_get_user_preferences(fake_firestore_doc):
    fake_firestore_doc.to_dict.return_value = {
        "preferences": {
            "movements": {"Impressionism": 0.8, "Cubism": 0.5}
        }
    }

    with patch("functions.recommandation_functions.firestore") as mock_firestore:
        mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

        result = get_user_preferences("test-uid", db)
        assert result == {"Impressionism": 0.8, "Cubism": 0.5}

def test_get_previous_recommendations(fake_firestore_doc):
    fake_firestore_doc.to_dict.return_value = {
        "previous_reco": ["id1", "id2", "id3"]
    }

    with patch("functions.recommandation_functions.firestore") as mock_firestore:
        mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

        result = get_previous_recommendations("test-uid", db)
        assert result == ["id1", "id2", "id3"]

def test_get_user_collection(fake_firestore_doc):
    fake_firestore_doc.to_dict.return_value = {
        "collection": ["art1", "art2"]
    }

    with patch("functions.recommandation_functions.firestore") as mock_firestore:
        mock_firestore.client.return_value.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

        result = get_user_collection("test-uid", db)
        assert result == ["art1", "art2"]

def test_update_firestore():
    with patch("functions.recommandation_functions.firestore") as mock_firestore:
        mock_doc_ref = MagicMock()
        mock_firestore.client.return_value.collection.return_value.document.return_value = mock_doc_ref

        previous = ["id1", "id2", "id3"]
        new = [{"id": "id4"}, {"id": "id5"}]

        updated = update("test-uid", previous, new, db)

        mock_doc_ref.update.assert_any_call({'previous_reco': ['id1', 'id2', 'id3', 'id4', 'id5']})
        mock_doc_ref.update.assert_any_call({'reco': ['id4', 'id5']})

        assert updated == ['id1', 'id2', 'id3', 'id4', 'id5']
