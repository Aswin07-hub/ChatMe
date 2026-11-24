import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_html/flutter_html.dart';

import 'login_sheet.dart';
import 'profile_options.dart';
import 'services/gemini_service.dart';
import 'data/scheme_data_service.dart';
import 'data/top_schemes_data.dart';

// ─────────────────────────────────────────────
// ChatMe Chat Screen — Mobile-first design
// Mirrors the web interface: side-drawer via burger,
// voice-chat button, welcome state, chips, sign-in banner.
// Integrated with LoginSignupSheet and ProfileWizard.
// ─────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final Map<String, String> t;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final Locale locale;
  final ThemeMode themeMode;
  final ProfileData? userProfile;
  final void Function(ProfileData?)? onLoginSuccess;
  final VoidCallback? onLogout;
  final VoidCallback? onNavigateHome;

  const ChatScreen({
    super.key,
    required this.t,
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.locale,
    required this.themeMode,
    this.userProfile,
    this.onLoginSuccess,
    this.onLogout,
    this.onNavigateHome,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];
  bool _showVoicePanel = false;
  bool _isDictating = false;
  bool _inputMicUserStopped = true;
  String _dictationAccumulatedText = '';

  int? _activeSpokenMessageIndex;
  // Word highlight lives in a ValueNotifier so ONLY the spoken text repaints
  // (before, every word tick rebuilt + re-parsed the whole HTML bubble).
  final ValueNotifier<int> _spokenWord = ValueNotifier<int>(-1);
  int? get _activeSpokenWordIndex =>
      _spokenWord.value < 0 ? null : _spokenWord.value;
  set _activeSpokenWordIndex(int? v) => _spokenWord.value = v ?? -1;

  bool _isSending = false; // blocks double-send / mixed-up replies
  final ValueNotifier<bool> _slow = ValueNotifier<bool>(false);
  final Map<String, String> _htmlCache = {};
  Timer? _highlightTimer;

  final GeminiService _geminiService = GeminiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  String _voiceState =
      'idle'; // idle, connecting, listening, thinking, speaking
  final List<Uint8List> _audioQueue = [];
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Maintain earlier design: _messages starts completely empty

    _audioPlayer.onPlayerComplete.listen((_) {
      _highlightTimer?.cancel();
      _activeSpokenMessageIndex = null;
      _activeSpokenWordIndex = null;
      _isPlayingAudio = false;
      if (mounted) setState(() {});
      _playNextAudio();
    });
  }

  Future<bool> _ensureSpeech() async {
    if (_speechEnabled) return true;
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (!_showVoicePanel) {
          if (status == 'done' || status == 'notListening') {
            if (_isDictating && !_inputMicUserStopped) {
              _dictationAccumulatedText = _controller.text;
              if (_dictationAccumulatedText.isNotEmpty &&
                  !_dictationAccumulatedText.endsWith(' ')) {
                _dictationAccumulatedText += ' ';
              }
              Future.delayed(const Duration(milliseconds: 50), () {
                if (_isDictating &&
                    !_inputMicUserStopped &&
                    !_speechToText.isListening) {
                  _startDictationSession();
                }
              });
            } else if (_isDictating) {
              setState(() => _isDictating = false);
            }
          }
          return;
        }

        if (status == 'done' || status == 'notListening') {
          if (_voiceState == 'listening') {
            _processSpeechResult();
          }
        }
      },
      onError: (errorNotification) {
        if (!mounted) return;
        if (!_showVoicePanel) {
          if (_isDictating && !_inputMicUserStopped) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (_isDictating &&
                  !_inputMicUserStopped &&
                  !_speechToText.isListening) {
                _startDictationSession();
              }
            });
          } else if (_isDictating) {
            setState(() => _isDictating = false);
          }
          return;
        }
        _processSpeechResult();
      },
    );
    return _speechEnabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_showVoicePanel) {
        _stopVoiceChat();
      } else if (_isDictating) {
        _inputMicUserStopped = true;
        _speechToText.stop();
        if (mounted) setState(() => _isDictating = false);
      }
      _audioPlayer.stop();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _highlightTimer?.cancel();
    _spokenWord.dispose();
    _slow.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _sendMessage([String? predefined]) {
    final text = (predefined ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add({'sender': 'user', 'text': text});
      // Show loading placeholder while awaiting response
      _messages.add({'sender': 'bot', 'text': '…'});
    });
    _controller.clear();
    _scrollToBottom();

    final lower = text.toLowerCase().trim();

    // 1. If the user explicitly asks for top 5 schemes or flagship schemes,
    // display all 5 schemes in the webapp frontend format
    final isExplicitTop5 =
        lower.contains('top 5') ||
        lower.contains('top five') ||
        lower.contains('top scheme') ||
        lower.contains('flagship') ||
        lower.contains('5 scheme') ||
        lower.contains('five scheme') ||
        lower.contains('முக்கிய 5') ||
        lower.contains('முதல் 5') ||
        lower.contains('5 திட்டங்கள்') ||
        lower.contains('ஐந்து திட்டங்கள்');

    if (isExplicitTop5) {
      final lang = widget.locale.languageCode;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          if (_messages.isNotEmpty &&
              _messages.last['sender'] == 'bot' &&
              _messages.last['text'] == '…') {
            _messages.removeLast();
          }
          _messages.add({
            'sender': 'bot',
            'text': TopSchemesRepository.formatTop5SchemesHtml(lang),
          });
          _isSending = false;
        });
        _scrollToBottom();
      });
      return;
    }

    // 2. Forward queries (including broad scheme queries) to Gemini Service
    // so the agentic AI router can evaluate intent, ask clarification questions,
    // and customize recommendations according to user profile and facts.
    _fetchGeminiResponse(text);
  }

  Future<void> _fetchGeminiResponse(String prompt) async {
    _slow.value = false;
    final slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) _slow.value = true;
    });
    try {
      await _fetchGeminiResponseInner(prompt);
    } finally {
      slowTimer.cancel();
      _slow.value = false;
      _isSending = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchGeminiResponseInner(String prompt) async {
    final lang = widget.locale.languageCode;
    final isTa = lang == 'ta';
    final lower = prompt.toLowerCase().trim();

    // Check if query is looking for schemes
    final isSchemeSearchIntent =
        lower.contains('scheme') ||
        lower.contains('scholarship') ||
        lower.contains('student') ||
        lower.contains('education') ||
        lower.contains('postgraduate') ||
        lower.contains('college') ||
        lower.contains('school') ||
        lower.contains('degree') ||
        lower.contains('farmer') ||
        lower.contains('agriculture') ||
        lower.contains('women') ||
        lower.contains('girl') ||
        lower.contains('health') ||
        lower.contains('disability') ||
        lower.contains('pension') ||
        lower.contains('subsidy') ||
        lower.contains('welfare') ||
        lower.contains('திட்டம்') ||
        lower.contains('கல்வி') ||
        lower.contains('மாணவர்') ||
        lower.contains('உதவித்தொகை') ||
        lower.contains('விவசாய') ||
        lower.contains('மகளிர்') ||
        lower.contains('பெண்') ||
        lower.contains('மருத்துவம்');

    try {
      final data = await _geminiService.generateResponse(
        prompt,
        lang,
        widget.userProfile?.toMap(),
      );
      if (!mounted) return;

      final text =
          data['response'] ??
          data['answer'] ??
          data['message'] ??
          data['text'] ??
          '';
      final isClarification = data['is_clarification'] == true;
      String finalHtml = text.toString();

      // If backend response is an agentic clarification question, display it directly
      // without overriding with local schemes!
      if (isClarification) {
        finalHtml = _sanitizeSchemeResponse(finalHtml);
      } else if (finalHtml.contains('scheme-btn')) {
        finalHtml = _sanitizeSchemeResponse(finalHtml);
      } else if (isSchemeSearchIntent) {
        // Backend returned unformatted LLM text without buttons (e.g. AI Summary essay)
        // Format the top 5 matching schemes with proper View Full Details buttons
        final localResults = SchemeDataService().search(prompt, limit: 5);
        if (localResults.isNotEmpty) {
          finalHtml = SchemeDataService.formatMultiSchemeHtml(
            localResults,
            lang,
          );
        } else {
          finalHtml = _sanitizeSchemeResponse(finalHtml);
        }
      }

      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last['sender'] == 'bot' &&
            _messages.last['text'] == '…') {
          _messages.removeLast();
        }
        _messages.add({'sender': 'bot', 'text': finalHtml});
      });
    } catch (_) {
      // Fallback to local SchemeDataService if network/gateway is temporarily down
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last['sender'] == 'bot' &&
            _messages.last['text'] == '…') {
          _messages.removeLast();
        }

        final localResults = SchemeDataService().search(prompt, limit: 5);
        if (localResults.isNotEmpty) {
          _messages.add({
            'sender': 'bot',
            'text': SchemeDataService.formatMultiSchemeHtml(localResults, lang),
          });
        } else {
          final fallbackMsg =
              isTa
                  ? "மன்னிக்கவும், தகவல் பெற முடியவில்லை. 'கல்வி உதவித்தொகை' அல்லது 'விவசாயிகள் மானியம்' போன்ற தலைப்புகளில் தேட முயற்சிக்கவும்."
                  : "Sorry, I could not fetch information for that request. Try asking about 'Educational Scholarships' or other welfare categories.";
          _messages.add({'sender': 'bot', 'text': fallbackMsg});
        }
      });
    }
    _scrollToBottom();
  }

  /// Strip unwanted trailing LLM hallucinated application text from multi-scheme list
  String _sanitizeSchemeResponse(String text) {
    final pattern = RegExp(
      r'(How to Apply and Get More Information:?|விண்ணப்பிப்பது எப்படி:?).*$',
      caseSensitive: false,
      dotAll: true,
    );
    return text.replaceFirst(pattern, '').trim();
  }

  // ──────────────────────────────────────────────
  // SCHEME DETAILS INLINE (mirrors webapp format)
  // ──────────────────────────────────────────────
  Future<void> _viewSchemeDetails(
    String schemeId,
    int msgIndex,
    bool isDark,
  ) async {
    final msg = _messages[msgIndex];
    final originalText = msg['text'];
    final lang = widget.locale.languageCode;

    setState(() {
      msg['original_text'] = originalText;
      msg['text'] =
          '<div style="font-style: italic; padding: 12px; color: ${isDark ? "#9CA3AF" : "#4B5563"};">${widget.t['loadingDetails'] ?? 'Loading scheme details...'}</div>';
    });

    final backText = lang == 'ta' ? 'பட்டியலுக்கு திரும்பு' : 'Back to List';
    final backButton =
        '<button class="back-btn">&larr; $backText</button><br/>';

    // 1. Check curated Top 5 Schemes (instant rich presentation)
    final topScheme = TopSchemesRepository.findById(schemeId);
    if (topScheme != null) {
      final fullHtml = TopSchemesRepository.formatFullSchemeHtml(
        topScheme,
        lang,
      );
      if (mounted) {
        setState(() {
          msg['text'] = '$backButton$fullHtml';
        });
        _scrollToBottom();
      }
      return;
    }

    // 2. Check bundled SchemeDataService (instant verified full details for all 222 schemes)
    final localScheme = SchemeDataService().findById(schemeId);
    if (localScheme != null) {
      final fullHtml = SchemeDataService.formatFullSchemeHtml(
        localScheme,
        lang,
      );
      if (mounted) {
        setState(() {
          msg['text'] = '$backButton$fullHtml';
        });
        _scrollToBottom();
      }
      return;
    }

    // 3. Fallback to Gemini Service / Backend for cloud-only scheme IDs
    try {
      final detailsHtml = await _geminiService.fetchSchemeDetails(
        schemeId,
        lang,
      );
      if (!mounted) return;
      if (detailsHtml.contains("Scheme not found")) {
        throw Exception("Scheme not found");
      }
      setState(() {
        msg['text'] = '$backButton$detailsHtml';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        msg['text'] = originalText;
      });
      _snack(
        widget.t['detailsError'] ?? 'Unable to load details for this scheme',
      );
    }
    _scrollToBottom();
  }

  // ──────────────────────────────────────────────
  // DRAWER — mirrors web sidebar with full localization
  // ──────────────────────────────────────────────
  Widget _buildDrawer(bool isDark) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Drawer(
      width: 290,
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: logo + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.t['appName'] ?? 'ChatMe',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color:
                              isDark ? Colors.white : const Color(0xFF7F1212),
                        ),
                      ),
                      Text(
                        widget.t['aiAssistant'] ?? 'AI Assistant',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),

            // New Chat button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _geminiService.resetSession();
                    setState(() {
                      _messages.clear();
                      _htmlCache.clear();
                      _isSending = false;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    widget.t['newChat'] ?? 'New Chat',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1212),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign-in notice card (guests only)
            if (widget.userProfile == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 28,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.t['savedConvoNotice'] ??
                            'Your saved conversations will appear here after you sign in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLoginSheet(context, isDark);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7F1212),
                            side: const BorderSide(color: Color(0xFF7F1212)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            widget.t['signInToSaveChats'] ??
                                'Sign in to save chats',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),
            Divider(height: 1, color: dividerColor),

            // Bottom drawer items
            _drawerItem(
              isDark,
              icon: Icons.location_on_outlined,
              label: widget.t['nearestCscCenter'] ?? 'Nearest CSC Center',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://tnega.tn.gov.in/csclocation');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _drawerItem(
              isDark,
              icon:
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label:
                  isDark
                      ? (widget.t['lightMode'] ?? 'Light Mode')
                      : (widget.t['darkMode'] ?? 'Dark Mode'),
              onTap: () {
                Navigator.pop(context);
                widget.onThemeToggle();
              },
            ),
            // Language toggle row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.translate, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  _langChip('தமிழ்', 'ta', isDark),
                  const SizedBox(width: 6),
                  _langChip('English', 'en', isDark),
                ],
              ),
            ),
            _drawerItem(
              isDark,
              icon: Icons.home_outlined,
              label: widget.t['homeTab'] ?? 'Home',
              onTap: () {
                Navigator.pop(context);
                if (widget.onNavigateHome != null) {
                  widget.onNavigateHome!();
                }
              },
            ),
            if (widget.userProfile == null)
              _drawerItem(
                isDark,
                icon: Icons.login,
                label: widget.t['signIn'] ?? 'Sign In',
                labelColor: const Color(0xFF7F1212),
                iconColor: const Color(0xFF7F1212),
                onTap: () {
                  Navigator.pop(context);
                  _showLoginSheet(context, isDark);
                },
              )
            else
              _drawerItem(
                isDark,
                icon: Icons.logout,
                label: widget.t['logout'] ?? 'Sign Out',
                labelColor: const Color(0xFF7F1212),
                iconColor: const Color(0xFF7F1212),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout?.call();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    bool isDark, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color:
            iconColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color:
              labelColor ??
              (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  Widget _langChip(String label, String code, bool isDark) {
    final isActive = widget.locale.languageCode == code;
    return GestureDetector(
      onTap: () {
        if (!isActive) widget.onLanguageToggle();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFF7F1212)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isActive
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  void _showLoginSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => LoginSignupSheet(
            isDark: isDark,
            t: widget.t,
            locale: widget.locale,
            onLoginSuccess: (profile) {
              if (widget.onLoginSuccess != null) {
                widget.onLoginSuccess!(profile);
              }
            },
          ),
    );
  }

  // ──────────────────────────────────────────────
  // WELCOME STATE (Earlier design with 4 category chips)
  // ──────────────────────────────────────────────
  Widget _buildWelcomeState(bool isDark) {
    final chips = [
      widget.t['chipEdu'] ?? 'Educational Scholarships',
      widget.t['chipFarmer'] ?? 'Farmer Subsidies',
      widget.t['chipWomen'] ?? 'Women Welfare',
      widget.t['chipHealth'] ?? 'Healthcare Schemes',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          // App Logo
          Image.asset(
            'assets/images/app_logo.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            widget.t['welcomeTitle'] ?? 'Welcome to ChatMe',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.t['welcomeDesc'] ??
                'Your intelligent assistant for Tamil Nadu government schemes. Ask me anything about subsidies, loans, or welfare.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Sign-in banner (matches web's info bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.t['signInBannerText'] ??
                        'Sign in to save your chat history & get personalized recommendations',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showLoginSheet(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1212),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.t['signIn'] ?? 'Sign In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Earlier design 4 quick-action chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                chips.map((label) {
                  return GestureDetector(
                    onTap: () => _sendMessage(label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HTML FORMATTING & INTERACTIVITY
  // ──────────────────────────────────────────────
  String _processMessageHtml(String text, int index) {
    if (_htmlCache.length > 300) _htmlCache.clear();
    return _htmlCache.putIfAbsent(
      '$index|${text.hashCode}',
      () => _convertHtml(text, index),
    );
  }

  String _plain(String html) =>
      html
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&larr;', '')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();

  Widget _buildSpokenText(String html, bool isDark) {
    final words = _plain(html).split(RegExp(r'\s+'));
    final base = TextStyle(
      fontSize: 14,
      height: 1.55,
      color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937),
    );
    return ValueListenableBuilder<int>(
      valueListenable: _spokenWord,
      builder:
          (context, active, _) => Text.rich(
            TextSpan(
              style: base,
              children: [
                for (var i = 0; i < words.length; i++)
                  TextSpan(
                    text: i == words.length - 1 ? words[i] : '${words[i]} ',
                    style:
                        i == active
                            ? TextStyle(
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF064E3B),
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )
                            : null,
                  ),
              ],
            ),
          ),
    );
  }

  String _convertHtml(String text, int index) {
    var html = text.replaceAllMapped(
      RegExp(
        r'<button[^>]*scheme-btn[^>]*>(.*?)</button>',
        caseSensitive: false,
      ),
      (match) {
        final fullTag = match.group(0) ?? '';
        final innerText = match.group(1) ?? '';
        final idMatch =
            RegExp(r'data-scheme-id="([^"]+)"').firstMatch(fullTag) ??
            RegExp(r"data-scheme-id='([^']+)'").firstMatch(fullTag);
        final schemeId = idMatch?.group(1) ?? '';
        return '<a class="scheme-btn" href="scheme://$schemeId">$innerText</a>';
      },
    );
    html = html.replaceAllMapped(
      RegExp(r'<button[^>]*back-btn[^>]*>(.*?)</button>', caseSensitive: false),
      (match) {
        final innerText = match.group(1) ?? '';
        return '<a class="back-btn" href="back://$index">$innerText</a>';
      },
    );
    return html;
  }

  // ──────────────────────────────────────────────
  // MESSAGES LIST (mirrors webapp MessageBubble.jsx & styles.css)
  // ──────────────────────────────────────────────
  Widget _buildMessages(bool isDark) {
    return SelectionArea(
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isUser = msg['sender'] == 'user';
          final isThinking = !isUser && msg['text'] == '…';

          if (isUser) {
            return Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.82,
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  // Signature Crimson Red bubble with Golden Yellow border
                  color: const Color(0xFF7F1212),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F1212).withAlpha(55),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg['text'] ?? '',
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          // Assistant / ChatMe Bot Message in Yellow bubble with Golden border & Red accent
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bot Avatar with TN Govt Emblem - Yellow & Red ring
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7F1212),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Message Content Bubble in Warm Vibrant Yellow with Golden Border
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.84,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF28200E)
                              : const Color(0xFFFEF3C7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0xFFFFD700).withAlpha(160)
                                : const Color(0xFFFFD700),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bot Name Header in Signature Red with Golden accent
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.t['appName'] ?? 'ChatMe',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF7F1212),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isDark
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF7F1212),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isThinking)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        isDark
                                            ? const Color(0xFFFFD700)
                                            : const Color(0xFF7F1212),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ValueListenableBuilder<bool>(
                                  valueListenable: _slow,
                                  builder:
                                      (context, slow, _) => Flexible(
                                        child: Text(
                                          slow
                                              ? (widget.t['serverSlow'] ??
                                                  'The server is waking up...')
                                              : (widget.t['thinking'] ??
                                                  'Thinking...'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color:
                                                isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child:
                                index == _activeSpokenMessageIndex
                                    ? _buildSpokenText(
                                      msg['text'] ?? '',
                                      isDark,
                                    )
                                    : Html(
                                      data: _processMessageHtml(
                                        msg['text'] ?? '',
                                        index,
                                      ),
                                      extensions: [
                                        // 1. Webapp Scheme Button (.scheme-btn)
                                        MatcherExtension(
                                          matcher:
                                              (ctx) => ctx.classes.contains(
                                                'scheme-btn',
                                              ),
                                          builder: (ctx) {
                                            final schemeId =
                                                ctx.attributes['data-scheme-id'] ??
                                                (ctx.attributes['href']
                                                        ?.replaceFirst(
                                                          'scheme://',
                                                          '',
                                                        ) ??
                                                    '');
                                            final text =
                                                ctx.element?.text ?? '';
                                            final isTa =
                                                widget.locale.languageCode ==
                                                'ta';
                                            final defaultText =
                                                isTa
                                                    ? "📖 முழு விவரங்களைப் பார்க்க"
                                                    : "📖 View Full Details";
                                            final btnText =
                                                text.trim().isNotEmpty
                                                    ? text.trim()
                                                    : defaultText;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                                bottom: 8,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap:
                                                      () => _viewSchemeDetails(
                                                        schemeId,
                                                        index,
                                                        isDark,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Ink(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isDark
                                                              ? const Color(
                                                                0xFF10B981,
                                                              )
                                                              : const Color(
                                                                0xFF064E3B,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withAlpha(25),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      btnText,
                                                      style: TextStyle(
                                                        color:
                                                            isDark
                                                                ? const Color(
                                                                  0xFF064E3B,
                                                                )
                                                                : Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // 2. Webapp Back to List Button (.back-btn)
                                        MatcherExtension(
                                          matcher:
                                              (ctx) => ctx.classes.contains(
                                                'back-btn',
                                              ),
                                          builder: (ctx) {
                                            final text =
                                                ctx.element?.text ?? '';
                                            final isTa =
                                                widget.locale.languageCode ==
                                                'ta';
                                            final defaultText =
                                                isTa
                                                    ? "பட்டியலுக்கு திரும்பு"
                                                    : "Back to List";
                                            final cleanText =
                                                text
                                                    .trim()
                                                    .replaceAll('←', '')
                                                    .replaceAll('&larr;', '')
                                                    .trim();
                                            final btnText =
                                                cleanText.isNotEmpty
                                                    ? cleanText
                                                    : defaultText;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                bottom: 12,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (_messages[index]
                                                          .containsKey(
                                                            'original_text',
                                                          )) {
                                                        _messages[index]['text'] =
                                                            _messages[index]['original_text'];
                                                      }
                                                    });
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Ink(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isDark
                                                              ? const Color(
                                                                0xFFF59E0B,
                                                              )
                                                              : const Color(
                                                                0xFFD97706,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withAlpha(25),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.arrow_back,
                                                          size: 15,
                                                          color:
                                                              isDark
                                                                  ? const Color(
                                                                    0xFF78350F,
                                                                  )
                                                                  : Colors
                                                                      .white,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          btnText,
                                                          style: TextStyle(
                                                            color:
                                                                isDark
                                                                    ? const Color(
                                                                      0xFF78350F,
                                                                    )
                                                                    : Colors
                                                                        .white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                      onLinkTap: (url, _, _) {
                                        if (url != null &&
                                            url.startsWith('scheme://')) {
                                          final schemeId = url.replaceFirst(
                                            'scheme://',
                                            '',
                                          );
                                          _viewSchemeDetails(
                                            schemeId,
                                            index,
                                            isDark,
                                          );
                                        } else if (url != null &&
                                            url.startsWith('back://')) {
                                          final msgIndex = int.parse(
                                            url.replaceFirst('back://', ''),
                                          );
                                          setState(() {
                                            if (_messages[msgIndex].containsKey(
                                              'original_text',
                                            )) {
                                              _messages[msgIndex]['text'] =
                                                  _messages[msgIndex]['original_text'];
                                            }
                                          });
                                        } else if (url != null) {
                                          launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      style: {
                                        "body": Style(
                                          fontSize: FontSize(14.0),
                                          lineHeight: const LineHeight(1.55),
                                          color:
                                              isDark
                                                  ? const Color(0xFFF3F4F6)
                                                  : const Color(0xFF1F2937),
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                        "strong": Style(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                        ),
                                        "h3": Style(
                                          fontSize: FontSize(15.5),
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF064E3B),
                                          margin: Margins.only(
                                            top: 6,
                                            bottom: 8,
                                          ),
                                        ),
                                        "h4": Style(
                                          fontSize: FontSize(14.0),
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF064E3B),
                                          margin: Margins.only(
                                            top: 10,
                                            bottom: 4,
                                          ),
                                        ),
                                        "hr": Style(
                                          border: Border(
                                            bottom: BorderSide(
                                              color:
                                                  isDark
                                                      ? const Color(0xFF374151)
                                                      : const Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                          ),
                                          margin: Margins.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        // Fallback classes for .scheme-btn and .back-btn
                                        ".scheme-btn": Style(
                                          backgroundColor:
                                              isDark
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF064E3B),
                                          color:
                                              isDark
                                                  ? const Color(0xFF064E3B)
                                                  : Colors.white,
                                          padding: HtmlPaddings.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: FontSize(13.0),
                                          display: Display.inlineBlock,
                                          textAlign: TextAlign.center,
                                          margin: Margins.only(
                                            top: 8,
                                            bottom: 8,
                                            right: 6,
                                          ),
                                        ),
                                        "a.scheme-btn": Style(
                                          backgroundColor:
                                              isDark
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF064E3B),
                                          color:
                                              isDark
                                                  ? const Color(0xFF064E3B)
                                                  : Colors.white,
                                          padding: HtmlPaddings.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: FontSize(13.0),
                                          display: Display.inlineBlock,
                                          textAlign: TextAlign.center,
                                          margin: Margins.only(
                                            top: 8,
                                            bottom: 8,
                                            right: 6,
                                          ),
                                        ),
                                        ".back-btn": Style(
                                          backgroundColor:
                                              isDark
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFD97706),
                                          color:
                                              isDark
                                                  ? const Color(0xFF78350F)
                                                  : Colors.white,
                                          padding: HtmlPaddings.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: FontSize(13.0),
                                          display: Display.inlineBlock,
                                          textAlign: TextAlign.center,
                                          margin: Margins.only(
                                            top: 4,
                                            bottom: 12,
                                          ),
                                        ),
                                        "a.back-btn": Style(
                                          backgroundColor:
                                              isDark
                                                  ? const Color(0xFFF59E0B)
                                                  : const Color(0xFFD97706),
                                          color:
                                              isDark
                                                  ? const Color(0xFF78350F)
                                                  : Colors.white,
                                          padding: HtmlPaddings.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: FontSize(13.0),
                                          display: Display.inlineBlock,
                                          textAlign: TextAlign.center,
                                          margin: Margins.only(
                                            top: 4,
                                            bottom: 12,
                                          ),
                                        ),
                                        "a": Style(
                                          color:
                                              isDark
                                                  ? const Color(0xFF34D399)
                                                  : const Color(0xFF064E3B),
                                          textDecoration: TextDecoration.none,
                                        ),
                                      },
                                    ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // INPUT BAR (Maintaining earlier design)
  // ──────────────────────────────────────────────
  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        widget.t['searchPlaceholder'] ??
                        'Type your query here... (English or Tamil)',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Clear button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: GestureDetector(
                    onTap: () {
                      _controller.clear();
                      if (_isDictating) {
                        _dictationAccumulatedText = '';
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.clear,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Mic button
            GestureDetector(
              onTap: _toggleDictation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      _isDictating
                          ? Colors.red.shade100
                          : const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isDictating ? Icons.stop : Icons.mic,
                  color: _isDictating ? Colors.red : const Color(0xFF7F1212),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send button
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isSending ? Colors.grey : const Color(0xFF7F1212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // VOICE CHAT
  // ──────────────────────────────────────────────
  Future<void> _startVoiceChat() async {
    if (!await _ensureSpeech()) {
      _snack(
        widget.t['speechUnavailable'] ?? 'Speech recognition is not available',
      );
      return;
    }

    setState(() {
      _showVoicePanel = true;
      _voiceState = 'connecting';
      _audioQueue.clear();
      _isPlayingAudio = false;
      _audioPlayer.stop();
    });

    _startNativeListening();
  }

  void _startNativeListening() async {
    if (!_showVoicePanel ||
        _isPlayingAudio ||
        _voiceState == 'speaking' ||
        _voiceState == 'thinking') {
      return;
    }

    if (mounted) setState(() => _voiceState = 'listening');

    setState(() {
      if (_messages.isNotEmpty &&
          _messages.last['sender'] == 'user' &&
          _messages.last['is_partial'] == true) {
        _messages.removeLast();
      }
      _messages.add({
        'sender': 'user',
        'text':
            widget.locale.languageCode == 'ta'
                ? 'கேட்கிறது...'
                : 'Listening...',
        'is_voice': true,
        'is_partial': true,
      });
    });
    _scrollToBottom();

    final localeId = widget.locale.languageCode == 'ta' ? 'ta_IN' : 'en_IN';

    await _speechToText.listen(
      onResult: (result) {
        if (mounted && _showVoicePanel && _voiceState == 'listening') {
          setState(() {
            if (_messages.isNotEmpty &&
                _messages.last['sender'] == 'user' &&
                _messages.last['is_partial'] == true) {
              _messages.last['text'] = result.recognizedWords;
            }
          });
          _scrollToBottom();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _processSpeechResult() async {
    if (!_showVoicePanel) return;

    String finalWords = '';
    if (_messages.isNotEmpty &&
        _messages.last['sender'] == 'user' &&
        _messages.last['is_partial'] == true) {
      finalWords = _messages.last['text'];
      _messages.last['is_partial'] = false;
    }

    if (finalWords.isEmpty ||
        finalWords == 'Listening...' ||
        finalWords == 'கேட்கிறது...') {
      if (_messages.isNotEmpty &&
          _messages.last['sender'] == 'user' &&
          (_messages.last['text'] == 'Listening...' ||
              _messages.last['text'] == 'கேட்கிறது...')) {
        _messages.removeLast();
      }
      _startNativeListening();
      return;
    }

    if (mounted) setState(() => _voiceState = 'thinking');

    try {
      final langCode = widget.locale.languageCode;
      final data = await _geminiService.generateVoiceResponseFromText(
        finalWords,
        langCode,
        userProfile: widget.userProfile?.toMap(),
      );

      if (mounted && _showVoicePanel) {
        setState(() {
          final botText =
              data['response'] ?? data['answer'] ?? data['text'] ?? '';
          if (botText.isNotEmpty) {
            _messages.add({'sender': 'bot', 'text': botText});
            _activeSpokenMessageIndex = _messages.length - 1;
            _activeSpokenWordIndex = -1;
          }
        });
        _scrollToBottom();

        final audioBase64 = data['audio'];
        if (audioBase64 != null && audioBase64.toString().isNotEmpty) {
          _audioQueue.add(base64Decode(audioBase64.toString()));
          _playNextAudio();
        } else {
          _startNativeListening();
        }
      }
    } catch (_) {
      if (mounted && _showVoicePanel) {
        _snack(
          widget.t['voiceError'] ??
              'Could not get a response. Please try again.',
        );
        _startNativeListening();
      }
    }
  }

  void _stopVoiceChat() async {
    await _speechToText.stop();
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    _voiceState = 'idle';
    _showVoicePanel = false;
    _audioQueue.clear();
    _isPlayingAudio = false;
    _highlightTimer?.cancel();
    _activeSpokenMessageIndex = null;
    _activeSpokenWordIndex = null;
    await _audioPlayer.stop();
    if (mounted) setState(() {});
  }

  void _toggleDictation() async {
    if (_showVoicePanel) return;

    if (_isDictating) {
      _inputMicUserStopped = true;
      _speechToText.stop();
      setState(() => _isDictating = false);
      return;
    }

    if (!await _ensureSpeech()) {
      _snack(
        widget.t['speechUnavailable'] ?? 'Speech recognition is not available',
      );
      return;
    }

    _inputMicUserStopped = false;
    setState(() => _isDictating = true);

    _dictationAccumulatedText = _controller.text;
    if (_dictationAccumulatedText.isNotEmpty &&
        !_dictationAccumulatedText.endsWith(' ')) {
      _dictationAccumulatedText += ' ';
    }

    _startDictationSession();
  }

  void _startDictationSession() async {
    if (_inputMicUserStopped || !_isDictating) return;

    final localeId = widget.locale.languageCode == 'ta' ? 'ta_IN' : 'en_IN';

    await _speechToText.listen(
      onResult: (result) {
        if (mounted && _isDictating && !_inputMicUserStopped) {
          setState(() {
            _controller.text =
                _dictationAccumulatedText + result.recognizedWords;
          });
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _interruptVoiceChat() {
    if (_isPlayingAudio) {
      _audioQueue.clear();
      _isPlayingAudio = false;
      _audioPlayer.stop();
      if (mounted) setState(() => _voiceState = 'listening');
      _startNativeListening();
    }
  }

  void _playNextAudio() async {
    if (_audioQueue.isEmpty) {
      if (_showVoicePanel && _voiceState == 'speaking') {
        if (mounted) setState(() => _voiceState = 'listening');
        _startNativeListening();
      }
      return;
    }

    if (_isPlayingAudio) return;

    _isPlayingAudio = true;
    if (mounted) setState(() => _voiceState = 'speaking');

    final audioBytes = _audioQueue.removeAt(0);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_audio_chunk.mp3');
      await file.writeAsBytes(audioBytes);
      await _audioPlayer.play(DeviceFileSource(file.path));

      if (_activeSpokenMessageIndex != null &&
          _activeSpokenMessageIndex! < _messages.length) {
        final text = _messages[_activeSpokenMessageIndex!]['text'] ?? '';
        final wordsCount = _plain(text.toString()).split(RegExp(r'\s+')).length;
        if (wordsCount > 0) {
          _audioPlayer.getDuration().then((duration) {
            final msPerWord =
                duration != null && duration.inMilliseconds > 0
                    ? duration.inMilliseconds ~/ wordsCount
                    : 300;
            _activeSpokenWordIndex = 0;
            _highlightTimer?.cancel();
            _highlightTimer = Timer.periodic(
              Duration(milliseconds: msPerWord),
              (timer) {
                if (_activeSpokenWordIndex != null &&
                    _activeSpokenWordIndex! < wordsCount - 1) {
                  _activeSpokenWordIndex = _activeSpokenWordIndex! + 1;
                } else {
                  timer.cancel();
                }
              },
            );
          });
        }
      }
    } catch (_) {
      _isPlayingAudio = false;
      _playNextAudio();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      drawer: _buildDrawer(isDark),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (ctx) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDark ? Colors.white : const Color(0xFF7F1212),
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              widget.t['appName'] ?? 'ChatMe',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF7F1212),
              ),
            ),
          ],
        ),
        actions: [
          // Voice Chat button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (_showVoicePanel) {
                  _stopVoiceChat();
                } else {
                  _startVoiceChat();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      _showVoicePanel
                          ? Colors.red.shade50
                          : const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _showVoicePanel ? Icons.close : Icons.mic,
                      size: 16,
                      color:
                          _showVoicePanel
                              ? Colors.red
                              : const Color(0xFF7F1212),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _showVoicePanel
                          ? (widget.t['closeVoice'] ?? 'Close Voice')
                          : (widget.t['voiceChat'] ?? 'Voice Chat'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            _showVoicePanel
                                ? Colors.red
                                : const Color(0xFF7F1212),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    hasMessages
                        ? _buildMessages(isDark)
                        : _buildWelcomeState(isDark),
              ),
              _buildInputBar(isDark),
            ],
          ),
          if (_showVoicePanel)
            Positioned(
              bottom: 90,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: _FloatingAvatarWidget(
                  isDark: isDark,
                  t: widget.t,
                  state: _voiceState,
                  onInterrupt: _interruptVoiceChat,
                  onClose: _stopVoiceChat,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FLOATING AVATAR WIDGET (Voice Video Interaction)
// ─────────────────────────────────────────────
class _FloatingAvatarWidget extends StatefulWidget {
  final bool isDark;
  final Map<String, String> t;
  final String state; // connecting, listening, thinking, speaking, idle
  final VoidCallback onInterrupt;
  final VoidCallback onClose;

  const _FloatingAvatarWidget({
    required this.isDark,
    required this.t,
    required this.state,
    required this.onInterrupt,
    required this.onClose,
  });

  @override
  State<_FloatingAvatarWidget> createState() => _FloatingAvatarWidgetState();
}

class _FloatingAvatarWidgetState extends State<_FloatingAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  VideoPlayerController? _idleController;
  VideoPlayerController? _activeController;
  VideoPlayerController? _talkingController;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseCtrl);
    _syncPulse();
    _initVideos();
  }

  void _syncPulse() {
    final pulse = widget.state == 'listening' || widget.state == 'connecting';
    if (pulse && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!pulse && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  Future<void> _initVideos() async {
    final options = VideoPlayerOptions(mixWithOthers: true);
    _idleController = VideoPlayerController.asset(
      'assets/videos/Greeting_Sakti.mp4',
      videoPlayerOptions: options,
    );

    try {
      await _idleController!.initialize();
    } catch (_) {
      return; // avatar videos unavailable - voice chat still works
    }
    if (!mounted) return;

    _idleController!.setVolume(0.0);
    _activeController!.setVolume(0.0);
    _talkingController!.setVolume(0.0);

    _idleController!.setLooping(true);
    _activeController!.setLooping(true);
    _talkingController!.setLooping(true);
    _idleController!.play();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _idleController?.dispose();
    _activeController?.dispose();
    _talkingController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncPulse();
      _updateVideoPlayback();
    }
  }

  Future<void> _updateVideoPlayback() async {
    VideoPlayerController? currentVideo;
    if (widget.state == 'speaking') {
      _talkingController ??= VideoPlayerController.asset(
        'assets/videos/Talking_Sakti.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      if (!(_talkingController?.value.isInitialized ?? false)) {
        try {
          await _talkingController!.initialize();
          _talkingController!.setVolume(0);
          _talkingController!.setLooping(true);
          if (mounted) setState(() {});
        } catch (_) {}
      }
      currentVideo = _talkingController;
    } else if (widget.state == 'thinking' || widget.state == 'connecting') {
      _activeController ??= VideoPlayerController.asset(
        'assets/videos/Thinking_Sakti.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      if (!(_activeController?.value.isInitialized ?? false)) {
        try {
          await _activeController!.initialize();
          _activeController!.setVolume(0);
          _activeController!.setLooping(true);
          if (mounted) setState(() {});
        } catch (_) {}
      }
      currentVideo = _activeController;
    } else {
      currentVideo = _idleController;
    }

    if (currentVideo != _idleController) _idleController?.pause();
    if (currentVideo != _activeController) _activeController?.pause();
    if (currentVideo != _talkingController) _talkingController?.pause();
    if (currentVideo != null) {
      currentVideo.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPulse =
        widget.state == 'listening' || widget.state == 'connecting';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onInterrupt,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (showPulse)
                    ...List.generate(
                      2,
                      (i) => Transform.scale(
                        scale: _pulseAnim.value + i * 0.1,
                        child: Container(
                          width: 100,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: const Color(
                              0xFFFFD700,
                            ).withAlpha(40 - i * 15),
                          ),
                        ),
                      ),
                    ),
                  child!,
                  // Close button
                  Positioned(
                    top: -5,
                    right: -5,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Status indicator
                  if (widget.state != 'speaking')
                    Positioned(
                      bottom: -5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape:
                              widget.state == 'thinking' ||
                                      widget.state == 'connecting'
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                          borderRadius:
                              widget.state == 'thinking' ||
                                      widget.state == 'connecting'
                                  ? BorderRadius.circular(12)
                                  : null,
                          color:
                              widget.isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                          border: Border.all(
                            color:
                                widget.state == 'thinking' ||
                                        widget.state == 'connecting'
                                    ? Colors.blue
                                    : const Color(0xFFFFD700),
                            width: 2,
                          ),
                        ),
                        child:
                            widget.state == 'thinking' ||
                                    widget.state == 'connecting'
                                ? const Text(
                                  '...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                                : const Icon(
                                  Icons.mic,
                                  size: 12,
                                  color: Color(0xFFFFD700),
                                ),
                      ),
                    ),
                ],
              );
            },
            child: Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color:
                      widget.state == 'thinking' || widget.state == 'connecting'
                          ? Colors.blue
                          : (showPulse
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF7F1212)),
                  width: 3,
                ),
                color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child:
                    (!(_idleController?.value.isInitialized ?? false) &&
                            widget.state != 'thinking' &&
                            widget.state != 'connecting' &&
                            widget.state != 'speaking')
                        ? const Center(child: CircularProgressIndicator())
                        : IndexedStack(
                          index:
                              widget.state == 'speaking'
                                  ? 2
                                  : (widget.state == 'thinking' ||
                                          widget.state == 'connecting'
                                      ? 1
                                      : 0),
                          children: [
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _idleController!.value.size.width,
                                  height: _idleController!.value.size.height,
                                  child: VideoPlayer(_idleController!),
                                ),
                              ),
                            ),
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _activeController!.value.size.width,
                                  height: _activeController!.value.size.height,
                                  child: VideoPlayer(_activeController!),
                                ),
                              ),
                            ),
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _talkingController!.value.size.width,
                                  height: _talkingController!.value.size.height,
                                  child: VideoPlayer(_talkingController!),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.black54 : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.state == 'speaking'
                ? (widget.t['talking'] ?? 'Talking...')
                : (widget.state == 'thinking' || widget.state == 'connecting'
                    ? (widget.t['thinking'] ?? 'Thinking...')
                    : (widget.state == 'idle'
                        ? (widget.t['greeting'] ?? 'Greetings...')
                        : (widget.t['voiceListening'] ?? 'Listening...'))),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : const Color(0xFF7F1212),
            ),
          ),
        ),
      ],
    );
  }
}
