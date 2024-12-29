import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthentificationService {
  final String urlReg = "http://127.0.0.1:5000/api/registration/";
  final String urlLogin = "http://127.0.0.1:5000/api/login/";

  Future<Map<String, dynamic>> registerUser(String email, String password, String username) async {
    try {
      final response = await http.post(
        Uri.parse(urlReg),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'],
        };  
      } 
      else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (data['error'] == "Cet email est déjà utilisé !") {
          return data['error'];  
        }
        else if (data['error'] == "Mot de passe trop faible. Il doit avoir au moins 14 caractères, inclure une majuscule, une minuscule, un chiffre et un caractère spécial.") {
          return {
          "success": false,
          "message": data['error'],
        };
        } else {
          return {
          "success": false,
          "message": data['error'],
          }; 
        }
      } 
      else if (response.statusCode == 500) {
        final data = jsonDecode(response.body);
         return {
          "success": false,
          "message": data['error'],
          }; 
      } 
      else {
        return {
          "success": false,
          "message": "erreur inconnue",
          }; 
      }
    } catch (e) {
      return {
          "success": false,
          "message": "erreur lors de la requête",
          }; 
    }
  }

   Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(urlLogin),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          "success": false,
          "message": data['error'],
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur lors de la requête : ${e.toString()}",
      };
    }
  }
}
