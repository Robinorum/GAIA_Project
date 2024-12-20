import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String email;
  final String username;
  final bool googleAccount;
  final List<String> liked;
  final List<String> collection;
  final String visitedMuseum;
  final String profilePhoto; // Ajout de la photo de profil
  final Map<String, dynamic> preferences; // Ajout des préférences complètes
  final Map<String, double> movements; // Ajout des préférences liées aux mouvements artistiques

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.googleAccount,
    required this.liked,
    required this.collection,
    required this.visitedMuseum,
    required this.profilePhoto,
    required this.preferences,
    required this.movements,
  });


  static AppUser empty() {
    return AppUser(
      id: '',
      email: '',
      username: '',
      googleAccount: false,
      liked: [],
      collection: [],
      visitedMuseum: '',
      profilePhoto: '',
      preferences: {},
      movements: {},
    );
  }

  // Méthode pour récupérer un utilisateur depuis Firebase Auth et Firestore
  static Future<AppUser> fromAuth(User firebaseUser) async {
    final firestore = FirebaseFirestore.instance;

    // Récupérer les données de Firestore
    final doc = await firestore.collection('accounts').doc(firebaseUser.uid).get();

    if (!doc.exists) {
      throw Exception("Utilisateur introuvable dans la base de données");
    }

    final data = doc.data() as Map<String, dynamic>;

    // Récupérer les préférences de mouvement (s'ils existent)
    final movementsData = Map<String, double>.from(data['preferences']?['movement'] ?? {});

    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      googleAccount: data['googleAccount'] ?? false,
      liked: List<String>.from(data['liked'] ?? []),
      collection: List<String>.from(data['collection'] ?? []),
      visitedMuseum: data['visitedMuseum'] ?? '',
      profilePhoto: data['profilePhoto'] ?? '',
      preferences: data['preferences'] ?? {}, // Récupération des préférences
      movements: movementsData, // Récupération des préférences liées aux mouvements
    );
  }
}
