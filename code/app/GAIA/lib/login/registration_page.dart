import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'profilage_page.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/model/app_user.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? emailError;
  String? usernameError;
  String? passwordError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(theme),
                  const SizedBox(height: 30),
                  _buildRegistrationForm(theme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Créer un compte',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rejoignez notre communauté d\'art',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: emailController,
              hintText: "Adresse email",
              errorText: emailError,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: usernameController,
              hintText: "Nom d'utilisateur",
              errorText: usernameError,
              prefixIcon: Icons.person_outline,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              hintText: "Mot de passe",
              errorText: passwordError,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildPasswordRequirements(theme),
            const SizedBox(height: 24),
            _buildSignUpButton(theme),
            const SizedBox(height: 20),
            _buildLoginLink(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        prefixIcon: Icon(
          prefixIcon,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      onChanged: (value) {
        // Clear errors when user starts typing
        if (controller == emailController && emailError != null) {
          setState(() => emailError = null);
        } else if (controller == usernameController && usernameError != null) {
          setState(() => usernameError = null);
        } else if (controller == passwordController && passwordError != null) {
          setState(() => passwordError = null);
        }
      },
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exigences du mot de passe :',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          _buildRequirement('Au moins 14 caractères', theme),
          _buildRequirement('Une lettre majuscule', theme),
          _buildRequirement('Une lettre minuscule', theme),
          _buildRequirement('Un chiffre', theme),
          _buildRequirement('Un caractère spécial (@\$!%*?&)', theme),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 4,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                "Créer mon compte",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: RichText(
        text: TextSpan(
          text: "Déjà un compte ? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          children: [
            TextSpan(
              text: "Se connecter",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignUp() {
    if (emailController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      signUp();
    } else {
      _showValidationErrors();
    }
  }

  void _showValidationErrors() {
    setState(() {
      if (emailController.text.isEmpty) {
        emailError = "L'email est requis";
      }
      if (usernameController.text.isEmpty) {
        usernameError = "Le nom d'utilisateur est requis";
      }
      if (passwordController.text.isEmpty) {
        passwordError = "Le mot de passe est requis";
      }
    });
  }

  Future<void> signUp() async {
    setState(() {
      _isLoading = true;
      emailError = null;
      usernameError = null;
      passwordError = null;
    });

    try {
      // Check if the email already exists
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailController.text)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        setState(() {
          emailError = "Cet email est déjà utilisé";
          _isLoading = false;
        });
        return;
      }

      // Check if the username already exists
      final usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameController.text)
          .get();
      if (usernameSnapshot.docs.isNotEmpty) {
        setState(() {
          usernameError = "Ce nom d'utilisateur est déjà utilisé";
          _isLoading = false;
        });
        return;
      }

      // Validate password
      if (passwordController.text.length < 14 ||
          !RegExp(r'[A-Z]').hasMatch(passwordController.text) ||
          !RegExp(r'[a-z]').hasMatch(passwordController.text) ||
          !RegExp(r'\d').hasMatch(passwordController.text) ||
          !RegExp(r'[@$!%*?&]').hasMatch(passwordController.text)) {
        setState(() {
          passwordError = "Le mot de passe ne respecte pas les exigences";
          _isLoading = false;
        });
        return;
      }

      // Create user with FirebaseAuth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Save user data to Firestore
      await _firestore
          .collection('accounts')
          .doc(userCredential.user?.uid)
          .set({
        'email': emailController.text,
        'username': usernameController.text,
        'googleAccount': false,
        'brands': [],
        'reco': [],
        'previous_reco': [],
        'collection': [],
        'visitedMuseum': '',
        'profilePhoto': '',
        'preferences': {'movements': {}},
        'quests': [],
      });

      // Fetch the created user's data
      final userDoc = await _firestore
          .collection('accounts')
          .doc(userCredential.user?.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create AppUser object
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        email: userData['email'],
        username: userData['username'],
        googleAccount: userData['googleAccount'] ?? false,
        liked: List<String>.from(userData['liked'] ?? []),
        collection: List<String>.from(userData['collection'] ?? []),
        visitedMuseum: userData['visitedMuseum'] ?? '',
        profilePhoto: userData['profilePhoto'] ?? '',
        preferences: userData['preferences'] ?? {},
        movements: Map<String, double>.from(
            userData['preferences']?['movements'] ?? {}),
      );

      // Add the user to the UserProvider
      // ignore: use_build_context_synchronously
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Compte créé avec succès !"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to ProfilagePage
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const ProfilagePage()),
      );
    } catch (e) {
      setState(() {
        passwordError = "Erreur lors de l'inscription : $e";
        _isLoading = false;
      });
    }
  }
}
