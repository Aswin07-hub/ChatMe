import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'profile_options.dart';
import 'profile_setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────
// SAKTI Auth (Login & Signup) Bottom Sheet & Screen
// Implements OTP-based phone login, Google sign in, and
// onboarding signup flow matching SAKTI webapp LoginPage.jsx
// ─────────────────────────────────────────────

class LoginSignupSheet extends StatefulWidget {
  final bool isDark;
  final Map<String, String> t;
  final Locale locale;
  final Function(ProfileData? profile) onLoginSuccess;

  const LoginSignupSheet({
    super.key,
    required this.isDark,
    required this.t,
    required this.locale,
    required this.onLoginSuccess,
  });

  @override
  State<LoginSignupSheet> createState() => _LoginSignupSheetState();
}

class _LoginSignupSheetState extends State<LoginSignupSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String _step = 'phone'; // 'phone' | 'otp'
  bool _loading = false;
  String? _error;
  String? _verificationId;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool get _isTa => widget.locale.languageCode == 'ta';

  void _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    setState(() => _error = null);

    if (phone.length != 10 || int.tryParse(phone) == null) {
      setState(() {
        _error =
            _isTa
                ? 'சரியான 10 இலக்க தொலைபேசி எண்ணை உள்ளிடவும்'
                : 'Please enter a valid 10-digit phone number.';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => _loading = false);
          _finishLogin();
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = _friendlyError(e);
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!mounted) return;
          setState(() {
            _loading = false;
            _step = 'otp';
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  void _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    setState(() => _error = null);

    if (otp.length != 6) {
      setState(() {
        _error =
            _isTa
                ? '6 இலக்க OTP குறியீட்டை உள்ளிடவும்'
                : 'Please enter the 6-digit OTP code.';
      });
      return;
    }

    if (_verificationId == null) {
      setState(
        () =>
            _error =
                _isTa
                    ? 'OTP ஐ மீண்டும் கோரவும்.'
                    : 'Verification expired. Please request the OTP again.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() => _loading = false);
      _finishLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  void _signInGoogle() async {
    setState(() => _loading = true);
    try {
      final webClientId = AppConfig.googleWebClientId;
      final serverClientId =
          webClientId.isNotEmpty && !webClientId.contains('your_web')
              ? webClientId
              : null;
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn(serverClientId: serverClientId).signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() => _loading = false);
      _finishLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  /// Closes the sheet and opens profile setup. The navigator / messenger are
  /// captured BEFORE the sheet is popped - using this sheet's own `context`
  /// after it is closed caused "deactivated widget" crashes.
  void _finishLogin() {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isTa = _isTa;
    final onSuccess = widget.onLoginSuccess;
    final t = widget.t;
    final locale = widget.locale;
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder:
            (ctx) => ProfileSetupScreen(
              t: t,
              locale: locale,
              onComplete: (profile) {
                Navigator.of(ctx).pop();
                onSuccess(profile);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isTa
                          ? 'வரவேற்கிறோம்! உங்கள் விவரங்கள் வெற்றிகரமாக சேமிக்கப்பட்டன.'
                          : 'Welcome! Your profile has been set up successfully.',
                    ),
                    backgroundColor: const Color(0xFF7F1212),
                  ),
                );
              },
            ),
      ),
    );
  }

  /// Human-friendly (and translated) auth errors instead of raw exceptions.
  String _friendlyError(Object e) {
    final ta = _isTa;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return ta
              ? 'தொலைபேசி எண் தவறானது.'
              : 'That phone number is not valid.';
        case 'too-many-requests':
          return ta
              ? 'பல முறை முயற்சித்தீர்கள். சிறிது நேரம் கழித்து முயலவும்.'
              : 'Too many attempts. Please try again later.';
        case 'invalid-verification-code':
          return ta
              ? 'OTP தவறானது.'
              : 'Incorrect OTP. Please check and try again.';
        case 'session-expired':
        case 'code-expired':
          return ta
              ? 'OTP காலாவதியானது. மீண்டும் அனுப்பவும்.'
              : 'The OTP has expired. Please request a new one.';
        case 'network-request-failed':
          return ta
              ? 'இணைய இணைப்பைச் சரிபார்க்கவும்.'
              : 'Please check your internet connection.';
        case 'account-exists-with-different-credential':
          return ta
              ? 'இந்த கணக்கு வேறு முறையில் பதிவு செய்யப்பட்டுள்ளது.'
              : 'This account is already registered with another sign-in method.';
      }
    }
    return ta
        ? 'உள்நுழைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.'
        : 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheetBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // SAKTI App Logo & Subtitle
            Image.asset(
              'assets/images/app_logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              widget.t['appName'] ?? 'ChatMe',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF7F1212),
              ),
            ),
            Text(
              widget.t['govText']!.toUpperCase(),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _step == 'phone'
                  ? (widget.t['signIn'] ?? 'Sign In')
                  : (_isTa ? 'OTP சரிபார்ப்பு' : 'Verify Phone'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _step == 'phone'
                  ? (widget.t['signInModalSubtitle'] ??
                      'Sign in to save your chat history & get personalized recommendations')
                  : (_isTa
                      ? '+91 ${_phoneCtrl.text} என்ற எண்ணிற்கு OTP அனுப்பப்பட்டுள்ளது'
                      : 'We sent a 6-digit code to +91 ${_phoneCtrl.text}'),
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Error display
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── STEP 1: PHONE & GOOGLE ──
            if (_step == 'phone') ...[
              // Google Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _signInGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : Colors.grey.shade800,
                    side: BorderSide(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Icon
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.t['continueWithGoogle'] ??
                            'Continue with Google',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.t['or'] ?? 'or',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Phone Number Field (+91)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_iphone,
                          size: 18,
                          color: Color(0xFF7F1212),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+91',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                  hintText: _isTa ? '10 இலக்க எண்' : 'Enter 10-digit number',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
              const SizedBox(height: 18),

              // Send OTP / Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1212),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isTa ? 'OTP அனுப்பவும்' : 'Send OTP',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                ),
              ),
            ],

            // ── STEP 2: ENTER OTP ──
            if (_step == 'otp') ...[
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    letterSpacing: 6,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed:
                        () => setState(() {
                          _step = 'phone';
                          _otpCtrl.clear();
                          _error = null;
                        }),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 14,
                      color: Color(0xFF7F1212),
                    ),
                    label: Text(
                      _isTa ? 'எண்ணை மாற்றுக' : 'Change Number',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F1212),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _sendOtp,
                    child: Text(
                      _isTa ? 'மீண்டும் அனுப்புக' : 'Resend OTP',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF7F1212),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF7F1212),
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            _isTa
                                ? 'சரிபார்த்து தொடரவும்'
                                : 'Verify & Continue',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Continue as guest
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _isTa ? 'விருந்தினராக தொடரவும்' : 'Continue as Guest',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
