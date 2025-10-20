import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'registration_step1.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ========================= For Firestore Database
final FirebaseFirestore _db = FirebaseFirestore.instance;
// ================================================== 

// ========================= For Google Sign in
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<UserCredential?> login({bool forceAccountSelection = false}) async {
  try {
    if (forceAccountSelection) {
      await FirebaseAuth.instance.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
    debugPrint('Signed in: ${userCred.user?.email}');
    return userCred;

  } catch (e, st) {
    debugPrint('login() error: $e\n$st');
    rethrow;
  }
}
// ================================================== 

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<Offset> _logoSlide;

  late final AnimationController _textController;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  late final AnimationController _bottomController;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();

    //slide
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoController.forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });

    // Bottom slide
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
        );
    Future.delayed(const Duration(milliseconds: 500), () {
      _bottomController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  bool _isSigningIn = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F2D7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: Hero(
                        tag: 'logoHero',
                        child: SizedBox(
                          width: 230,
                          child: Image.asset(
                            alignment: Alignment.bottomCenter,
                            'assets/HeronVoteLogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "H",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: "erons",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                TextSpan(
                                  text: "Vote",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SlideTransition(
              position: _bottomSlide,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF354372),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 50
                ),
                child: GestureDetector(
                  onTap: () async{
                    if (_isSigningIn) return; 
                    setState(() => _isSigningIn = true);

                    try {
                      final userCred = await login(forceAccountSelection: true);

                      if (!mounted) return;

                      if (userCred == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Google sign-in cancelled.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      final user = userCred.user!;
                      final uid = user.uid;
                      final email = user.email ?? '';
                      final name = user.displayName ?? '';

                      final userRef = _db.collection('users').doc(uid);
                      final doc = await userRef.get();
                      
                      if (!email.toLowerCase().endsWith('@umak.edu.ph')) {
                        await FirebaseAuth.instance.signOut();
                        await _googleSignIn.signOut();

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Google sign-in failed. Please use your UMak Account.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
            
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Signed in as $email'),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      // Register User
                      await userRef.set({
                        'uid': uid,
                        'email': email,
                        'name': name,
                        'student_number': '',
                        'program': '',
                        'college': '',
                        'year_level': '',
                        'section': '',
                        'semester': '',
                        'gender': '',
                        'createdAt': doc.exists ? FieldValue.serverTimestamp() : DateTime.now(),
                        'lastUpdateCOR': DateTime.now(),
                      }, SetOptions(merge: true));

                      debugPrint(doc.exists ? 'User exists' : 'User registered');

                      if (!mounted) return;

                      // If login successful, go to authentication/verification page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegistrationStep1(uid: uid)),
                      );

                    } catch (e, st) {
                      debugPrint('Sign-in handler error: $e\n$st');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('An error occurred during sign-in.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isSigningIn = false);
                    }
                  },
                  child: Container(
                    height: 61,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6AA0),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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