import 'package:gaia/model/app_user.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? emailError;
  String? passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    identifierController.dispose();
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
                  const SizedBox(height: 40),
                  _buildHeader(theme),
                  const SizedBox(height: 30),
                  _buildLoginForm(theme),
                  const SizedBox(height: 20),
                  _buildFooter(theme),
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
        Container(
          width: 100,
          height: 100,
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
            Icons.palette,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bienvenue',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connectez-vous pour découvrir l\'art',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
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
              controller: identifierController,
              hintText: "Email ou Nom d'utilisateur",
              errorText: emailError,
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
            const SizedBox(height: 24),
            _buildLoginButton(theme),
            const SizedBox(height: 16),
            _buildDivider(theme),
            const SizedBox(height: 16),
            _buildGoogleButton(theme),
            const SizedBox(height: 20),
            _buildCreateAccountButton(theme),
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
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => login(context),
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
                "Se connecter",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading
            ? null
            : () async {
                await signInWithGoogle(context);
              },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  'https://developers.google.com/identity/images/g-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        label: Text(
          "Continuer avec Google",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton(ThemeData theme) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationPage(),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: RichText(
        text: TextSpan(
          text: "Pas encore de compte ? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          children: [
            TextSpan(
              text: "Créer un compte",
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

  Widget _buildFooter(ThemeData theme) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "🚧 Mode Développeur",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      emailError = null;
      passwordError = null;
    });

    String email;
    if (identifierController.text.contains('@')) {
      email = identifierController.text;
    } else {
      final userCollection = _firestore.collection('accounts');
      final snapshot = await userCollection
          .where('username', isEqualTo: identifierController.text)
          .get();

      if (snapshot.docs.isNotEmpty) {
        email = snapshot.docs[0]['email'];
      } else {
        setState(() {
          emailError = "Nom d'utilisateur non trouvé";
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final userDoc =
            await _firestore.collection('accounts').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Créer un objet AppUser
          AppUser user = AppUser(
            id: firebaseUser.uid,
            email: userData['email'],
            username: userData['username'],
            googleAccount: userData['googleAccount'] ?? false,
            liked: List<String>.from(userData['liked'] ?? []),
            collection: List<String>.from(userData['collection'] ?? []),
            visitedMuseum: userData['visitedMuseum'] ?? '',
            profilePhoto: userData['profilePhoto'] ?? '',
            preferences: userData['preferences'] ?? {},
            movements: Map<String, double>.from(
                userData['preferences']?['movement'] ?? {}),
          );

          // Ajouter l'utilisateur au UserProvider
          // ignore: use_build_context_synchronously
          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // Redirection vers la page d'accueil
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        passwordError = "Erreur de connexion : $e";
        _isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc =
            await _firestore.collection('accounts').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('accounts').doc(firebaseUser.uid).set({
            'email': firebaseUser.email,
            'username': firebaseUser.displayName,
            'googleAccount': true,
          });
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        AppUser user = AppUser(
          id: firebaseUser.uid,
          email: userData['email'],
          username: userData['username'],
          googleAccount: true,
          liked: List<String>.from(userData['liked'] ?? []),
          collection: List<String>.from(userData['collection'] ?? []),
          visitedMuseum: userData['visitedMuseum'] ?? '',
          profilePhoto: userData['profilePhoto'] ?? '',
          preferences: userData['preferences'] ?? {},
          movements: Map<String, double>.from(
              userData['preferences']?['movement'] ?? {}),
        );

        // ignore: use_build_context_synchronously
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $e")),
      );
    }
  }
}
