D'abord lancer le fichier index.py pour creer le .faiss (changer la valeur 50% en ce que vous voulez)
FICHIER INDEX.PY A LANCER QU'UNE SEULE FOIS


POUR LANCER LE SERVEUR :

METTRE RECHERCHE.PY ET SERVER.PY AU MEME ENDROIT

Lancer server.py  --> faire un curl POST pour rechercher une image 

commande : curl -X POST -F "file=@nom-image.jpg" http://127.0.0.1:5000/predict

