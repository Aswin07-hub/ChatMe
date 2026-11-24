import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_screen.dart';
import 'data/scheme_data_service.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'profile_options.dart';
import 'profile_screen.dart';
import 'services/gemini_service.dart';

const Color kBrand = Color(0xFF7F1212);
const Color kGold = Color(0xFFFFD700);

/// The window is drawn IMMEDIATELY (splash) and all heavy start-up work
/// happens behind it. Before, main() awaited .env + Firebase + the 570 KB
/// CSV parse before runApp(), so users stared at a blank screen.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  late Future<SharedPreferences> _boot = _bootstrap();

  Future<SharedPreferences> _bootstrap() async {
    await dotenv.load(fileName: '.env');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init failed: $e'); // app still works offline
    }
    // Fire-and-forget: parsed in a background isolate, never blocks the UI.
    unawaited(SchemeDataService().load().catchError((_) {}));
    unawaited(GeminiService().warmUp());
    return SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _boot,
      builder: (context, snap) {
        if (snap.hasData) return MyApp(prefs: snap.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child:
                  snap.hasError
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: kBrand,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text('Could not start ChatMe'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                () => setState(() => _boot = _bootstrap()),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 96,
                            height: 96,
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: kBrand,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    // Theme + language are now remembered between launches.
    _themeMode =
        widget.prefs.getString('theme') == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
    _locale = Locale(widget.prefs.getString('lang') == 'ta' ? 'ta' : 'en');
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    widget.prefs.setString(
      'theme',
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void toggleLanguage() {
    setState(() {
      _locale =
          _locale.languageCode == 'en'
              ? const Locale('ta')
              : const Locale('en');
    });
    widget.prefs.setString('lang', _locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatMe',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrand,
          primary: kBrand,
          secondary: kGold,
          surface: Colors.white,
        ),
        fontFamily: 'sans-serif',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrand,
          brightness: Brightness.dark,
          // Dark red on a dark surface was unreadable -> use gold in dark mode.
          primary: kGold,
          secondary: kGold,
          surface: const Color(0xFF1E1E1E),
        ),
        fontFamily: 'sans-serif',
      ),
      home: MainShell(
        prefs: widget.prefs,
        onThemeToggle: toggleTheme,
        onLanguageToggle: toggleLanguage,
        locale: _locale,
        themeMode: _themeMode,
      ),
    );
  }
}

// Global Translations Map
final Map<String, Map<String, String>> localizedValues = {
  'en': {
    'appName': 'ChatMe',
    'govText': 'Government of Tamil Nadu',
    'heroSubtitle': 'Empowering Citizens through Intelligent Governance',
    'heroTamilTop': 'Intelligent Governance',
    'heroTamilBottom': 'Government Guide',
    'launchCta': 'Launch Assistant',
    'exploreDirectory': 'View Directory',
    'newsTitle': 'Trending News & Announcements',
    'readMore': 'Read More',
    'categoriesTitle': 'Popular Scheme Categories',
    'categoriesSubtitle': 'Direct access to welfare systems',
    'agriTitle': 'Agriculture',
    'agriDesc': 'Subsidies & crop insurance',
    'eduTitle': 'Education',
    'eduDesc': 'Scholarships & student loans',
    'healthTitle': 'Healthcare',
    'healthDesc': 'Medical insurance & support',
    'seniorTitle': 'Senior Citizens',
    'seniorDesc': 'Pension schemes & wellness',
    'linkExplore': 'Explore Portal',
    'footerText':
        '© {year} GOVERNMENT OF TAMIL NADU • DIGITAL GOVERNANCE INITIATIVE',
    'searchPlaceholder': 'Type your query here... (English or Tamil)',
    'welcomeTitle': 'Welcome to ChatMe',
    'welcomeDesc':
        'Your intelligent assistant for Tamil Nadu government schemes. Ask me anything about subsidies, loans, or welfare.',
    'chatTab': 'Chat',
    'homeTab': 'Home',
    'profileTab': 'Profile',
    'aiAssistant': 'AI Assistant',
    'newChat': 'New Chat',
    'savedConvoNotice':
        'Your saved conversations will appear here after you sign in.',
    'signInToSaveChats': 'Sign in to save chats',
    'nearestCscCenter': 'Nearest CSC Center',
    'darkMode': 'Dark Mode',
    'lightMode': 'Light Mode',
    'signIn': 'Sign In',
    'voiceChat': 'Voice Chat',
    'voiceListening': 'Listening...',
    'voiceTapToStop': 'Tap the mic to stop',
    'voiceTapToSpeak': 'Tap the mic to start speaking',
    'voiceCancel': 'Cancel',
    'signInBannerText':
        'Sign in to save your chat history & get personalized recommendations',
    'signInModalTitle': 'Sign in to ChatMe',
    'signInModalSubtitle': 'Save your chats & get personalized recommendations',
    'emailOrPhone': 'Email / Phone Number',
    'password': 'Password',
    'or': 'or',
    'continueWithGoogle': 'Continue with Google',
    'chipEdu': 'Educational Scholarships',
    'chipFarmer': 'Farmer Subsidies',
    'chipWomen': 'Women Welfare',
    'chipHealth': 'Healthcare Schemes',
    'saktiPortal': 'ChatMe Portal',
    'disclaimerText':
        'ChatMe may produce inaccurate information about people, places, or facts.',
    'liveBadge': 'LIVE',
    'aiLiveBadge': 'AI LIVE',
    'fullName': 'Full Name',
    'age': 'Age',
    'gender': 'Gender',
    'district': 'District',
    'occupation': 'Occupation',
    'profileCity': 'Chennai, Tamil Nadu',
    'genderVal': 'Male',
    'occupationVal': 'Engineer',
    'districtVal': 'Chennai',
    'userName': 'ChatMe User',
    'womenWelfareNewsCat': 'WOMEN WELFARE',
    'welfareNewsCat': 'WELFARE',
    'guestUser': 'Guest User',
    'notSignedIn': 'Not Signed In',
    'signInToViewProfile':
        'Sign in to access your profile and personalized welfare schemes.',
    'setupProfile': 'Set Up Profile',
    'editProfile': 'Edit Profile',
    'educationLevel': 'Education Level',
    'annualIncome': 'Annual Income',
    'specialCategories': 'Special Categories',
    'studentStatus': 'Student Status',
    'farmerStatus': 'Farmer Status',
    'disabilityStatus': 'Differently Abled',
    'logout': 'Sign Out',
    'yes': 'Yes',
    'no': 'No',
    'closeVoice': 'Close Voice',
    'thinking': 'Thinking...',
    'talking': 'Talking...',
    'greeting': 'Greetings...',
    'serverSlow':
        'The server is waking up, this may take a few more seconds...',
    'speechUnavailable': 'Speech recognition is not available on this device',
    'voiceError': 'Could not get a response. Please try again.',
    'detailsError': 'Unable to load details for this scheme',
    'loadingDetails': 'Loading scheme details...',
    'copied': 'Copied to clipboard',
    'signedOut': 'You have been signed out',
    'latestUpdate': 'Latest update',
    'backToList': 'Back to List',
    'viewDetails': '📖 View Full Details',
  },
  'ta': {
    'appName': 'ChatMe',
    'govText': 'தமிழ்நாடு அரசு',
    'heroSubtitle': 'அறிவுசார் ஆளுகை மூலம் குடிமக்களுக்கு அதிகாரம் அளித்தல்',
    'heroTamilTop': 'மக்களுக்கான அறிவுசார்',
    'heroTamilBottom': 'அரசு வழிகாட்டி',
    'launchCta': 'உதவியாளரைத் தொடங்கு',
    'exploreDirectory': 'அடைவை பார்க்க',
    'newsTitle': 'பிரபலமான செய்திகள் & அறிவிப்புகள்',
    'readMore': 'மேலும் படிக்க',
    'categoriesTitle': 'பிரபலமான திட்டப் பிரிவுகள்',
    'categoriesSubtitle': 'நேரடி நலத்திட்ட உதவிகள்',
    'agriTitle': 'வேளாண்மை',
    'agriDesc': 'மானியங்கள் & பயிர் காப்பீடு',
    'eduTitle': 'கல்வி',
    'eduDesc': 'உதவித்தொகை & கல்விக்கடன்',
    'healthTitle': 'சுகாதாரம்',
    'healthDesc': 'மருத்துவ காப்பீடு & ஆதரவு',
    'seniorTitle': 'மூத்த குடிமக்கள்',
    'seniorDesc': 'ஓய்வூதிய திட்டங்கள்',
    'linkExplore': 'இணையதளத்தைப் பார்',
    'footerText': '© {year} தமிழ்நாடு அரசு • டிஜிட்டல் ஆளுகை முன்முயற்சி',
    'searchPlaceholder':
        'உங்கள் கேள்வியை இங்கே தட்டச்சு செய்க... (தமிழ் அல்லது ஆங்கிலம்)',
    'welcomeTitle': 'ChatMe-க்கு உங்களை வரவேற்கிறோம்',
    'welcomeDesc':
        'தமிழ்நாடு அரசு நலத்திட்டங்களுக்கான உங்களின் அறிவுசார் உதவியாளர். மானியங்கள், கடன்கள் அல்லது நலத்திட்டங்கள் பற்றி கேளுங்கள்.',
    'chatTab': 'அரட்டை',
    'homeTab': 'முகப்பு',
    'profileTab': 'சுயவிவரம்',
    'aiAssistant': 'செயற்கை நுண்ணறிவு உதவியாளர்',
    'newChat': 'புதிய அரட்டை',
    'savedConvoNotice':
        'நீங்கள் உள்நுழைந்த பிறகு உங்கள் சேமிக்கப்பட்ட உரையாடல்கள் இங்கே தோன்றும்.',
    'signInToSaveChats': 'அரட்டைகளைச் சேமிக்க உள்நுழைக',
    'nearestCscCenter': 'அருகிலுள்ள இ-சேவை மையம்',
    'darkMode': 'இருண்ட பயன்முறை',
    'lightMode': 'வெளிச்ச பயன்முறை',
    'signIn': 'உள்நுழைக',
    'voiceChat': 'குரல் அரட்டை',
    'voiceListening': 'கேட்கிறது...',
    'voiceTapToStop': 'நிறுத்த மைக்-ஐ தட்டவும்',
    'voiceTapToSpeak': 'பேசத் தொடங்க மைக்-ஐ தட்டவும்',
    'voiceCancel': 'ரத்துசெய்',
    'signInBannerText':
        'உங்கள் அரட்டை வரலாற்றைச் சேமிக்கவும் தனிப்பயனாக்கப்பட்ட பரிந்துரைகளைப் பெறவும் உள்நுழைக',
    'signInModalTitle': 'ChatMe-இல் உள்நுழைக',
    'signInModalSubtitle':
        'அரட்டைகளைச் சேமித்து தனிப்பயன் பரிந்துரைகளைப் பெறுங்கள்',
    'emailOrPhone': 'மின்னஞ்சல் / தொலைபேசி எண்',
    'password': 'கடவுச்சொல்',
    'or': 'அல்லது',
    'continueWithGoogle': 'கூகிள் மூலம் தொடரவும்',
    'chipEdu': 'கல்வி உதவித்தொகை',
    'chipFarmer': 'விவசாய மானியங்கள்',
    'chipWomen': 'மகளிர் நலன்',
    'chipHealth': 'சுகாதார திட்டங்கள்',
    'saktiPortal': 'ChatMe போர்டல்',
    'disclaimerText': 'ChatMe சில நேரங்களில் தவறான தகவல்களை வழங்கக்கூடும்.',
    'liveBadge': 'நேரலை',
    'aiLiveBadge': 'செயற்கை நுண்ணறிவு நேரலை',
    'fullName': 'முழு பெயர்',
    'age': 'வயது',
    'gender': 'பாலினம்',
    'district': 'மாவட்டம்',
    'occupation': 'தொழில்',
    'profileCity': 'சென்னை, தமிழ்நாடு',
    'genderVal': 'ஆண்',
    'occupationVal': 'பொறியாளர்',
    'districtVal': 'சென்னை',
    'userName': 'ChatMe பயனர்',
    'womenWelfareNewsCat': 'மகளிர் நலம்',
    'welfareNewsCat': 'நலத்திட்டம்',
    'guestUser': 'விருந்தினர் பயனர்',
    'notSignedIn': 'உள்நுழையவில்லை',
    'signInToViewProfile':
        'உங்கள் சுயவிவரம் மற்றும் தனிப்பயன் திட்டங்களை அணுக உள்நுழைக.',
    'setupProfile': 'சுயவிவரத்தை பதிவுசெய்க',
    'editProfile': 'சுயவிவரத்தைத் திருத்து',
    'educationLevel': 'கல்வித் தகுதி',
    'annualIncome': 'ஆண்டு வருமானம்',
    'specialCategories': 'சிறப்பு தகுதிப் பிரிவுகள்',
    'studentStatus': 'மாணவர் நிலை',
    'farmerStatus': 'விவசாயி நிலை',
    'disabilityStatus': 'மாற்றுத்திறனாளி நிலை',
    'logout': 'வெளியேறுக',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'closeVoice': 'குரலை மூடு',
    'thinking': 'யோசிக்கிறது...',
    'talking': 'பேசுகிறது...',
    'greeting': 'வணக்கம்...',
    'serverSlow':
        'சர்வர் இயங்கத் தொடங்குகிறது, இன்னும் சில விநாடிகள் ஆகலாம்...',
    'speechUnavailable': 'இந்த சாதனத்தில் குரல் அறிதல் கிடைக்கவில்லை',
    'voiceError': 'பதிலைப் பெற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    'detailsError': 'இந்தத் திட்டத்தின் விவரங்களை ஏற்ற முடியவில்லை',
    'loadingDetails': 'திட்ட விவரங்கள் ஏற்றப்படுகின்றன...',
    'copied': 'நகலெடுக்கப்பட்டது',
    'signedOut': 'நீங்கள் வெளியேறிவிட்டீர்கள்',
    'latestUpdate': 'சமீபத்திய தகவல்',
    'backToList': 'பட்டியலுக்கு திரும்பு',
    'viewDetails': '📖 முழு விவரங்களைப் பார்க்க',
  },
};

class MainShell extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final Locale locale;
  final ThemeMode themeMode;

  const MainShell({
    super.key,
    required this.prefs,
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.locale,
    required this.themeMode,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _profileKey = 'chatme_profile';
  int _currentIndex = 0;
  ProfileData? _userProfile;

  @override
  void initState() {
    super.initState();
    _restoreProfile();
  }

  /// Restores the saved profile ONLY if the Firebase session is still valid.
  /// (Before: the sign-in survived an app restart but the profile did not.)
  void _restoreProfile() {
    try {
      final raw = widget.prefs.getString(_profileKey);
      final signedIn =
          Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
      if (raw == null || !signedIn) return;
      _userProfile = ProfileData.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      /* corrupted data -> behave as guest */
    }
  }

  void _handleProfileUpdate(ProfileData? profile) {
    setState(() => _userProfile = profile);
    if (profile != null) {
      widget.prefs.setString(_profileKey, jsonEncode(profile.toMap()));
    }
  }

  Future<void> _handleLogout() async {
    final t = localizedValues[widget.locale.languageCode]!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _userProfile = null;
      _currentIndex = 0;
    });
    await widget.prefs.remove(_profileKey);
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut(); // was never called before
    } catch (_) {}
    messenger.showSnackBar(
      SnackBar(content: Text(t['signedOut'] ?? 'Signed out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = localizedValues[widget.locale.languageCode]!.map(
      (k, v) =>
          MapEntry(k, v.replaceAll('{year}', DateTime.now().year.toString())),
    );

    // Back button: go to Home first, exit only from Home.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        // IndexedStack keeps the chat (messages, scroll) alive when you
        // switch tabs. Before, every tab switch wiped the conversation.
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              t: t,
              onThemeToggle: widget.onThemeToggle,
              onLanguageToggle: widget.onLanguageToggle,
              locale: widget.locale,
              themeMode: widget.themeMode,
              onNavigateToChat: () => setState(() => _currentIndex = 1),
            ),
            ChatScreen(
              t: t,
              onThemeToggle: widget.onThemeToggle,
              onLanguageToggle: widget.onLanguageToggle,
              locale: widget.locale,
              themeMode: widget.themeMode,
              userProfile: _userProfile,
              onLoginSuccess: _handleProfileUpdate,
              onLogout: _handleLogout,
              onNavigateHome: () => setState(() => _currentIndex = 0),
            ),
            ProfileScreen(
              t: t,
              locale: widget.locale,
              userProfile: _userProfile,
              onProfileUpdated: _handleProfileUpdate,
              onLogout: _handleLogout,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: isDark ? kGold.withAlpha(60) : kBrand.withAlpha(25),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: isDark ? kGold : kBrand),
              label: t['homeTab'] ?? 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(
                Icons.chat_bubble,
                color: isDark ? kGold : kBrand,
              ),
              label: t['chatTab'] ?? 'Chat',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: isDark ? kGold : kBrand),
              label: t['profileTab'] ?? 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------

// ----------------------------------------------------
// Custom Painted Emblem representing Tamil Nadu's SAKTI Digital Seal
// ----------------------------------------------------
class SaktiEmblemPainter extends CustomPainter {
  final double opacity;
  SaktiEmblemPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF7F1212).withAlpha((opacity * 255).toInt())
          ..style = PaintingStyle.fill;

    // Draw stylized outer shield matching Web App Emblem style
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.05,
      size.width,
      size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.75,
      size.width * 0.5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.75,
      0,
      size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.05,
      size.width * 0.5,
      0,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Inner gold highlights
    final goldPaint =
        Paint()
          ..color = const Color(0xFFFFD700).withAlpha((opacity * 255).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final innerPath = Path();
    innerPath.moveTo(size.width * 0.5, size.height * 0.1);
    innerPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.14,
      size.width * 0.88,
      size.height * 0.3,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.84,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.9,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.16,
      size.height * 0.7,
      size.width * 0.12,
      size.height * 0.3,
    );
    innerPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.14,
      size.width * 0.5,
      size.height * 0.1,
    );
    canvas.drawPath(innerPath, goldPaint);

    // Central digital glowing node
    final nodePaint =
        Paint()
          ..color = const Color(0xFFFFD700).withAlpha((opacity * 255).toInt())
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      3.5,
      nodePaint,
    );

    // Dynamic lightning lines (representing SAKTI energy)
    final linePaint =
        Paint()
          ..color = Colors.white.withAlpha(((opacity * 0.8) * 255).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
