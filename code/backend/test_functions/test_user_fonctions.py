import pytest
from unittest.mock import patch, MagicMock
from functions.user_functions import (
    get_artworks,
    get_collection,
    get_artworks_by_ids,
    get_artwork_by_id,
)  # adapte le nom selon ton fichier exact

# Fixture pour un document Firestore mocké
@pytest.fixture
def fake_doc():
    doc = MagicMock()
    doc.exists = True
    return doc

# Fixture pour un document Firestore mocké inexistant
@pytest.fixture
def fake_doc_not_exist():
    doc = MagicMock()
    doc.exists = False
    return doc

def test_get_artworks():
    fake_artwork1 = MagicMock()
    fake_artwork1.to_dict.return_value = {'title': 'Art1'}
    fake_artwork1.id = 'id1'
    fake_artwork2 = MagicMock()
    fake_artwork2.to_dict.return_value = {'title': 'Art2'}
    fake_artwork2.id = 'id2'
    
    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_collection = mock_db.collection.return_value
        mock_collection.stream.return_value = [fake_artwork1, fake_artwork2]
        
        result = get_artworks()
        assert len(result) == 2
        assert result[0]['id'] == 'id1'
        assert result[1]['title'] == 'Art2'

def test_get_collection_exists(fake_doc):
    fake_doc.to_dict.return_value = {'collection': ['art1', 'art2']}
    
    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_doc_ref = mock_db.collection.return_value.document.return_value
        mock_doc_ref.get.return_value = fake_doc
        
        result = get_collection('user123')
        assert result == ['art1', 'art2']

def test_get_collection_not_exist(fake_doc_not_exist):
    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_doc_ref = mock_db.collection.return_value.document.return_value
        mock_doc_ref.get.return_value = fake_doc_not_exist
        
        result = get_collection('user123')
        assert result == []

def test_get_artworks_by_ids():
    fake_artwork1 = MagicMock()
    fake_artwork1.to_dict.return_value = {'title': 'Art1'}
    fake_artwork1.id = 'id1'
    fake_artwork2 = MagicMock()
    fake_artwork2.to_dict.return_value = {'title': 'Art2'}
    fake_artwork2.id = 'id2'

    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_collection = mock_db.collection.return_value
        
        def where_side_effect(field_path, op_string, value):
            # Simule la requête Firestore
            class QueryMock:
                def stream(self_inner):
                    return [fake_artwork1, fake_artwork2]
            return QueryMock()
        
        mock_collection.where.side_effect = where_side_effect
        
        artwork_ids = ['id1', 'id2']
        result = get_artworks_by_ids(artwork_ids)
        
        assert len(result) == 2
        assert result[0]['id'] == 'id1'
        assert result[1]['title'] == 'Art2'

def test_get_artwork_by_id_exists(fake_doc):
    fake_doc.to_dict.return_value = {'title': 'Art1'}
    fake_doc.id = 'id1'
    
    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_doc = mock_db.collection.return_value.document.return_value.get.return_value = fake_doc
        
        result = get_artwork_by_id('id1')
        assert result['id'] == 'id1'
        assert result['title'] == 'Art1'

def test_get_artwork_by_id_not_exists(fake_doc_not_exist):
    with patch('functions.user_functions.firestore.client') as mock_client:
        mock_db = mock_client.return_value
        mock_doc = mock_db.collection.return_value.document.return_value.get.return_value = fake_doc_not_exist
        
        result = get_artwork_by_id('idX')
        assert result is None
