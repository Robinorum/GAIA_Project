import pytest
from unittest.mock import patch, MagicMock
from functions.recommandation_functions import (
    get_user_preferences,
    get_previous_recommendations,
    get_user_collection,
    update,
)


@pytest.fixture
def fake_firestore_doc():
    mock_doc = MagicMock()
    mock_doc.exists = True
    return mock_doc

def test_get_user_preferences(fake_firestore_doc):
    # Configure le to_dict de fake_firestore_doc ici (dans le test)
    fake_firestore_doc.to_dict.return_value = {
        "preferences": {
            "movements": {"Impressionism": 0.8, "Cubism": 0.5}
        }
    }

    # Crée un fake_db qui retourne fake_firestore_doc sur get()
    fake_db = MagicMock()
    fake_db.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

    # Appelle la fonction avec fake_db en 2e paramètre
    result = get_user_preferences("test-uid", fake_db)

    assert result == {"Impressionism": 0.8, "Cubism": 0.5}

def test_get_previous_recommendations(fake_firestore_doc):
    fake_firestore_doc.to_dict.return_value = {
        "previous_reco": ["id1", "id2", "id3"]
    }

    fake_db = MagicMock()
    fake_db.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

    result = get_previous_recommendations("test-uid", fake_db)
    assert result == ["id1", "id2", "id3"]

def test_get_user_collection(fake_firestore_doc):
    fake_firestore_doc.to_dict.return_value = {
        "collection": ["art1", "art2"]
    }

    fake_db = MagicMock()
    fake_db.collection.return_value.document.return_value.get.return_value = fake_firestore_doc

    result = get_user_collection("test-uid", fake_db)
    assert result == ["art1", "art2"]

def test_update_firestore():
    # Création d'un mock pour doc_ref (document Firestore)
    mock_doc_ref = MagicMock()

    # Création d'un mock db (client Firestore) qui renvoie mock_doc_ref sur collection().document()
    fake_db = MagicMock()
    fake_db.collection.return_value.document.return_value = mock_doc_ref

    previous = ["id1", "id2", "id3"]
    new = [{"id": "id4"}, {"id": "id5"}]

    # Appel de la fonction update avec fake_db
    updated = update("test-uid", previous, new, fake_db)

    # Vérifie que update a bien été appelé avec les bons arguments
    mock_doc_ref.update.assert_any_call({'previous_reco': ['id1', 'id2', 'id3', 'id4', 'id5']})
    mock_doc_ref.update.assert_any_call({'reco': ['id4', 'id5']})

    # Vérifie le résultat retourné par la fonction
    assert updated == ['id1', 'id2', 'id3', 'id4', 'id5']
