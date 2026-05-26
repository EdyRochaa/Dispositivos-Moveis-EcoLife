// ============================================================
// ECOLIFE PRO - Aplicação Completa Profissional
// ============================================================
// Estrutura:
//   1. Bootstrap, Theme System, Theme Provider
//   2. Auth Service (Firebase)
//   3. App State (estado compartilhado)
//   4. Tappable widget (cursor pointer + hover)
//   5. Splash Screen animada
//   6. Login & Signup
//   7. Main Scaffold com bottom nav
//   8. Telas: Inicio, Impacto, Progresso, EcoGuerreiros, Perfil
//   9. Sub-telas: Habitos, Privacidade, Notificacoes
//  10. Widgets: Header, BottomNav, AnimatedGauge, BarChart, DonutChart, etc.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pdf/pdf.dart' show PdfColor, PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EcoLifeApp());
}

// ============================================================
// 1. THEME SYSTEM
// ============================================================

class AppColors {
  // Light
  static const lightBg = Color(0xFFF5F7F5);
  static const lightCard = Colors.white;
  static const lightText = Color(0xFF1A1A1A);
  static const lightSubText = Color(0xFF666666);

  // Dark
  static const darkBg = Color(0xFF0F1419);
  static const darkCard = Color(0xFF1A2128);
  static const darkText = Color(0xFFE8EAED);
  static const darkSubText = Color(0xFF9AA0A6);
  static const darkBorder = Color(0xFF2A323C);

  // Brand greens
  static const greenPrimary = Color(0xFF2E7D32);
  static const greenDark = Color(0xFF1B5E20);
  static const greenLight = Color(0xFF66BB6A);
  static const greenAccent = Color(0xFF4CAF50);
  static const greenSurface = Color(0xFFE8F5E9);
}

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._();
  ThemeProvider._();
  // Modo escuro removido — app fixado em tema claro.
  final bool _isDark = false;
  bool get isDark => _isDark;
  void toggle() {
    // No-op: tema claro fixo.
  }

  Color get bg => _isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get card => _isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get text => _isDark ? AppColors.darkText : AppColors.lightText;
  Color get subText => _isDark ? AppColors.darkSubText : AppColors.lightSubText;
  Color get border => _isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);
  Color get shadow =>
      _isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06);
}

class EcoLifeApp extends StatelessWidget {
  const EcoLifeApp({super.key});

  // Chave global do navigator — permite navegar de qualquer lugar do app
  // mesmo se o BuildContext atual já tiver sido descartado.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final isDark = ThemeProvider.instance.isDark;
        return MaterialApp(
          title: 'EcoLife',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: ThemeProvider.instance.bg,
            fontFamily: 'Roboto',
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.greenPrimary)
                : const ColorScheme.light(primary: AppColors.greenPrimary),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ============================================================
// 2. AUTH SERVICE
// ============================================================

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static bool _isUnitEmail(String email) {
    return email.trim().toLowerCase().endsWith('@souunit.com.br');
  }

  static Future<String?> login(String email, String password) async {
    if (!_isUnitEmail(email)) {
      return 'Acesso permitido apenas para e-mails @souunit.com.br';
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Usuário não encontrado';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos';
        case 'invalid-email':
          return 'E-mail inválido';
        case 'user-disabled':
          return 'Conta desativada';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente mais tarde';
        default:
          return 'Erro ao fazer login. Tente novamente';
      }
    }
  }

  static Future<String?> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      return 'Preencha todos os campos';
    }
    if (!_isUnitEmail(email)) {
      return 'Cadastro permitido apenas para e-mails @souunit.com.br';
    }
    if (password.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
    if (password != confirmPassword) return 'As senhas não coincidem';
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Telefone inválido';
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'E-mail já cadastrado';
        case 'invalid-email':
          return 'E-mail inválido';
        case 'weak-password':
          return 'Senha muito fraca (mínimo 6 caracteres)';
        case 'operation-not-allowed':
          return 'Cadastro com e-mail não está habilitado no Firebase';
        case 'network-request-failed':
          return 'Sem conexão com a internet';
        default:
          return 'Erro: ${e.code} - ${e.message}';
      }
    }
  }

  static Future<String?> loginWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('profile');
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return 'Login cancelado';
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
      // Garante que photoURL e displayName venham populados
      await _auth.currentUser?.reload();

      // Valida domínio após login
      final email = _auth.currentUser?.email ?? '';
      if (!_isUnitEmail(email)) {
        await logout();
        return 'Acesso permitido apenas para e-mails @souunit.com.br';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Erro ao entrar com Google';
    } catch (_) {
      return 'Erro ao entrar com Google';
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<void> saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String type,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'phone': phone,
      'type': type,
      'criado_por': email,
      'usuario_logado': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateUserInFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final email = _auth.currentUser?.email ?? '';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      ...data,
      'usuario_logado': email,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteUserFromFirestore(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  static Future<void> loadUserFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final data = doc.data()!;
        AppState.instance.setProfileData(
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          type: data['type'] ?? 'Cliente',
        );
      }
    } catch (_) {
      // Ignora erro silenciosamente e continua
    }
  }
}

// ============================================================
// 3. APP STATE
// ============================================================

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  final Map<String, bool> dailyHabits = {
    'Reduzir tempo de banho': true,
    'Economia de energia': false,
    'Reciclagem correta': false,
    'Redução de lixo': false,
    'Uso de transporte público': false,
    'Alimentação sustentável': false,
  };

  static const Map<String, IconData> habitIcons = {
    'Reduzir tempo de banho': Icons.shower,
    'Economia de energia': Icons.flash_on,
    'Reciclagem correta': Icons.recycling,
    'Redução de lixo': Icons.delete_outline,
    'Uso de transporte público': Icons.directions_bus,
    'Alimentação sustentável': Icons.restaurant,
  };

  int streak = 5;
  int greenScore = 850;
  bool showLocation = true;
  bool notificationsEnabled = true;
  bool analyticsEnabled = false;
  bool privacyMode = false;

  // Subcategorias de notificação
  bool notifyDailyHabits = true;
  bool notifyAchievements = true;
  bool notifyFriends = false;
  bool notifyTips = true;

  // User profile data (preenchido no cadastro)
  String userName = '';
  String userPhone = '';
  String userSurname = '';
  String userCity = '';
  String userState = '';
  String userCountry = 'Brasil';
  String userType = 'Cliente';

  void setProfileData({
    String? name,
    String? phone,
    String? surname,
    String? city,
    String? state,
    String? country,
    String? type,
  }) {
    if (name != null) userName = name;
    if (phone != null) userPhone = phone;
    if (surname != null) userSurname = surname;
    if (city != null) userCity = city;
    if (state != null) userState = state;
    if (country != null) userCountry = country;
    if (type != null) userType = type;
    notifyListeners();
  }

  final List<double> monthlyData = [
    0.55,
    0.75,
    0.7,
    0.3,
    0.5,
    0.55,
    0.8,
    0.95,
    0.4,
    0.6,
    0.8,
    0.85,
  ];
  final List<String> months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  final List<Map<String, dynamic>> globalRanking = [
    {'name': 'DANTAS', 'points': 2840},
    {'name': 'JOSE', 'points': 2510},
    {'name': 'Alves', 'points': 2200},
    {'name': 'você', 'points': 850, 'isMe': true},
    {'name': '******', 'points': 720},
  ];

  final List<Map<String, dynamic>> friendsRanking = [
    {'name': 'JOSE. A', 'points': 1850},
    {'name': 'OLIVIA. S', 'points': 1620},
    {'name': 'MARCOS. A', 'points': 1340},
    {'name': '******', 'points': 0},
    {'name': '******', 'points': 0},
  ];

  List<Map<String, dynamic>> get recentActivities {
    final completed = dailyHabits.entries
        .where((e) => e.value)
        .map((e) => {'name': e.key, 'icon': habitIcons[e.key]})
        .toList();
    return completed.isEmpty
        ? [
            {'name': 'Reduzir tempo de banho', 'icon': Icons.shower},
            {'name': 'Economizar energia', 'icon': Icons.flash_on},
            {'name': 'Reciclar corretamente', 'icon': Icons.recycling},
            {'name': 'Reduzir lixo', 'icon': Icons.delete_outline},
            {
              'name': 'Utilizar transporte público',
              'icon': Icons.directions_bus,
            },
          ]
        : completed;
  }

  int get habitsCompletedToday => dailyHabits.values.where((v) => v).length;
  int get totalHabits => dailyHabits.length;
  double get habitsProgress => habitsCompletedToday / totalHabits;

  void toggleHabit(String habit) {
    dailyHabits[habit] = !(dailyHabits[habit] ?? false);
    greenScore = 800 + habitsCompletedToday * 25;
    notifyListeners();
  }

  void setSetting(String key, bool value) {
    switch (key) {
      case 'location':
        showLocation = value;
        break;
      case 'notifications':
        notificationsEnabled = value;
        break;
      case 'analytics':
        analyticsEnabled = value;
        break;
      case 'privacy':
        privacyMode = value;
        break;
      case 'notify_daily_habits':
        notifyDailyHabits = value;
        break;
      case 'notify_achievements':
        notifyAchievements = value;
        break;
      case 'notify_friends':
        notifyFriends = value;
        break;
      case 'notify_tips':
        notifyTips = value;
        break;
    }
    notifyListeners();
  }
}

// ============================================================
// 4. TAPPABLE (cursor pointer + hover)
// ============================================================

class Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleOnHover;
  final BorderRadius? borderRadius;
  final bool addElevation;

  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleOnHover = 1.0,
    this.borderRadius,
    this.addElevation = false,
  });

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovering ? widget.scaleOnHover : 1.0);
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          if (widget.onTap != null) {
            HapticFeedback.lightImpact();
            widget.onTap!();
          }
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: widget.addElevation && _hovering
                ? BoxDecoration(
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 5. SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5)),
    );
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _navigate();
  }

  void _navigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await AuthService.loadUserFromFirestore(user.uid);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            user != null ? const MainScaffold() : const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/Logo_EcoLife.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        'Bem-vindo ao EcoLife',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Serviços sustentáveis para você',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.7),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 6. LOGIN & SIGNUP (mantidos do anterior - resumido)
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));
    _cardController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await AuthService.login(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (error != null) {
      _passwordController.clear();
      setState(() {
        _isLoading = false;
        _error = error;
        _obscurePassword = true;
      });
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AuthService.loadUserFromFirestore(user.uid);
        AuthService.updateUserInFirestore(
          uid: user.uid,
          data: {'lastLogin': FieldValue.serverTimestamp()},
        ).catchError((_) {});
      }
      if (!mounted) return;
      _goHome();
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });
    final error = await AuthService.loginWithGoogle();
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isGoogleLoading = false;
        _error = error;
      });
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AuthService.loadUserFromFirestore(user.uid);
        AuthService.updateUserInFirestore(
          uid: user.uid,
          data: {'lastLogin': FieldValue.serverTimestamp()},
        ).catchError((_) {});
      }
      if (!mounted) return;
      _goHome();
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainScaffold(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double w = constraints.maxWidth > 500 ? 400 : double.infinity;
                return FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: w,
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 25,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 320,
                            width: 320,
                            child: EcoLogo(),
                          ),
                          const SizedBox(height: 20),
                          EcoTextField(
                            hintText: 'E-mail',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                          ),
                          EcoTextField(
                            hintText: 'Senha',
                            controller: _passwordController,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            icon: Icons.lock_outline,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _ErrorBox(message: _error!),
                          ],
                          const SizedBox(height: 24),
                          Tappable(
                            onTap: _isLoading ? null : _login,
                            scaleOnHover: 1.02,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade500,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'ENTRAR',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.black12,
                                  thickness: 1.5,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'ou',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.black12,
                                  thickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GoogleSignInButton(
                            isLoading: _isGoogleLoading,
                            onTap: _isGoogleLoading ? null : _loginGoogle,
                          ),
                          const SizedBox(height: 20),
                          Tappable(
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, a, __) => const SignUpScreen(),
                                transitionsBuilder: (_, a, __, child) =>
                                    SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(1, 0),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: a,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                transitionDuration: const Duration(
                                  milliseconds: 400,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Ainda não tem uma conta?\n',
                                    ),
                                    TextSpan(
                                      text: 'Cadastre-se aqui',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  String _userType = 'Cliente';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));
    _cardController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await AuthService.register(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      phone: _phoneController.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
    } else {
      // Salvar nome e dados no Firebase + AppState
      final user = FirebaseAuth.instance.currentUser;
      if (_nameController.text.trim().isNotEmpty) {
        await user?.updateDisplayName(_nameController.text.trim());
      }
      AppState.instance.setProfileData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        type: _userType,
      );
      // Salvar no Firestore
      if (user != null) {
        try {
          await AuthService.saveUserToFirestore(
            uid: user.uid,
            email: user.email ?? '',
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            type: _userType,
          );
        } catch (e) {
          debugPrint('Erro ao salvar no Firestore: $e');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conta criada com sucesso! 🎉'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const MainScaffold(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double w = constraints.maxWidth > 500 ? 450 : double.infinity;
                return FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: w,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 25,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Tappable(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 180,
                            width: 180,
                            child: EcoLogo(),
                          ),
                          const SizedBox(height: 20),
                          GoogleSignInButton(
                            onTap: () async {
                              final error = await AuthService.loginWithGoogle();
                              if (!context.mounted) return;
                              if (error != null) {
                                setState(() => _error = error);
                              } else {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MainScaffold(),
                                  ),
                                  (_) => false,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.black12,
                                  thickness: 1.5,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'ou',
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.black12,
                                  thickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          EcoTextField(
                            hintText: 'Nome completo',
                            controller: _nameController,
                            icon: Icons.person_outline,
                          ),
                          EcoTextField(
                            hintText: 'E-mail',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            icon: Icons.email_outlined,
                          ),
                          EcoTextField(
                            hintText: 'Senha (mín. 6 caracteres)',
                            controller: _passwordController,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            icon: Icons.lock_outline,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          EcoTextField(
                            hintText: 'Confirmar senha',
                            controller: _confirmController,
                            isPassword: true,
                            obscureText: _obscureConfirm,
                            icon: Icons.lock_outline,
                            onTogglePassword: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          EcoTextField(
                            hintText: 'Telefone (DDD) XXXXX-XXXX',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_outlined,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _ErrorBox(message: _error!),
                          ],
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _RadioOption(
                                label: 'Prestador de serviços',
                                value: 'Prestador',
                                groupValue: _userType,
                                onChanged: (v) =>
                                    setState(() => _userType = v!),
                              ),
                              _RadioOption(
                                label: 'Cliente',
                                value: 'Cliente',
                                groupValue: _userType,
                                onChanged: (v) =>
                                    setState(() => _userType = v!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Tappable(
                            onTap: _isLoading ? null : _register,
                            scaleOnHover: 1.02,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade500,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'CRIAR CONTA',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 7. MAIN SCAFFOLD
// ============================================================

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    InicioScreen(),
    ImpactoScreen(),
    ProgressoScreen(),
    EcoGuerreirosScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, ThemeProvider.instance]),
      builder: (context, _) => Scaffold(
        backgroundColor: ThemeProvider.instance.bg,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: EcoBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ============================================================
// 8. SCREENS - INÍCIO
// ============================================================

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, ThemeProvider.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final theme = ThemeProvider.instance;
        return CollapsibleHeaderPage(
          title: 'INÍCIO',
          child: Column(
            children: [
              // Gauge bonita
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.isDark
                          ? [const Color(0xFF1B5E20), const Color(0xFF0D3D11)]
                          : [Colors.white, const Color(0xFFF1F8E9)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.green.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            color: theme.isDark
                                ? Colors.white70
                                : Colors.green.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Green Score',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: theme.isDark
                                  ? Colors.white70
                                  : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedGauge(
                        value: state.greenScore / 1000,
                        score: state.greenScore,
                        isDark: theme.isDark,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: state.greenScore > 700
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.greenScore > 700
                                  ? Icons.trending_up
                                  : Icons.trending_flat,
                              color: state.greenScore > 700
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.greenScore > 700
                                  ? 'Excelente progresso!'
                                  : 'Continue assim!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: state.greenScore > 700
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Stats rápidas
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.2,
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department,
                        iconColor: Colors.orange,
                        value: '${state.streak}',
                        label: 'DIAS SEGUIDOS',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        value:
                            '${state.habitsCompletedToday}/${state.totalHabits}',
                        label: 'HÁBITOS HOJE',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.3,
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dicas Diárias',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._tips.map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.eco,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'ATIVIDADES RECENTES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                state.recentActivities.take(5).length,
                (i) => _AnimatedEntry(
                  controller: _entryController,
                  delay: 0.5 + (i * 0.05),
                  child: _ActivityRow(activity: state.recentActivities[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _tips = [
    'Apoie causas ambientais',
    'Leve sua própria garrafa reutilizável',
    'Dê novo uso aos materiais',
    'Consuma de forma consciente',
    'Plante uma árvore',
  ];
}

// ============================================================
// IMPACTO
// ============================================================

class ImpactoScreen extends StatefulWidget {
  const ImpactoScreen({super.key});
  @override
  State<ImpactoScreen> createState() => _ImpactoScreenState();
}

class _ImpactoScreenState extends State<ImpactoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, ThemeProvider.instance]),
      builder: (context, _) {
        final theme = ThemeProvider.instance;
        return CollapsibleHeaderPage(
          title: 'IMPACTO SUSTENTÁVEL',
          child: Column(
            children: [
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.0,
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CARBONO REDUZIDO (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: AnimatedBarChart(
                          data: AppState.instance.monthlyData,
                          labels: AppState.instance.months,
                          controller: _entryController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.3,
                child: _SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _DonutCard(
                          label: 'Água Economizada',
                          value: 0.65,
                          color: Colors.blue.shade400,
                          icon: Icons.water_drop,
                          iconColor: Colors.blue.shade600,
                          unit: 'L',
                          amount: '1.245',
                          controller: _entryController,
                          delay: 0.4,
                        ),
                      ),
                      Container(width: 1, height: 140, color: theme.border),
                      Expanded(
                        child: _DonutCard(
                          label: 'Carbono Economizado',
                          value: 0.75,
                          color: Colors.green.shade500,
                          icon: Icons.eco,
                          iconColor: Colors.green.shade700,
                          unit: 'kg',
                          amount: '38.5',
                          controller: _entryController,
                          delay: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.5,
                child: Text(
                  'EMBLEMAS DE CONQUISTA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: theme.text,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _AssetBadge(
                      assetPath: 'assets/MESTRE_RECICLAGEM.png',
                      title: 'MESTRE DA\nRECICLAGEM',
                      subtitle: 'RESÍDUOS VALORIZADOS',
                    ),
                    _AssetBadge(
                      assetPath: 'assets/HEROI_PLASTICO.png',
                      title: 'HERÓI\nPLÁSTICO',
                      subtitle: 'META ALCANÇADA',
                    ),
                    _AssetBadge(
                      assetPath: 'assets/ECONOMIZADOR_ENERGIA.png',
                      title: 'ECONOMIZADOR\nDE ENERGIA',
                      subtitle: 'ENERGIA POUPADA',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// PROGRESSO
// ============================================================

class ProgressoScreen extends StatefulWidget {
  const ProgressoScreen({super.key});
  @override
  State<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends State<ProgressoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, ThemeProvider.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final theme = ThemeProvider.instance;
        return CollapsibleHeaderPage(
          title: 'PROGRESSO',
          child: Column(
            children: [
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.0,
                child: _SectionCard(
                  child: SizedBox(
                    height: 200,
                    child: AnimatedBarChart(
                      data: state.monthlyData,
                      labels: state.months,
                      controller: _entryController,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Tappable(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitosScreen()),
                ),
                scaleOnHover: 1.03,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.card, theme.card.withOpacity(0.9)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MARQUE SEUS FEITOS DE HOJE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(state.dailyHabits.length, (i) {
                final entry = state.dailyHabits.entries.elementAt(i);
                return _AnimatedEntry(
                  controller: _entryController,
                  delay: 0.3 + (i * 0.05),
                  child: _HabitCheckRow(
                    icon: AppState.habitIcons[entry.key]!,
                    label: entry.key,
                    checked: entry.value,
                    onChanged: (_) {
                      state.toggleHabit(entry.key);
                      setState(() {});
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ECO-GUERREIROS
// ============================================================

class EcoGuerreirosScreen extends StatefulWidget {
  const EcoGuerreirosScreen({super.key});
  @override
  State<EcoGuerreirosScreen> createState() => _EcoGuerreirosScreenState();
}

class _EcoGuerreirosScreenState extends State<EcoGuerreirosScreen>
    with SingleTickerProviderStateMixin {
  bool _isGlobal = true;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final list = _isGlobal ? state.globalRanking : state.friendsRanking;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green.shade700, Colors.green.shade900],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'ECO-GUERREIROS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade900,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'GLOBAL',
                        active: _isGlobal,
                        onTap: () => setState(() => _isGlobal = true),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'AMIGOS',
                        active: !_isGlobal,
                        onTap: () => setState(() => _isGlobal = false),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                child: Tappable(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        _isGlobal ? 'REMOVER AMIGOS' : 'ADICIONAR AMIGOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isGlobal
                            ? Icons.person_remove_outlined
                            : Icons.person_add_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AnimatedEntry(
                      controller: _entryController,
                      delay: i * 0.06,
                      child: _RankRow(
                        rank: i + 1,
                        name: list[i]['name'] as String,
                        points: list[i]['points'] as int,
                        isMe: list[i]['isMe'] == true,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Tappable(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Impacto compartilhado! 🌱'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  scaleOnHover: 1.02,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'COMPARTILHAR SEU IMPACTO',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PERFIL
// ============================================================

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    // Carregar dados do Firestore ao abrir o perfil
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AuthService.loadUserFromFirestore(user.uid).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppState.instance, ThemeProvider.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email ?? '';
        final name = UserDisplay.fullDisplay(user);
        final theme = ThemeProvider.instance;
        return CollapsibleHeaderPage(
          title: 'PERFIL',
          child: Column(
            children: [
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.0,
                child: Column(
                  children: [
                    _UserAvatar(user: user, size: 110, fontSize: 38),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: theme.subText),
                    ),
                    if (state.userType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          state.userType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.2,
                child: _ProfileFieldsGrid(
                  name: name,
                  email: email,
                  phone: state.userPhone,
                ),
              ),
              const SizedBox(height: 20),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.4,
                child: _ToggleRow(
                  icon: Icons.location_on,
                  label: 'Mostrar localização',
                  value: state.showLocation,
                  onChanged: (v) => state.setSetting('location', v),
                ),
              ),
              if (state.showLocation) ...[
                const SizedBox(height: 12),
                _AnimatedEntry(
                  controller: _entryController,
                  delay: 0.42,
                  child: const LocationMapCard(),
                ),
              ],
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.5,
                child: _NavTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notificações',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
              ),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.55,
                child: _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacidade',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
              ),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.6,
                child: _NavTile(
                  icon: Icons.help_outline,
                  label: 'Ajuda & Suporte',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedEntry(
                controller: _entryController,
                delay: 0.7,
                child: Tappable(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: theme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Sair',
                          style: TextStyle(color: theme.text),
                        ),
                        content: Text(
                          'Deseja encerrar a sessão?',
                          style: TextStyle(color: theme.text),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: theme.text),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            child: Text(
                              'Sair',
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    // Logout com timeout para evitar travamentos do
                    // GoogleSignIn (não bloqueia a navegação se demorar).
                    AuthService.logout().timeout(
                      const Duration(seconds: 3),
                      onTimeout: () {},
                    );
                    // Navegação via navigatorKey global — funciona
                    // mesmo se o context atual já tiver sido descartado.
                    EcoLifeApp.navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  scaleOnHover: 1.01,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'SAIR DA CONTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// 9. SUB-TELAS: Hábitos, Privacidade, Notificações
// ============================================================

class HabitosScreen extends StatelessWidget {
  const HabitosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final theme = ThemeProvider.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([state, theme]),
      builder: (context, _) => Scaffold(
        backgroundColor: theme.bg,
        body: Column(
          children: [
            GreenHeader(
              title: 'HÁBITOS',
              leading: Tappable(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESUMO DO DIA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ResumoQuad(
                            left1Title: 'PROGRESSO DOS HÁBITOS',
                            left1Content:
                                '• Você completou ${state.habitsCompletedToday} de ${state.totalHabits} hábitos hoje\n• Progresso - ${(state.habitsProgress * 100).round()}% concluído',
                            right1Title: 'SEQUÊNCIA',
                            right1Content:
                                '🔥\n• Você está há ${state.streak} dias consecutivos praticando hábitos sustentáveis.',
                            left2Title: 'IMPACTO',
                            left2Content:
                                '• Suas ações de hoje geraram impacto positivo no meio ambiente.\n• Você economizou aproximadamente 12 litros de água.',
                            right2Title: 'DESTAQUE DO DIA',
                            right2Content:
                                '• O hábito que mais se destacou hoje foi Reciclagem correta.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Lista de hábitos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: theme.text,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.menu,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Acompanhe e construa uma rotina mais sustentável',
                                  style: TextStyle(
                                    color: theme.subText,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...state.dailyHabits.keys.map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      h.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme.text,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Tappable(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'REMOVER HÁBITO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Tappable(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ADICIONAR HÁBITO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Histórico',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: theme.text,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.history,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Acompanhe suas atividades',
                                  style: TextStyle(
                                    color: theme.subText,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhum histórico ainda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: theme.text,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Complete seus hábitos diários para acompanhar seu progresso',
                                  style: TextStyle(
                                    color: theme.subText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final theme = ThemeProvider.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([state, theme]),
      builder: (context, _) => Scaffold(
        backgroundColor: theme.bg,
        body: Column(
          children: [
            GreenHeader(
              title: 'PRIVACIDADE',
              leading: Tappable(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Suas informações estão protegidas',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Controle exatamente quais dados são compartilhados e quem pode ver suas atividades.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.subText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ToggleRow(
                      icon: Icons.location_on_outlined,
                      label: 'Mostrar localização',
                      value: state.showLocation,
                      onChanged: (v) => state.setSetting('location', v),
                    ),
                    _ToggleRow(
                      icon: Icons.visibility_outlined,
                      label: 'Perfil público',
                      value: !state.privacyMode,
                      onChanged: (v) => state.setSetting('privacy', !v),
                    ),
                    _ToggleRow(
                      icon: Icons.analytics_outlined,
                      label: 'Análises de uso',
                      value: state.analyticsEnabled,
                      onChanged: (v) => state.setSetting('analytics', v),
                    ),
                    _ToggleRow(
                      icon: Icons.people_outline,
                      label: 'Mostrar para amigos',
                      value: true,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        children: [
                          _LinkTile(
                            label: 'Política de privacidade',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            ),
                          ),
                          Divider(color: theme.border, height: 1),
                          _LinkTile(
                            label: 'Termos de uso',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsOfUseScreen(),
                              ),
                            ),
                          ),
                          Divider(color: theme.border, height: 1),
                          _LinkTile(
                            label: 'Exportar meus dados',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExportDataScreen(),
                              ),
                            ),
                          ),
                          Divider(color: theme.border, height: 1),
                          _LinkTile(
                            label: 'Excluir conta',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeleteAccountScreen(),
                              ),
                            ),
                            danger: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final theme = ThemeProvider.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([state, theme]),
      builder: (context, _) => Scaffold(
        backgroundColor: theme.bg,
        body: Column(
          children: [
            GreenHeader(
              title: 'NOTIFICAÇÕES',
              leading: Tappable(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _ToggleRow(
                      icon: Icons.notifications_active_outlined,
                      label: 'Ativar notificações',
                      value: state.notificationsEnabled,
                      onChanged: (v) => state.setSetting('notifications', v),
                    ),
                    if (state.notificationsEnabled) ...[
                      _ToggleRow(
                        icon: Icons.local_fire_department,
                        label: 'Lembrete diário de hábitos',
                        value: state.notifyDailyHabits,
                        onChanged: (v) =>
                            state.setSetting('notify_daily_habits', v),
                      ),
                      _ToggleRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Conquistas e emblemas',
                        value: state.notifyAchievements,
                        onChanged: (v) =>
                            state.setSetting('notify_achievements', v),
                      ),
                      _ToggleRow(
                        icon: Icons.group,
                        label: 'Atividades de amigos',
                        value: state.notifyFriends,
                        onChanged: (v) => state.setSetting('notify_friends', v),
                      ),
                      _ToggleRow(
                        icon: Icons.campaign_outlined,
                        label: 'Dicas e novidades',
                        value: state.notifyTips,
                        onChanged: (v) => state.setSetting('notify_tips', v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 9b. SUB-TELAS LEGAIS (Política, Termos, Exportar, Excluir)
// ============================================================

class _LegalScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _LegalScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([theme, AppState.instance]),
      builder: (context, _) => Scaffold(
        backgroundColor: theme.bg,
        body: Column(
          children: [
            GreenHeader(
              title: title,
              leading: Tappable(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String heading;
  final String body;
  const _LegalSection({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(fontSize: 13, height: 1.55, color: theme.text),
          ),
        ],
      ),
    );
  }
}

// ----- Política de privacidade -----
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return _LegalScaffold(
      title: 'PRIVACIDADE',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.green.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Última atualização: 24 de maio de 2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Esta Política de Privacidade descreve como o EcoLife coleta, '
          'usa, armazena e protege suas informações pessoais. Ao utilizar '
          'o aplicativo, você concorda com as práticas descritas abaixo.',
          style: TextStyle(fontSize: 13, height: 1.55, color: theme.text),
        ),
        const SizedBox(height: 22),
        const _LegalSection(
          heading: '1. Informações que coletamos',
          body:
              'Coletamos dados fornecidos diretamente por você no cadastro '
              '(nome, sobrenome, e-mail, telefone, cidade, estado e país), '
              'além de informações geradas pelo uso do app (hábitos '
              'sustentáveis registrados, pontuação Green Score, sequências '
              'diárias, conquistas e preferências de configuração). '
              'Quando você faz login com o Google, recebemos seu nome '
              'público, e-mail e foto de perfil fornecidos pela conta.',
        ),
        const _LegalSection(
          heading: '2. Como usamos suas informações',
          body:
              'Utilizamos seus dados para: (a) autenticar e identificar '
              'sua conta; (b) personalizar sua experiência no app, '
              'incluindo cálculo de impacto ambiental, ranking de '
              'EcoGuerreiros e emblemas de conquista; (c) enviar '
              'notificações relevantes (quando habilitadas); '
              '(d) melhorar a performance e a segurança do serviço; '
              '(e) cumprir obrigações legais aplicáveis.',
        ),
        const _LegalSection(
          heading: '3. Compartilhamento de dados',
          body:
              'O EcoLife não vende seus dados pessoais. Compartilhamos '
              'informações apenas com: provedores de infraestrutura '
              '(Firebase / Google Cloud) estritamente necessários para '
              'a operação do app; autoridades públicas, quando exigido '
              'por lei ou decisão judicial; e outros usuários, apenas '
              'no que você optar por tornar público (ex.: presença no '
              'ranking de EcoGuerreiros).',
        ),
        const _LegalSection(
          heading: '4. Armazenamento e segurança',
          body:
              'Seus dados ficam armazenados em servidores Google Firebase, '
              'com criptografia em trânsito (TLS) e em repouso. O acesso '
              'interno é restrito a sistemas autenticados. Senhas nunca '
              'são armazenadas em texto puro. Apesar dos esforços, '
              'nenhum sistema é 100% imune a falhas, e você é responsável '
              'por manter suas credenciais em sigilo.',
        ),
        const _LegalSection(
          heading: '5. Seus direitos (LGPD)',
          body:
              'Em conformidade com a Lei Geral de Proteção de Dados '
              '(Lei 13.709/2018), você pode, a qualquer momento: '
              'confirmar a existência de tratamento; acessar seus dados; '
              'corrigir informações incompletas, inexatas ou desatualizadas; '
              'solicitar a anonimização, bloqueio ou eliminação de dados '
              'desnecessários; solicitar a portabilidade dos dados; '
              'revogar consentimentos previamente concedidos. Para '
              'exercer qualquer desses direitos, utilize a opção '
              '"Exportar meus dados" ou "Excluir conta" nesta tela.',
        ),
        const _LegalSection(
          heading: '6. Retenção de dados',
          body:
              'Mantemos seus dados enquanto sua conta estiver ativa. '
              'Caso a conta seja excluída, removemos suas informações '
              'pessoais em até 30 dias, exceto quando a retenção for '
              'exigida por lei (ex.: obrigações fiscais ou registros '
              'de segurança).',
        ),
        const _LegalSection(
          heading: '7. Cookies e tecnologias similares',
          body:
              'O app pode utilizar identificadores locais e tokens de '
              'sessão para manter você autenticado e lembrar suas '
              'preferências. Você pode limpar esses dados a qualquer '
              'momento pelas configurações do dispositivo.',
        ),
        const _LegalSection(
          heading: '8. Crianças e adolescentes',
          body:
              'O EcoLife não é direcionado a menores de 13 anos. '
              'Não coletamos intencionalmente dados desse público. '
              'Caso identifiquemos um cadastro de menor sem autorização '
              'do responsável, a conta será removida.',
        ),
        const _LegalSection(
          heading: '9. Alterações nesta política',
          body:
              'Podemos atualizar esta Política de Privacidade '
              'periodicamente. Em caso de mudanças relevantes, '
              'avisaremos no app antes da entrada em vigor. '
              'O uso contínuo após a atualização indica concordância '
              'com a nova versão.',
        ),
        const _LegalSection(
          heading: '10. Contato e Encarregado (DPO)',
          body:
              'Dúvidas, solicitações ou denúncias podem ser enviadas '
              'para o e-mail: privacidade@ecolife.app. '
              'Buscamos responder todas as solicitações em até 15 dias '
              'úteis, conforme determina a LGPD.',
        ),
      ],
    );
  }
}

// ----- Termos de uso -----
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return _LegalScaffold(
      title: 'TERMOS DE USO',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.gavel_outlined, color: Colors.green.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Versão 1.0 — vigente desde 24 de maio de 2026',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Estes Termos de Uso regulam a relação entre você (usuário) e o '
          'EcoLife. Ao criar uma conta ou usar o app, você declara estar '
          'de acordo com todas as condições abaixo. Leia com atenção.',
          style: TextStyle(fontSize: 13, height: 1.55, color: theme.text),
        ),
        const SizedBox(height: 22),
        const _LegalSection(
          heading: '1. Aceitação dos termos',
          body:
              'Ao clicar em "Cadastrar", logar com Google ou continuar '
              'utilizando o EcoLife, você confirma ter lido, compreendido '
              'e aceitado integralmente estes Termos. Se discordar de '
              'qualquer cláusula, não utilize o serviço.',
        ),
        const _LegalSection(
          heading: '2. Descrição do serviço',
          body:
              'O EcoLife é um aplicativo de acompanhamento de hábitos '
              'sustentáveis. Permite registrar práticas ecológicas, '
              'acompanhar progresso, calcular impacto ambiental estimado '
              'e visualizar conquistas. Os valores apresentados '
              '(carbono economizado, água preservada, etc.) são estimativas '
              'educativas baseadas em médias públicas e não constituem '
              'medição científica precisa.',
        ),
        const _LegalSection(
          heading: '3. Cadastro e conta',
          body:
              'Para usar o app, você precisa fornecer informações '
              'verdadeiras, completas e atualizadas. Você é o único '
              'responsável pela confidencialidade da sua senha e por '
              'todas as atividades realizadas em sua conta. Notifique-nos '
              'imediatamente em caso de uso não autorizado.',
        ),
        const _LegalSection(
          heading: '4. Uso permitido',
          body:
              'Você concorda em usar o EcoLife apenas para fins '
              'pessoais e lícitos. É proibido: (a) tentar acessar '
              'contas de terceiros; (b) burlar mecanismos de segurança; '
              '(c) utilizar bots, scripts ou automação para inflar '
              'pontuação; (d) publicar conteúdo ofensivo, ilegal, '
              'discriminatório ou que viole direitos de terceiros; '
              '(e) realizar engenharia reversa do aplicativo.',
        ),
        const _LegalSection(
          heading: '5. Propriedade intelectual',
          body:
              'Todo o conteúdo do EcoLife (logos, ícones, textos, '
              'layout, código-fonte) é protegido por direitos autorais '
              'e demais leis aplicáveis. É proibida a reprodução, '
              'distribuição ou modificação sem autorização prévia '
              'por escrito.',
        ),
        const _LegalSection(
          heading: '6. Conteúdo gerado pelo usuário',
          body:
              'Ao registrar hábitos ou outras informações no app, '
              'você concede ao EcoLife uma licença não exclusiva, '
              'gratuita e mundial para armazenar, exibir e processar '
              'esses dados, exclusivamente para fornecer o serviço a '
              'você. Você continua sendo o titular do conteúdo.',
        ),
        const _LegalSection(
          heading: '7. Disponibilidade e modificações',
          body:
              'Empenhamos esforços razoáveis para manter o app '
              'disponível, mas não garantimos funcionamento '
              'ininterrupto. Podemos suspender, modificar ou descontinuar '
              'funcionalidades a qualquer momento, com aviso prévio '
              'sempre que possível.',
        ),
        const _LegalSection(
          heading: '8. Limitação de responsabilidade',
          body:
              'O EcoLife é fornecido "no estado em que se encontra". '
              'Não nos responsabilizamos por: (a) decisões pessoais '
              'tomadas com base nas estimativas de impacto; '
              '(b) perda de dados decorrente de falhas em dispositivos '
              'do usuário; (c) interrupções causadas por terceiros '
              '(provedores de internet, Firebase, etc.).',
        ),
        const _LegalSection(
          heading: '9. Encerramento',
          body:
              'Você pode encerrar sua conta a qualquer momento pela '
              'opção "Excluir conta". Podemos suspender ou encerrar '
              'sua conta em caso de violação destes Termos, com aviso '
              'quando aplicável.',
        ),
        const _LegalSection(
          heading: '10. Legislação aplicável e foro',
          body:
              'Estes Termos são regidos pelas leis da República '
              'Federativa do Brasil. Fica eleito o foro da comarca de '
              'Aracaju/SE para dirimir quaisquer controvérsias, '
              'renunciando-se a qualquer outro, por mais privilegiado '
              'que seja.',
        ),
        const _LegalSection(
          heading: '11. Alterações nos termos',
          body:
              'Reservamo-nos o direito de modificar estes Termos. '
              'Mudanças significativas serão comunicadas no app. O uso '
              'continuado após a notificação implica aceitação tácita '
              'da nova versão.',
        ),
      ],
    );
  }
}

// ----- Exportar dados -----
class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _includeProfile = true;
  bool _includeHabits = true;
  bool _includeScore = true;
  bool _includeBadges = true;
  bool _includeSettings = false;
  bool _exporting = false;
  String? _previewJson;

  String _format = 'JSON';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AuthService.loadUserFromFirestore(user.uid).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _generatePreview() {
    final state = AppState.instance;
    final user = FirebaseAuth.instance.currentUser;
    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln('  "exported_at": "${DateTime.now().toIso8601String()}",');
    buf.writeln('  "format": "$_format",');
    if (_includeProfile) {
      buf.writeln('  "profile": {');
      buf.writeln('    "email": "${user?.email ?? ''}",');
      buf.writeln('    "name": "${state.userName}",');
      buf.writeln('    "surname": "${state.userSurname}",');
      buf.writeln('    "phone": "${state.userPhone}",');
      buf.writeln('    "city": "${state.userCity}",');
      buf.writeln('    "state": "${state.userState}",');
      buf.writeln('    "country": "${state.userCountry}",');
      buf.writeln('    "type": "${state.userType}"');
      buf.writeln('  },');
    }
    if (_includeScore) {
      buf.writeln('  "green_score": ${state.greenScore},');
      buf.writeln('  "streak_days": ${state.streak},');
    }
    if (_includeHabits) {
      buf.writeln('  "habits": {');
      final entries = state.dailyHabits.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final comma = i < entries.length - 1 ? ',' : '';
        buf.writeln('    "${e.key}": ${e.value}$comma');
      }
      buf.writeln('  },');
    }
    if (_includeBadges) {
      buf.writeln('  "badges": [');
      buf.writeln('    "MESTRE_RECICLAGEM",');
      buf.writeln('    "HEROI_PLASTICO",');
      buf.writeln('    "ECONOMIZADOR_ENERGIA"');
      buf.writeln('  ],');
    }
    if (_includeSettings) {
      buf.writeln('  "settings": {');
      buf.writeln('    "notifications": ${state.notificationsEnabled},');
      buf.writeln('    "show_location": ${state.showLocation},');
      buf.writeln('    "analytics": ${state.analyticsEnabled},');
      buf.writeln('    "privacy_mode": ${state.privacyMode}');
      buf.writeln('  }');
    }
    buf.writeln('}');
    setState(() => _previewJson = buf.toString());
  }

  Map<String, dynamic> _buildPayload() {
    final state = AppState.instance;
    final user = FirebaseAuth.instance.currentUser;
    final payload = <String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'format': _format,
    };
    if (_includeProfile) {
      payload['profile'] = {
        'email': user?.email ?? '',
        'name': state.userName,
        'surname': state.userSurname,
        'phone': state.userPhone,
        'city': state.userCity,
        'state': state.userState,
        'country': state.userCountry,
        'type': state.userType,
      };
    }
    if (_includeScore) {
      payload['green_score'] = state.greenScore;
      payload['streak_days'] = state.streak;
    }
    if (_includeHabits) {
      payload['habits'] = Map<String, dynamic>.from(state.dailyHabits);
    }
    if (_includeBadges) {
      payload['badges'] = const [
        'MESTRE_RECICLAGEM',
        'HEROI_PLASTICO',
        'ECONOMIZADOR_ENERGIA',
      ];
    }
    if (_includeSettings) {
      payload['settings'] = {
        'notifications': state.notificationsEnabled,
        'show_location': state.showLocation,
        'analytics': state.analyticsEnabled,
        'privacy_mode': state.privacyMode,
      };
    }
    return payload;
  }

  String _payloadToCsv(Map<String, dynamic> p) {
    final lines = <String>['campo,valor'];
    void add(String key, dynamic value) {
      final v = value.toString().replaceAll('"', '""').replaceAll('\n', ' ');
      lines.add('"$key","$v"');
    }

    p.forEach((k, v) {
      if (v is Map) {
        v.forEach((kk, vv) => add('$k.$kk', vv));
      } else if (v is List) {
        for (var i = 0; i < v.length; i++) {
          add('$k[$i]', v[i]);
        }
      } else {
        add(k, v);
      }
    });
    return lines.join('\n');
  }

  Future<Uint8List> _buildPdf(Map<String, dynamic> p) async {
    final doc = pw.Document(
      title: 'EcoLife - Exportação de Dados',
      author: 'EcoLife',
    );
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final green = PdfColor.fromInt(0xFF2E7D32);
    final lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    final darkText = PdfColor.fromInt(0xFF1B1B1B);
    final mutedText = PdfColor.fromInt(0xFF6B7280);

    pw.Widget sectionTitle(String t) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        t,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: green,
        ),
      ),
    );

    pw.Widget kv(String k, String v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              k,
              style: pw.TextStyle(
                fontSize: 10,
                color: mutedText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              v.isEmpty ? '-' : v,
              style: pw.TextStyle(fontSize: 10, color: darkText),
            ),
          ),
        ],
      ),
    );

    const profileLabels = {
      'email': 'E-mail',
      'name': 'Nome',
      'surname': 'Sobrenome',
      'phone': 'Telefone',
      'city': 'Cidade',
      'state': 'Estado',
      'country': 'País',
      'type': 'Tipo de conta',
    };
    const settingsLabels = {
      'notifications': 'Notificações',
      'show_location': 'Mostrar localização',
      'analytics': 'Análises de uso',
      'privacy_mode': 'Modo privado',
    };
    const badgeLabels = {
      'MESTRE_RECICLAGEM': 'Mestre da Reciclagem',
      'HEROI_PLASTICO': 'Herói Plástico',
      'ECONOMIZADOR_ENERGIA': 'Economizador de Energia',
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: green, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EcoLife',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: green,
                    ),
                  ),
                  pw.Text(
                    'Relatório de exportação de dados pessoais',
                    style: pw.TextStyle(fontSize: 9, color: mutedText),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'EcoLife • Documento gerado automaticamente conforme '
                'Art. 18 da LGPD (Lei 13.709/2018)',
                style: pw.TextStyle(fontSize: 8, color: mutedText),
              ),
              pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: mutedText),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGreen,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'Este documento contém os dados pessoais e de atividade '
              'associados à sua conta no EcoLife, conforme solicitado '
              'em conformidade com o direito de portabilidade previsto '
              'na Lei Geral de Proteção de Dados.',
              style: pw.TextStyle(fontSize: 10, color: darkText),
            ),
          ),
          if (p['profile'] != null) ...[
            sectionTitle('1. Dados de perfil'),
            for (final e in (p['profile'] as Map<String, dynamic>).entries)
              kv(profileLabels[e.key] ?? e.key, e.value.toString()),
          ],
          if (p['green_score'] != null) ...[
            sectionTitle('2. Pontuação e progresso'),
            kv('Green Score', p['green_score'].toString()),
            kv('Sequência (dias)', p['streak_days'].toString()),
          ],
          if (p['habits'] != null) ...[
            sectionTitle('3. Hábitos sustentáveis'),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromInt(0xFFE5E7EB),
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGreen),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Hábito',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Concluído',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final e in (p['habits'] as Map<String, dynamic>).entries)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          e.key,
                          style: pw.TextStyle(fontSize: 10, color: darkText),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          e.value == true ? 'Sim' : 'Não',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: e.value == true ? green : mutedText,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (p['badges'] != null) ...[
            sectionTitle('4. Conquistas e emblemas'),
            for (final b in (p['badges'] as List))
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      margin: const pw.EdgeInsets.only(right: 8),
                      decoration: pw.BoxDecoration(
                        color: green,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Text(
                      badgeLabels[b.toString()] ??
                          b.toString().replaceAll('_', ' '),
                      style: pw.TextStyle(fontSize: 10, color: darkText),
                    ),
                  ],
                ),
              ),
          ],
          if (p['settings'] != null) ...[
            sectionTitle('5. Configurações do aplicativo'),
            for (final e in (p['settings'] as Map<String, dynamic>).entries)
              kv(
                settingsLabels[e.key] ?? e.key,
                e.value == true ? 'Ativado' : 'Desativado',
              ),
          ],
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor(0.18, 0.49, 0.20, 0.4),
                width: 0.5,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'Para dúvidas ou solicitações relacionadas ao tratamento '
              'dos seus dados, entre em contato com nosso Encarregado '
              '(DPO): privacidade@ecolife.app',
              style: pw.TextStyle(fontSize: 9, color: mutedText),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    _generatePreview();
    try {
      final payload = _buildPayload();
      if (_format == 'PDF') {
        final bytes = await _buildPdf(payload);
        if (!mounted) return;
        setState(() => _exporting = false);
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name:
              'ecolife_dados_'
              '${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } else if (_format == 'CSV') {
        final csv = _payloadToCsv(payload);
        final bytes = Uint8List.fromList(utf8.encode(csv));
        if (!mounted) return;
        setState(() => _exporting = false);
        await Printing.sharePdf(bytes: bytes, filename: 'ecolife_dados.csv');
      } else {
        // JSON
        const enc = JsonEncoder.withIndent('  ');
        final jsonStr = enc.convert(payload);
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        if (!mounted) return;
        setState(() => _exporting = false);
        await Printing.sharePdf(bytes: bytes, filename: 'ecolife_dados.json');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Arquivo gerado! Use o menu para baixar, salvar ou '
                  'compartilhar.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Erro ao gerar arquivo: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return _LegalScaffold(
      title: 'EXPORTAR DADOS',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download_outlined, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'Portabilidade de dados',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Conforme o Art. 18 da LGPD, você tem o direito de receber '
                'uma cópia portável dos seus dados em formato estruturado. '
                'Selecione abaixo o que deseja incluir e o formato de '
                'exportação.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.green.shade900.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'O QUE INCLUIR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        _ExportCheckRow(
          label: 'Dados de perfil',
          icon: Icons.person_outline,
          value: _includeProfile,
          onChanged: (v) => setState(() => _includeProfile = v),
        ),
        _ExportCheckRow(
          label: 'Hábitos diários',
          icon: Icons.eco_outlined,
          value: _includeHabits,
          onChanged: (v) => setState(() => _includeHabits = v),
        ),
        _ExportCheckRow(
          label: 'Pontuação e progresso',
          icon: Icons.trending_up,
          value: _includeScore,
          onChanged: (v) => setState(() => _includeScore = v),
        ),
        _ExportCheckRow(
          label: 'Conquistas e emblemas',
          icon: Icons.emoji_events_outlined,
          value: _includeBadges,
          onChanged: (v) => setState(() => _includeBadges = v),
        ),
        _ExportCheckRow(
          label: 'Configurações do app',
          icon: Icons.settings_outlined,
          value: _includeSettings,
          onChanged: (v) => setState(() => _includeSettings = v),
        ),
        const SizedBox(height: 22),
        Text(
          'FORMATO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final fmt in ['JSON', 'CSV', 'PDF'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(fmt),
                  selected: _format == fmt,
                  selectedColor: Colors.green.shade600,
                  labelStyle: TextStyle(
                    color: _format == fmt ? Colors.white : theme.text,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _format = fmt),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            label: Text(
              _exporting ? 'Gerando arquivo...' : 'Gerar e baixar',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _generatePreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Visualizar prévia dos dados'),
          style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
        ),
        if (_previewJson != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Text(
              _previewJson!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
                color: theme.text,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(
          'Ao confirmar, o arquivo será gerado no formato escolhido e '
          'aberto no menu nativo do seu dispositivo — você poderá '
          'baixar, salvar na nuvem, imprimir ou compartilhar diretamente.',
          style: TextStyle(fontSize: 12, color: theme.subText, height: 1.5),
        ),
      ],
    );
  }
}

class _ExportCheckRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ExportCheckRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? Colors.green.shade400 : theme.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Excluir conta -----
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirm1 = false;
  bool _confirm2 = false;
  bool _confirm3 = false;
  final _confirmCtrl = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _confirm1 &&
      _confirm2 &&
      _confirm3 &&
      _confirmCtrl.text.trim().toUpperCase() == 'EXCLUIR';

  Future<void> _doDelete() async {
    setState(() => _deleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AuthService.deleteUserFromFirestore(user.uid);
        await user.delete();
      }
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      final msg = e.code == 'requires-recent-login'
          ? 'Por segurança, faça login novamente antes de excluir a conta.'
          : (e.message ?? 'Não foi possível excluir a conta.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Erro inesperado ao excluir a conta.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return _LegalScaffold(
      title: 'EXCLUIR CONTA',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Esta ação é permanente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ao excluir sua conta, os seguintes dados serão '
                'removidos definitivamente em até 30 dias: perfil, '
                'histórico de hábitos, pontuação Green Score, '
                'sequências, conquistas, emblemas e preferências. '
                'Você não poderá recuperá-los depois.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.red.shade900.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ANTES DE PROSSEGUIR, CONSIDERE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 12),
        _DeleteAlternative(
          icon: Icons.download_outlined,
          title: 'Exportar seus dados antes',
          subtitle: 'Baixe uma cópia completa do seu histórico para guardar.',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ExportDataScreen()),
            );
          },
        ),
        _DeleteAlternative(
          icon: Icons.notifications_off_outlined,
          title: 'Desativar notificações',
          subtitle: 'Pause as notificações sem perder seu progresso.',
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'CONFIRMAÇÕES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 12),
        _DeleteCheck(
          label:
              'Entendo que todos os meus hábitos, pontuação e conquistas '
              'serão perdidos para sempre.',
          value: _confirm1,
          onChanged: (v) => setState(() => _confirm1 = v),
        ),
        _DeleteCheck(
          label:
              'Entendo que esta ação não pode ser desfeita após a '
              'confirmação.',
          value: _confirm2,
          onChanged: (v) => setState(() => _confirm2 = v),
        ),
        _DeleteCheck(
          label: 'Confirmo que sou o titular desta conta e desejo encerrá-la.',
          value: _confirm3,
          onChanged: (v) => setState(() => _confirm3 = v),
        ),
        const SizedBox(height: 22),
        Text(
          'Para confirmar, digite EXCLUIR no campo abaixo:',
          style: TextStyle(fontSize: 13, color: theme.text),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmCtrl,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Digite EXCLUIR',
            filled: true,
            fillColor: theme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_canDelete && !_deleting) ? _doDelete : null,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever, color: Colors.white),
            label: Text(
              _deleting ? 'Excluindo conta...' : 'Excluir minha conta',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              disabledBackgroundColor: Colors.red.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar e voltar',
            style: TextStyle(color: theme.subText, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DeleteAlternative extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DeleteAlternative({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: theme.subText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.subText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DeleteCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _DeleteCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? Colors.red.shade300 : theme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: theme.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Ajuda & Suporte -----
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _openFaq;
  String _category = 'Dúvida';
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  static const _faqs = <Map<String, String>>[
    {
      'q': 'Como funciona o Green Score?',
      'a':
          'O Green Score é uma pontuação de 0 a 1000 calculada a partir '
          'dos seus hábitos sustentáveis registrados diariamente. Cada '
          'hábito concluído soma 25 pontos a uma base de 800. Quanto '
          'mais consistente sua rotina, maior o score.',
    },
    {
      'q': 'Como adiciono ou marco hábitos diários?',
      'a':
          'Vá em "Início" e role até a seção de hábitos. Toque no '
          'checkbox ao lado de cada hábito para marcá-lo como '
          'concluído no dia. Os dados são salvos automaticamente e '
          'refletidos no seu Impacto e Progresso.',
    },
    {
      'q': 'Como ganho emblemas e conquistas?',
      'a':
          'Os emblemas são desbloqueados ao atingir metas específicas: '
          'reciclagem contínua, redução de plástico, economia de '
          'energia, entre outros. Veja todos disponíveis em '
          '"Progresso → Emblemas de Conquista".',
    },
    {
      'q': 'Posso usar o EcoLife sem conexão à internet?',
      'a':
          'O app exige conexão para autenticar e sincronizar seu '
          'progresso. Algumas telas funcionam parcialmente offline, '
          'mas o registro de hábitos só é confirmado quando há '
          'conexão de volta.',
    },
    {
      'q': 'Como mudar minha senha?',
      'a':
          'Em "Perfil", toque no campo "Mudar senha atual". Por '
          'segurança, você precisará digitar a senha antiga e '
          'confirmar a nova duas vezes. Para quem entrou com Google, '
          'a senha é gerenciada pela sua conta Google.',
    },
    {
      'q': 'Por que minha foto de perfil não aparece?',
      'a':
          'Quando você loga com Google, usamos a foto da sua conta '
          'Google. Se ela não aparecer, verifique se sua conta tem '
          'foto pública e tente sair e entrar novamente. Caso '
          'persista, fale com o suporte abaixo.',
    },
    {
      'q': 'Como funcionam as notificações?',
      'a':
          'Ative em "Privacidade → Notificações" para receber lembretes '
          'diários de hábitos, alertas de conquistas, novidades e '
          'atividade de amigos. Você pode personalizar cada tipo.',
    },
    {
      'q': 'O EcoLife coleta minha localização?',
      'a':
          'Apenas se você ativar "Mostrar localização" em Privacidade. '
          'Usamos a localização cadastrada (cidade e estado) para '
          'estatísticas regionais e ranking de EcoGuerreiros locais. '
          'Você pode desativar a qualquer momento.',
    },
    {
      'q': 'Como excluo minha conta?',
      'a':
          'Em "Perfil → Privacidade → Excluir conta". O processo exige '
          'confirmação explícita e remove seus dados em até 30 dias, '
          'conforme a LGPD.',
    },
    {
      'q': 'Os valores de carbono e água são exatos?',
      'a':
          'São estimativas educativas baseadas em médias públicas de '
          'organizações ambientais. Servem como referência para '
          'visualizar seu impacto, não como medição científica '
          'precisa.',
    },
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            content: const Text(
              'Não foi possível abrir o link.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Link inválido.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _submitMessage() async {
    final msg = _messageCtrl.text.trim();
    if (msg.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Descreva sua mensagem com pelo menos 10 caracteres.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    final subject = Uri.encodeComponent(
      '[EcoLife - $_category] Solicitação de ${user?.email ?? "usuário"}',
    );
    final body = Uri.encodeComponent(
      'Categoria: $_category\n'
      'E-mail do usuário: ${user?.email ?? ""}\n'
      'Nome: ${UserDisplay.fullDisplay(user)}\n'
      '\n---\n\n'
      '$msg\n',
    );
    final mailto = 'mailto:suporte@ecolife.app?subject=$subject&body=$body';
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _sending = false);
    await _openUrl(mailto);
    if (!mounted) return;
    _messageCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Abrimos seu app de e-mail com a mensagem pronta.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return _LegalScaffold(
      title: 'AJUDA & SUPORTE',
      children: [
        // Hero / banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade500, Colors.green.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como podemos ajudar?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tempo médio de resposta: até 24h em dias úteis.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Quick action grid
        Text(
          'AÇÕES RÁPIDAS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HelpQuickAction(
                icon: Icons.mail_outline,
                label: 'E-mail',
                subtitle: 'suporte@ecolife.app',
                color: Colors.green.shade600,
                onTap: () => _openUrl('mailto:suporte@ecolife.app'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HelpQuickAction(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                subtitle: '(79) 99999-0000',
                color: const Color(0xFF25D366),
                onTap: () => _openUrl(
                  'https://wa.me/5579999990000?text=Olá%2C+preciso+de+ajuda+com+o+EcoLife.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HelpQuickAction(
                icon: Icons.language,
                label: 'Site',
                subtitle: 'ecolife.app',
                color: Colors.teal.shade600,
                onTap: () => _openUrl('https://ecolife.app'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HelpQuickAction(
                icon: Icons.menu_book_outlined,
                label: 'Central de ajuda',
                subtitle: 'Guia completo',
                color: Colors.indigo.shade500,
                onTap: () => _openUrl('https://ecolife.app/ajuda'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),
        Text(
          'PERGUNTAS FREQUENTES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_faqs.length, (i) {
          final faq = _faqs[i];
          final open = _openFaq == i;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: open ? Colors.green.shade300 : theme.border,
              ),
            ),
            child: Column(
              children: [
                Tappable(
                  onTap: () => setState(() => _openFaq = open ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            faq['q']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: theme.subText,
                        ),
                      ],
                    ),
                  ),
                ),
                if (open)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(54, 0, 14, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: theme.subText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 22),
        Text(
          'ENVIAR MENSAGEM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categoria',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.subText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in const [
                    'Dúvida',
                    'Problema técnico',
                    'Sugestão',
                    'LGPD / Privacidade',
                    'Outro',
                  ])
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      selectedColor: Colors.green.shade600,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _category == c ? Colors.white : theme.text,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Mensagem',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.subText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 5,
                minLines: 4,
                maxLength: 600,
                style: TextStyle(fontSize: 13, color: theme.text),
                decoration: InputDecoration(
                  hintText: 'Descreva sua dúvida ou problema com detalhes...',
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.green.shade500,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submitMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                  label: Text(
                    _sending ? 'Enviando...' : 'Enviar mensagem',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
        Text(
          'REDES SOCIAIS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.subText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SocialButton(
              icon: Icons.facebook,
              color: const Color(0xFF1877F2),
              onTap: () => _openUrl('https://facebook.com/ecolifeapp'),
            ),
            _SocialButton(
              icon: Icons.camera_alt,
              color: const Color(0xFFE1306C),
              onTap: () => _openUrl('https://instagram.com/ecolifeapp'),
            ),
            _SocialButton(
              icon: Icons.play_circle_outline,
              color: const Color(0xFFFF0000),
              onTap: () => _openUrl('https://youtube.com/@ecolifeapp'),
            ),
            _SocialButton(
              icon: Icons.alternate_email,
              color: const Color(0xFF1DA1F2),
              onTap: () => _openUrl('https://twitter.com/ecolifeapp'),
            ),
          ],
        ),

        const SizedBox(height: 26),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sobre o aplicativo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _AboutRow(label: 'Versão', value: '1.0.0+1'),
              _AboutRow(label: 'Build', value: 'release-2026.05'),
              _AboutRow(label: 'Plataforma', value: 'Flutter 3.x'),
              _AboutRow(label: 'DPO', value: 'privacidade@ecolife.app'),
              _AboutRow(label: 'CNPJ', value: '00.000.000/0001-00'),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _HelpQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _HelpQuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: onTap,
      scaleOnHover: 1.02,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: theme.subText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scaleOnHover: 1.08,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: theme.subText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 10. SHARED WIDGETS
// ============================================================

/// Wrapper que faz o header colapsar conforme o usuário rola a tela.
/// Use no lugar de `Column + GreenHeader + Expanded(SingleChildScrollView)`.
class CollapsibleHeaderPage extends StatefulWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CollapsibleHeaderPage({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 110),
  });

  @override
  State<CollapsibleHeaderPage> createState() => _CollapsibleHeaderPageState();
}

class _CollapsibleHeaderPageState extends State<CollapsibleHeaderPage> {
  final ScrollController _ctrl = ScrollController();
  final ValueNotifier<double> _progress = ValueNotifier(0);
  // Faixa em pixels: 0px = expandido, 110px+ = totalmente colapsado.
  static const double _shrinkRange = 110.0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _ctrl.offset.clamp(0.0, _shrinkRange);
    _progress.value = offset / _shrinkRange;
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _progress,
          builder: (_, value, __) =>
              GreenHeader(title: widget.title, shrinkProgress: value),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _ctrl,
            physics: const ClampingScrollPhysics(),
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class GreenHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final double shrinkProgress; // 0=expandido, 1=colapsado
  const GreenHeader({
    super.key,
    required this.title,
    this.leading,
    this.shrinkProgress = 0.0,
  });

  // helper de interpolação linear
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final state = AppState.instance;
    final shortName = UserDisplay.lastName(user).toUpperCase();
    final shortDisplay = shortName.length > 10
        ? shortName.substring(0, 10)
        : shortName;
    final showLoc = state.showLocation && state.userState.trim().isNotEmpty;
    final locLabel = showLoc
        ? (state.userCity.trim().isNotEmpty
              ? '${state.userCity}, ${state.userState}'
              : state.userState)
        : '';

    final p = shrinkProgress.clamp(0.0, 1.0);
    final logoSize = _lerp(140, 50, p);
    final logoPad = _lerp(8, 4, p);
    final logoShadowBlur = _lerp(20, 8, p);
    final paddingTop = _lerp(50, 38, p);
    final paddingBottom = _lerp(18, 8, p);
    final titleFontSize = _lerp(16, 13, p);
    final locFontSize = _lerp(10, 9, p);
    final radius = _lerp(34, 22, p);
    final avatarSize = _lerp(34, 28, p);
    final nameFontSize = _lerp(12, 11, p);
    // Esconder o chip de localização (sob o título) quando o header está
    // bem colapsado, para sobrar espaço — a opacidade vai a 0 nos últimos 30%.
    final locOpacity = (1 - (p / 0.7)).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: paddingTop,
        left: 14,
        right: 14,
        bottom: paddingBottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: _lerp(15, 8, p),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: section title (or back button) + location chip
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  leading ??
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (showLoc && locOpacity > 0.01) ...[
                          SizedBox(height: _lerp(4, 1, p)),
                          Opacity(
                            opacity: locOpacity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    locLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: locFontSize,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
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
          ),
          // Center: EcoLife logo (que encolhe)
          Container(
            padding: EdgeInsets.all(logoPad),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: logoShadowBlur,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: logoSize,
              height: logoSize,
              child: Image.asset(
                'assets/Logo_EcoLife.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Right: user name + avatar
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      shortDisplay,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: nameFontSize,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UserAvatar(user: user, size: avatarSize),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final User? user;
  final double size;
  final double? fontSize;
  const _UserAvatar({this.user, required this.size, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final letter =
        (user?.displayName?.isNotEmpty == true
                ? user!.displayName![0]
                : (user?.email?.isNotEmpty == true ? user!.email![0] : '?'))
            .toUpperCase();
    final photo = user?.photoURL;
    Widget fallback() => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF66BB6A),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? size * 0.4,
        ),
      ),
    );
    if (photo == null || photo.isEmpty) return fallback();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF66BB6A),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        photo,
        key: ValueKey(photo),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        // Sem loadingBuilder: o fundo verde do Container já é placeholder.
      ),
    );
  }
}

// Helper para extrair o "último nome" do usuário de forma inteligente.
class UserDisplay {
  static String lastName(User? user, {String fallback = 'USER'}) {
    // 1) Se houver displayName do provedor (Google/Firebase), pegar a ÚLTIMA palavra
    final dn = user?.displayName?.trim() ?? '';
    if (dn.isNotEmpty) {
      final parts = dn.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) return parts.last;
    }
    // 2) Se houver sobrenome cadastrado no AppState, usar ele
    final surname = AppState.instance.userSurname.trim();
    if (surname.isNotEmpty) {
      final parts = surname.split(RegExp(r'\s+'));
      return parts.last;
    }
    // 3) Se houver nome cadastrado, pegar última palavra
    final uname = AppState.instance.userName.trim();
    if (uname.isNotEmpty) {
      final parts = uname.split(RegExp(r'\s+'));
      if (parts.length > 1) return parts.last;
      // Só tem um nome — não dá pra adivinhar sobrenome, mostra mesmo assim
      return parts.first;
    }
    // 4) Email com separadores: edy.rocha@ → "rocha", edy_rocha → "rocha"
    final emailPrefix = (user?.email ?? '').split('@').first;
    if (emailPrefix.isNotEmpty) {
      final parts = emailPrefix.split(RegExp(r'[.\-_+]+'));
      if (parts.length > 1) return parts.last;
      return emailPrefix;
    }
    return fallback;
  }

  static String fullDisplay(User? user) {
    final dn = user?.displayName?.trim() ?? '';
    if (dn.isNotEmpty) return dn;
    final un = AppState.instance.userName.trim();
    final sn = AppState.instance.userSurname.trim();
    if (un.isNotEmpty || sn.isNotEmpty) {
      return [un, sn].where((s) => s.isNotEmpty).join(' ');
    }
    return (user?.email ?? '').split('@').first;
  }
}

class EcoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const EcoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomNavItem(
            icon: Icons.home,
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _BottomNavItem(
            icon: Icons.rocket_launch,
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _BottomNavItem(
            icon: Icons.add_circle_outline,
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _BottomNavItem(
            icon: Icons.group,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _BottomNavItem(
            icon: Icons.person,
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _BottomNavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final hovered = _hovered && !active; // active sobrescreve hover
    final bgColor = active
        ? Colors.white.withOpacity(0.28)
        : (hovered ? Colors.white.withOpacity(0.14) : Colors.transparent);
    final scale = active ? 1.15 : (hovered ? 1.10 : 1.0);
    final iconColor = active
        ? Colors.white
        : (hovered ? Colors.white : Colors.white.withOpacity(0.92));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              child: Icon(widget.icon, color: iconColor, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class EcoLogo extends StatelessWidget {
  const EcoLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/Logo_EcoLife.png', fit: BoxFit.contain);
  }
}

class EcoTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? icon;
  final VoidCallback? onTogglePassword;

  const EcoTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.icon,
    this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.green.shade900),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.green.shade600, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.green.shade400, size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const GoogleSignInButton({super.key, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      scaleOnHover: 1.02,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Continuar com Google',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 26),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: Colors.green.shade600,
            onChanged: onChanged,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.subText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: () {},
      scaleOnHover: 1.02,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: Colors.green.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Concluído:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    activity['name'] as String,
                    style: TextStyle(color: theme.subText, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;
  const _AnimatedEntry({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final interval = Interval(
      delay.clamp(0.0, 1.0),
      math.min(1.0, delay + 0.4),
      curve: Curves.easeOutCubic,
    );
    final fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: interval));
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: interval));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ============================================================
// CHARTS
// ============================================================

class AnimatedGauge extends StatefulWidget {
  final double value;
  final int score;
  final bool isDark;
  const AnimatedGauge({
    super.key,
    required this.value,
    required this.score,
    this.isDark = false,
  });

  @override
  State<AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = Tween<double>(begin: old.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => SizedBox(
        height: 180,
        width: double.infinity,
        child: CustomPaint(
          size: const Size.fromHeight(180),
          painter: BeautifulGaugePainter(
            value: _animation.value,
            score: widget.score,
            isDark: widget.isDark,
          ),
        ),
      ),
    );
  }
}

class BeautifulGaugePainter extends CustomPainter {
  final double value;
  final int score;
  final bool isDark;
  BeautifulGaugePainter({
    required this.value,
    required this.score,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final radius = math.min(size.width * 0.42, size.height * 0.9);

    // Background arc
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFFE8F0E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Main arc with green gradient
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF7CB342),
          const Color(0xFF43A047),
          const Color(0xFF2E7D32),
        ],
        startAngle: math.pi,
        endAngle: math.pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value,
      false,
      fgPaint,
    );

    // Score number
    final tp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height - 18),
    );

    // Leaf icon below number
    final tp2 = TextPainter(
      text: TextSpan(
        text: '🌿',
        style: TextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : Colors.green.shade700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(center.dx - tp2.width / 2, center.dy - 22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class AnimatedBarChart extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final AnimationController controller;
  const AnimatedBarChart({
    super.key,
    required this.data,
    required this.labels,
    required this.controller,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    final maxData = widget.data.reduce(math.max);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.data.length, (i) {
          final value = widget.data[i];
          final isHovered = _hoveredIndex == i;
          final isMax = value == maxData;
          final animatedHeight = 140 * value * widget.controller.value;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = i),
                onExit: (_) => setState(() => _hoveredIndex = null),
                cursor: SystemMouseCursors.click,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(value * 100).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      height: animatedHeight + (isHovered ? 8 : 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isMax
                              ? [Colors.green.shade300, Colors.green.shade500]
                              : (i % 2 == 0
                                    ? [
                                        Colors.green.shade800,
                                        Colors.green.shade900,
                                      ]
                                    : [
                                        Colors.green.shade500,
                                        Colors.green.shade700,
                                      ]),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isHovered
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DonutCard extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String unit;
  final String amount;
  final AnimationController controller;
  final double delay;
  const _DonutCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.unit,
    required this.amount,
    required this.controller,
    required this.delay,
  });

  @override
  State<_DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends State<_DonutCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    final interval = Interval(
      widget.delay.clamp(0.0, 1.0),
      math.min(1.0, widget.delay + 0.5),
      curve: Curves.easeOutCubic,
    );
    final anim = CurvedAnimation(parent: widget.controller, curve: interval);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: _hovered
                ? (Matrix4.identity()..scale(1.05))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            child: AnimatedBuilder(
              animation: anim,
              builder: (context, _) => SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: BeautifulDonutPainter(
                    value: widget.value * anim.value,
                    color: widget.color,
                    hovered: _hovered,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 28),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.amount}${widget.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeautifulDonutPainter extends CustomPainter {
  final double value;
  final Color color;
  final bool hovered;
  BeautifulDonutPainter({
    required this.value,
    required this.color,
    required this.hovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final stroke = hovered ? 16.0 : 14.0;

    final bg = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);

    if (hovered) {
      final glow = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        glow,
      );
    }

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.7), color],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _BadgeWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _BadgeWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  @override
  State<_BadgeWidget> createState() => _BadgeWidgetState();
}

class _BadgeWidgetState extends State<_BadgeWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: widget.gradient),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(
                      _hovered ? 0.6 : 0.3,
                    ),
                    blurRadius: _hovered ? 20 : 12,
                    spreadRadius: _hovered ? 3 : 1,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: theme.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetBadge extends StatefulWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  const _AssetBadge({
    required this.assetPath,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AssetBadge> createState() => _AssetBadgeState();
}

class _AssetBadgeState extends State<_AssetBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(_hovered ? 0.35 : 0.15),
                    blurRadius: _hovered ? 22 : 12,
                    spreadRadius: _hovered ? 2 : 0,
                  ),
                ],
              ),
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    color: AppColors.greenPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: theme.subText),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCheckRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  const _HabitCheckRow({
    required this.icon,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: () => onChanged(!checked),
      scaleOnHover: 1.01,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.text,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: checked
                    ? LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: checked ? Colors.transparent : Colors.grey.shade400,
                  width: 1.5,
                ),
                boxShadow: checked
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.green.shade800 : Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final bool isMe;
  const _RankRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    Color? rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = Colors.grey.shade400;
    if (rank == 3) rankColor = const Color(0xFFCD7F32);
    return Tappable(
      onTap: () {},
      scaleOnHover: 1.02,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? Colors.green.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: rankColor != null
                    ? LinearGradient(
                        colors: [rankColor.withOpacity(0.7), rankColor],
                      )
                    : null,
                color: rankColor == null ? Colors.transparent : null,
                shape: BoxShape.circle,
                boxShadow: rankColor != null
                    ? [
                        BoxShadow(
                          color: rankColor.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: rankColor != null
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade800,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'PONTOS',
                    style: TextStyle(fontSize: 9, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (points > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldsGrid extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  const _ProfileFieldsGrid({
    required this.name,
    required this.email,
    this.phone = '',
  });

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final rawPhone = state.userPhone.isNotEmpty ? state.userPhone : phone;
    final formattedPhone = rawPhone.isNotEmpty ? _formatPhone(rawPhone) : 'Telefone não informado';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _PField(name.isNotEmpty ? name : 'Nome não informado'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _PField(email),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _PField(formattedPhone),
        ),
      ],
    );
  }
}

class _PField extends StatelessWidget {
  final String label;
  const _PField(this.label);
  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () {},
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade700],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOCATION MAP CARD — mostra localização do usuário num mapa real
// Tenta GPS primeiro; se falhar, usa o estado cadastrado.
// ============================================================
class LocationMapCard extends StatefulWidget {
  const LocationMapCard({super.key});

  @override
  State<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends State<LocationMapCard> {
  // Coordenadas centrais dos 27 estados brasileiros (fallback).
  static const Map<String, LatLng> _statesBR = {
    'AC': LatLng(-9.0238, -70.8120),
    'AL': LatLng(-9.5713, -36.7820),
    'AP': LatLng(1.4554, -51.7860),
    'AM': LatLng(-3.4168, -65.8561),
    'BA': LatLng(-12.5797, -41.7007),
    'CE': LatLng(-5.4984, -39.3206),
    'DF': LatLng(-15.7998, -47.8645),
    'ES': LatLng(-19.1834, -40.3089),
    'GO': LatLng(-15.8270, -49.8362),
    'MA': LatLng(-4.9609, -45.2744),
    'MT': LatLng(-12.6819, -56.9211),
    'MS': LatLng(-20.7722, -54.7852),
    'MG': LatLng(-18.5122, -44.5550),
    'PA': LatLng(-3.4168, -52.7860),
    'PB': LatLng(-7.2400, -36.7820),
    'PR': LatLng(-25.2521, -52.0215),
    'PE': LatLng(-8.8137, -36.9541),
    'PI': LatLng(-7.7183, -42.7289),
    'RJ': LatLng(-22.9099, -43.2095),
    'RN': LatLng(-5.4026, -36.9541),
    'RS': LatLng(-30.0346, -51.2177),
    'RO': LatLng(-11.5057, -63.5806),
    'RR': LatLng(2.7376, -62.0751),
    'SC': LatLng(-27.2423, -50.2189),
    'SP': LatLng(-23.5505, -46.6333),
    'SE': LatLng(-10.9472, -37.0731),
    'TO': LatLng(-10.1753, -48.2982),
  };

  static const Map<String, String> _stateAliases = {
    'ACRE': 'AC',
    'ALAGOAS': 'AL',
    'AMAPA': 'AP',
    'AMAPÁ': 'AP',
    'AMAZONAS': 'AM',
    'BAHIA': 'BA',
    'CEARA': 'CE',
    'CEARÁ': 'CE',
    'DISTRITO FEDERAL': 'DF',
    'ESPIRITO SANTO': 'ES',
    'ESPÍRITO SANTO': 'ES',
    'GOIAS': 'GO',
    'GOIÁS': 'GO',
    'MARANHAO': 'MA',
    'MARANHÃO': 'MA',
    'MATO GROSSO': 'MT',
    'MATO GROSSO DO SUL': 'MS',
    'MINAS GERAIS': 'MG',
    'PARA': 'PA',
    'PARÁ': 'PA',
    'PARAIBA': 'PB',
    'PARAÍBA': 'PB',
    'PARANA': 'PR',
    'PARANÁ': 'PR',
    'PERNAMBUCO': 'PE',
    'PIAUI': 'PI',
    'PIAUÍ': 'PI',
    'RIO DE JANEIRO': 'RJ',
    'RIO GRANDE DO NORTE': 'RN',
    'RIO GRANDE DO SUL': 'RS',
    'RONDONIA': 'RO',
    'RONDÔNIA': 'RO',
    'RORAIMA': 'RR',
    'SANTA CATARINA': 'SC',
    'SAO PAULO': 'SP',
    'SÃO PAULO': 'SP',
    'SERGIPE': 'SE',
    'TOCANTINS': 'TO',
  };

  static const Map<String, String> _fullStateNames = {
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };

  // Reverso: lat/lng aprox. → estado mais próximo (para rotular GPS).
  String _nearestStateLabel(LatLng pos) {
    double bestDist = double.infinity;
    String bestState = '';
    _statesBR.forEach((sigla, coord) {
      final dLat = pos.latitude - coord.latitude;
      final dLng = pos.longitude - coord.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        bestState = sigla;
      }
    });
    return _fullStateNames[bestState] ?? bestState;
  }

  LatLng? _resolveCadastrado(String stateRaw) {
    final s = stateRaw.trim().toUpperCase();
    if (s.isEmpty) return null;
    if (_statesBR.containsKey(s)) return _statesBR[s];
    if (_stateAliases.containsKey(s)) {
      return _statesBR[_stateAliases[s]!];
    }
    return null;
  }

  LatLng? _coord;
  String _source = ''; // 'gps' | 'cadastro'
  String _label = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? errorReason;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorReason = 'GPS desativado no dispositivo.';
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever) {
          errorReason =
              'Permissão de localização foi negada permanentemente. '
              'Habilite manualmente nas configurações do navegador.';
        } else if (perm == LocationPermission.denied) {
          errorReason = 'Permissão de localização negada.';
        } else {
          // Permissão OK — cache primeiro (instantâneo no mobile)
          try {
            final cached = await Geolocator.getLastKnownPosition();
            if (cached != null && mounted) {
              final coord = LatLng(cached.latitude, cached.longitude);
              setState(() {
                _coord = coord;
                _source = 'gps';
                _label = _nearestStateLabel(coord);
                _loading = false;
              });
              // Em background atualiza com leitura mais precisa
              unawaited(
                Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.medium,
                        timeLimit: Duration(seconds: 6),
                      ),
                    )
                    .then((p) {
                      if (!mounted) return;
                      final nc = LatLng(p.latitude, p.longitude);
                      setState(() {
                        _coord = nc;
                        _label = _nearestStateLabel(nc);
                      });
                    })
                    .catchError((_) {}),
              );
              return;
            }
          } catch (_) {
            /* sem cache, segue para getCurrentPosition */
          }
          // Sem cache — leitura direta (medium accuracy funciona no web/desktop)
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 20),
            ),
          );
          final coord = LatLng(pos.latitude, pos.longitude);
          if (!mounted) return;
          setState(() {
            _coord = coord;
            _source = 'gps';
            _label = _nearestStateLabel(coord);
            _loading = false;
          });
          return;
        }
      }
    } on TimeoutException {
      errorReason = 'O GPS demorou muito para responder. Tente novamente.';
    } catch (e) {
      errorReason = 'Erro ao acessar GPS: $e';
    }
    // Fallback: estado cadastrado
    final state = AppState.instance;
    final coord = _resolveCadastrado(state.userState);
    if (!mounted) return;
    if (coord != null) {
      final city = state.userCity.trim();
      final stateLabel =
          _fullStateNames[state.userState.trim().toUpperCase()] ??
          state.userState;
      setState(() {
        _coord = coord;
        _source = 'cadastro';
        _label = city.isNotEmpty ? '$city · $stateLabel' : stateLabel;
        _loading = false;
      });
    } else {
      setState(() {
        _coord = null;
        _source = '';
        _label = '';
        _loading = false;
        _error =
            errorReason ??
            'Permita o acesso à localização ou preencha o estado no perfil.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;

    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detectando sua localização...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pode levar alguns segundos. Aceite o pedido de '
                    'permissão do navegador, se aparecer.',
                    style: TextStyle(fontSize: 11, color: theme.subText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_coord == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localização indisponível',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _error ??
                            'Permita o acesso à localização ou '
                                'preencha o estado no perfil.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.subText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _resolve,
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final coord = _coord!;
    final isGps = _source == 'gps';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isGps ? Icons.my_location : Icons.public,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGps ? 'Localização atual (GPS)' : 'Sua localização',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          _label.isNotEmpty ? _label : 'Brasil',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: theme.subText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          isGps ? 'AO VIVO' : 'ATIVO',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Mapa
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: coord,
                  initialZoom: isGps ? 13 : 7,
                  minZoom: 4,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'app.ecolife',
                    maxZoom: 19,
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: coord,
                        radius: isGps ? 2000 : 80000,
                        useRadiusInMeter: true,
                        color: Colors.green.withOpacity(0.18),
                        borderColor: Colors.green.shade600,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: coord,
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: _PulsingPin(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 12, color: theme.subText),
                  const SizedBox(width: 6),
                  Text(
                    'Lat ${coord.latitude.toStringAsFixed(4)}, '
                    'Long ${coord.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.subText,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Tappable(
                    onTap: _resolve,
                    child: Icon(
                      Icons.refresh,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '© OSM',
                    style: TextStyle(fontSize: 9, color: theme.subText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingPin extends StatefulWidget {
  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = (0.5 + math.sin(_c.value * 2 * math.pi) * 0.5);
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Halo pulsante
            Positioned(
              top: 12,
              child: Container(
                width: 28 + pulse * 12,
                height: 28 + pulse * 12,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.25 - pulse * 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Pin
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 16),
                ),
                // Cauda triangular
                CustomPaint(
                  size: const Size(10, 6),
                  painter: _PinTailPainter(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.shade600;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: () => onChanged(!value),
      scaleOnHover: 1.01,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.text,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      )
                    : null,
                color: value ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: onTap,
      scaleOnHover: 1.01,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.subText),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _LinkTile({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: danger ? Colors.red.shade400 : theme.text,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: danger ? Colors.red.shade400 : theme.subText,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoQuad extends StatelessWidget {
  final String left1Title, left1Content, right1Title, right1Content;
  final String left2Title, left2Content, right2Title, right2Content;
  const _ResumoQuad({
    required this.left1Title,
    required this.left1Content,
    required this.right1Title,
    required this.right1Content,
    required this.left2Title,
    required this.left2Content,
    required this.right2Title,
    required this.right2Content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.instance;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _quad(left1Title, left1Content, theme)),
              const VerticalDivider(width: 16),
              Expanded(child: _quad(right1Title, right1Content, theme)),
            ],
          ),
        ),
        const Divider(height: 24),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _quad(left2Title, left2Content, theme)),
              const VerticalDivider(width: 16),
              Expanded(child: _quad(right2Title, right2Content, theme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quad(String title, String content, ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.green.shade800,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(fontSize: 11, color: theme.text, height: 1.4),
        ),
      ],
    );
  }
}