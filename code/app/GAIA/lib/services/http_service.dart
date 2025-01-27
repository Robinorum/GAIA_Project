import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HttpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to get Firebase ID token
  Future<String?> getIdToken() async {
    User? user = _auth.currentUser;
    return user?.getIdToken();
  }

  // Generic method to make GET requests
  Future<http.Response> get(String endpoint) async {
    String? token = await getIdToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Generic method to make POST requests
  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    String? token = await getIdToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  // Generic method to make PUT requests
  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    String? token = await getIdToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.put(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  // Generic method to make DELETE requests
  Future<http.Response> delete(String endpoint) async {
    String? token = await getIdToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.delete(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }
  // You can also add methods for POST, PUT, DELETE, etc.
}
