import pytest
import firebase_admin
from firebase_admin import credentials

from functions.user_functions import (
    get_artworks, 
    get_artwork_by_id, 
    get_collection,
)

# === 1. Setup global Firebase Admin une fois pour tous les tests ===
@pytest.fixture(scope="session", autouse=True)
def setup_firestore():
    if not firebase_admin._apps:  # Évite de réinitialiser si déjà fait
        cred = credentials.Certificate("testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json") 
        firebase_admin.initialize_app(cred)
    yield
    
def test_get_artworks_real_db():
    artworks = get_artworks()
    assert isinstance(artworks, list)
    assert len(artworks) > 0  # Assure-toi d'avoir au moins une œuvre dans la base
    assert "title" in artworks[0]

def test_get_collection_user_real_db():
    uid = "vB8cb9MIVYbf9k88q4WFPTJ6YyD3"  # Remplace avec un UID valide de ta base
    expected_ids = ["4782", "51598"]
    collection = get_collection(uid)
    
    assert isinstance(collection, list)
    assert set(expected_ids).issubset(set(collection))

def test_get_artwork_by_id_real_db():
    all_artworks = get_artworks()
    if not all_artworks:
        pytest.skip("Aucune œuvre dans la base")
    
    art_id = all_artworks[0]['id']
    artwork = get_artwork_by_id(art_id)
    assert artwork is not None
    assert artwork['id'] == art_id

