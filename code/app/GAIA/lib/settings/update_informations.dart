import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gaia/config/ip_config.dart';
import 'package:gaia/services/http_service.dart';

// ====================== CHANGE EMAIL PAGE ======================
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final HttpService httpService = HttpService();
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _changeEmail() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (user == null || user.email == null) {
      setState(() {
        _message = "Utilisateur non connecté.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail);

      final response = await httpService.put(
        IpConfig.userEmail(user.uid),
        body: {'email': newEmail},
      );

      setState(() {
        _isSuccess = response.statusCode == 200;
        _message = _isSuccess
            ? "Email changé avec succès ! Vérifiez votre boîte de réception."
            : "Une erreur est survenue. Veuillez réessayer plus tard.";
      });
    } catch (_) {
      setState(() {
        _message =
            "Impossible de changer l'email. Vérifiez vos informations et réessayez.";
        _isSuccess = false;
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildModernLayout(
      title: "Changer l'email",
      icon: Icons.email_outlined,
      iconColor: Colors.blue,
      fields: [
        _buildModernTextField(
          controller: _emailController,
          label: "Nouvelle adresse email",
          hint: "exemple@domaine.com",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildModernTextField(
          controller: _passwordController,
          label: "Mot de passe actuel",
          hint: "Entrez votre mot de passe",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
      onSubmit: _changeEmail,
      loading: _loading,
      message: _message,
      isSuccess: _isSuccess,
      buttonLabel: "Mettre à jour l'email",
    );
  }
}

// ====================== CHANGE PASSWORD PAGE ======================
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final HttpService httpService = HttpService();
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _changePassword() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (user == null || user.email == null) {
      setState(() {
        _message = "Utilisateur non connecté.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _message = "Les mots de passe ne correspondent pas.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    if (newPassword.length < 14) {
      setState(() {
        _message = "Le mot de passe doit contenir au moins 6 caractères.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      setState(() {
        _message = "Mot de passe changé avec succès !";
        _isSuccess = true;
      });
    } catch (_) {
      setState(() {
        _message =
            "Impossible de changer le mot de passe. Vérifiez vos informations et réessayez.";
        _isSuccess = false;
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildModernLayout(
      title: "Changer le mot de passe",
      icon: Icons.lock_outline,
      iconColor: Colors.orange,
      fields: [
        _buildModernTextField(
          controller: _currentPasswordController,
          label: "Mot de passe actuel",
          hint: "Entrez votre mot de passe actuel",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        _buildModernTextField(
          controller: _newPasswordController,
          label: "Nouveau mot de passe",
          hint: "Au moins 14 caractères",
          icon: Icons.lock_reset,
          isPassword: true,
        ),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: "Confirmer le mot de passe",
          hint: "Retapez le nouveau mot de passe",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
      onSubmit: _changePassword,
      loading: _loading,
      message: _message,
      isSuccess: _isSuccess,
      buttonLabel: "Mettre à jour le mot de passe",
    );
  }
}

// ====================== CHANGE USERNAME PAGE ======================
class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final HttpService httpService = HttpService();
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _changeUsername() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final newUsername = _usernameController.text.trim();
    final password = _passwordController.text;

    if (user == null || user.email == null) {
      setState(() {
        _message = "Utilisateur non connecté.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    if (newUsername.isEmpty || newUsername.length < 3) {
      setState(() {
        _message = "Le nom d'utilisateur doit contenir au moins 3 caractères.";
        _loading = false;
        _isSuccess = false;
      });
      return;
    }

    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);

      final response = await httpService.put(
        IpConfig.userUsername(user.uid),
        body: {'username': newUsername},
      );

      setState(() {
        _isSuccess = response.statusCode == 200;
        _message = _isSuccess
            ? "Nom d'utilisateur changé avec succès !"
            : "Une erreur est survenue. Veuillez réessayer plus tard.";
      });
    } catch (_) {
      setState(() {
        _message =
            "Impossible de changer le nom d'utilisateur. Vérifiez vos informations et réessayez.";
        _isSuccess = false;
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildModernLayout(
      title: "Changer le nom d'utilisateur",
      icon: Icons.person_outline,
      iconColor: Colors.green,
      fields: [
        _buildModernTextField(
          controller: _usernameController,
          label: "Nouveau nom d'utilisateur",
          hint: "Au moins 3 caractères",
          icon: Icons.person_outline,
          keyboardType: TextInputType.text,
        ),
        _buildModernTextField(
          controller: _passwordController,
          label: "Mot de passe actuel",
          hint: "Confirmez avec votre mot de passe",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
      onSubmit: _changeUsername,
      loading: _loading,
      message: _message,
      isSuccess: _isSuccess,
      buttonLabel: "Mettre à jour le nom",
    );
  }
}

// ====================== SHARED UI COMPONENTS ======================
Widget _buildModernLayout({
  required String title,
  required IconData icon,
  required Color iconColor,
  required List<Widget> fields,
  required VoidCallback onSubmit,
  required bool loading,
  required String? message,
  required bool isSuccess,
  required String buttonLabel,
}) {
  return Builder(
    builder: (context) => Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 32),

              // Main Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Veuillez remplir les informations ci-dessous",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Form Fields
                      ...fields.map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: field,
                          )),

                      const SizedBox(height: 12),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: iconColor,
                            foregroundColor: Colors.white,
                            elevation: loading ? 0 : 2,
                            shadowColor: iconColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: loading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.grey[600]!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Mise à jour...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      buttonLabel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Message
                      if (message != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSuccess
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSuccess ? Icons.check_circle : Icons.error,
                                color: isSuccess ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: isSuccess
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ],
  );
}
