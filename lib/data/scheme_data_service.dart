// lib/data/scheme_data_service.dart
//
// SAKTI — Scheme Data Service
// Loads knowledge.csv (government schemes) and sakti_faq.csv (FAQs)
// from Flutter assets and provides:
//   • Full scheme list
//   • Smart keyword / category search with relevance scoring
//   • Webapp-compatible HTML multi-summary & full scheme formatters
//   • FAQ lookup
// No internet required — fully offline after first app install.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class SchemeEntry {
  final String id;
  final String url;
  final String title;
  final String details;
  final String benefits;
  final String eligibility;
  final String applicationProcess;
  final String documentsRequired;
  final String summary;

  // Lower-cased copies are computed ONCE (not on every search).
  final String titleLc;
  final String summaryLc;
  final String benefitsLc;
  final String eligibilityLc;

  SchemeEntry({
    required this.id,
    required this.url,
    required this.title,
    required this.details,
    required this.benefits,
    required this.eligibility,
    required this.applicationProcess,
    required this.documentsRequired,
    required this.summary,
  })  : titleLc = title.toLowerCase(),
        summaryLc = summary.toLowerCase(),
        benefitsLc = benefits.toLowerCase(),
        eligibilityLc = eligibility.toLowerCase();

  /// All searchable text combined for quick keyword matching
  String get searchBlob =>
      '$titleLc $summaryLc $benefitsLc $eligibilityLc ${details.toLowerCase()}';

  bool matchesQuery(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return searchBlob.contains(q);
  }
}

class FaqEntry {
  final String question;
  final String answer;

  const FaqEntry({required this.question, required this.answer});
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

/// Runs in a background isolate.
List<List<String>> _parseCsv(String raw) {
  final rows = const CsvToListConverter(shouldParseNumbers: false).convert(raw);
  return rows
      .map((r) => r.map((c) => c.toString()).toList(growable: false))
      .toList(growable: false);
}

class SchemeDataService {
  static final SchemeDataService _instance = SchemeDataService._internal();
  factory SchemeDataService() => _instance;
  SchemeDataService._internal();

  List<SchemeEntry> _schemes = [];
  Map<String, SchemeEntry> _byId = {};
  List<FaqEntry> _faqs = [];
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;
  List<SchemeEntry> get allSchemes => _schemes;
  List<FaqEntry> get allFaqs => _faqs;

  /// Completes when the CSV data is ready. Safe to call many times.
  Future<void> get ready => load();

  /// Loads data once. CSV parsing runs in a background isolate so the UI
  /// thread never freezes (the old version parsed 570 KB on the main thread
  /// BEFORE runApp(), which caused the long white/black startup screen).
  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _doLoad();
  }

  Future<void> _doLoad() async {
    try {
      final raws = await Future.wait([
        rootBundle.loadString('assets/data/knowledge.csv'),
        rootBundle.loadString('assets/data/sakti_faq.csv'),
      ]);
      final schemeRows = await compute(_parseCsv, raws[0]);
      final faqRows = await compute(_parseCsv, raws[1]);

      _schemes = schemeRows.skip(1).where((r) => r.length >= 9).map((r) {
        return SchemeEntry(
          id: r[0].trim(),
          url: r[1].trim(),
          title: r[2].trim(),
          details: r[3].trim(),
          benefits: r[4].trim(),
          eligibility: r[5].trim(),
          applicationProcess: r[6].trim(),
          documentsRequired: r[7].trim(),
          summary: r[8].trim(),
        );
      }).toList();
      _byId = {for (final s in _schemes) s.id: s};

      _faqs = faqRows
          .where((r) => r.length >= 2)
          .map((r) => FaqEntry(question: r[0].trim(), answer: r[1].trim()))
          .toList();
      _loaded = true;
    } catch (e) {
      _loading = null; // allow retry
      debugPrint('SchemeDataService load failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // SEARCH API WITH RELEVANCE SCORING
  // ─────────────────────────────────────────────

  /// Keyword search with tokenization, synonym expansion, and relevance ranking.
  /// Returns top [limit] matching schemes (default 5).
  List<SchemeEntry> search(String query, {int limit = 5}) {
    if (query.trim().isEmpty) return _schemes.take(limit).toList();

    final cleanQuery = query.toLowerCase().trim();

    // Stop words to discard
    const stopWords = {
      'the', 'and', 'for', 'are', 'what', 'can', 'you', 'give', 'tell', 'about',
      'scheme', 'schemes', 'tamil', 'nadu', 'tn', 'available', 'show', 'list',
      'find', 'get', 'need', 'want', 'please', 'with', 'from', 'have', 'there',
      'any', 'some', 'all', 'how', 'which', 'who', 'i', 'me', 'my', 'is', 'in',
      'to', 'of', 'a', 'an'
    };

    // Category expansions
    const categoryExpansions = {
      'student': [
        'student', 'students', 'scholarship', 'education', 'college', 'school',
        'degree', 'study', 'postgraduate', 'graduate', 'undergraduate', 'plus one',
        'hostel', 'pudhumai'
      ],
      'scholarship': [
        'scholarship', 'student', 'students', 'education', 'fellowship', 'stipend',
        'tuition', 'fee', 'merit', 'award'
      ],
      'education': [
        'education', 'scholarship', 'student', 'school', 'college', 'university',
        'books', 'degree', 'study', 'free education'
      ],
      'postgraduate': [
        'postgraduate', 'post graduate', 'pg', 'master', 'degree', 'scholarship',
        'higher education', 'ph.d', 'research'
      ],
      'college': [
        'college', 'university', 'degree', 'higher education', 'scholarship',
        'student', 'naan mudhalvan'
      ],
      'women': [
        'women', 'woman', 'girl', 'mother', 'widow', 'magalir', 'female',
        'hostel', 'urimai', 'pudhumai'
      ],
      'girl': [
        'girl', 'girl child', 'women', 'female', 'education', 'pudhumai'
      ],
      'farmer': [
        'farmer', 'farmers', 'agriculture', 'farming', 'crop', 'pulse', 'seed',
        'irrigation', 'soil', 'uzhavan'
      ],
      'agriculture': [
        'agriculture', 'farmer', 'farming', 'crop', 'cultivation', 'horticulture',
        'seeds', 'irrigation'
      ],
      'health': [
        'health', 'medical', 'hospital', 'treatment', 'insurance', 'medicine',
        'disease', 'cmchis', 'comprehensive'
      ],
      'disability': [
        'disability', 'differently abled', 'disabled', 'blind', 'deaf',
        'handicapped', 'retarded', 'muscular dystrophy'
      ],
      'differently abled': [
        'differently abled', 'disability', 'disabled', 'handicapped', 'special education'
      ],
      'pension': [
        'pension', 'indigent', 'destitute', 'allowance', 'senior citizen', 'aged',
        'elderly', 'welfare'
      ],
      'housing': [
        'housing', 'house', 'shelter', 'home', 'hostel'
      ],
      'employment': [
        'employment', 'job', 'skill', 'training', 'entrepreneur', 'self help',
        'loan', 'subsidy'
      ],
      'business': [
        'business', 'entrepreneur', 'loan', 'micro credit', 'credit', 'vendor'
      ],
      // Tamil expansions
      'மாணவர்': [
        'student', 'scholarship', 'education', 'கல்வி', 'மாணவர்', 'மாணவர்கள்', 'பள்ளி', 'கல்லூரி'
      ],
      'கல்வி': [
        'education', 'scholarship', 'student', 'கல்வி', 'பள்ளி', 'கல்லூரி', 'உதவித்தொகை'
      ],
      'உதவித்தொகை': [
        'scholarship', 'fellowship', 'stipend', 'உதவித்தொகை'
      ],
      'விவசாயி': [
        'farmer', 'agriculture', 'விவசாயி', 'விவசாயிகள்', 'வேளாண்', 'பயிர்'
      ],
      'மகளிர்': [
        'women', 'girl', 'மகளிர்', 'பெண்கள்', 'பெண்'
      ],
      'மருத்துவம்': [
        'health', 'medical', 'மருத்துவம்', 'சுகாதாரம்', 'காப்பீடு'
      ],
    };

    // Extract word tokens
    final rawTokens = cleanQuery
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0B80-\u0BFF\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !stopWords.contains(t))
        .toList();

    final expandedTokens = <String>{...rawTokens};
    for (final t in rawTokens) {
      for (final entry in categoryExpansions.entries) {
        if (t.length >= 3 &&
            (t.contains(entry.key) || entry.key.contains(t))) {
          expandedTokens.addAll(entry.value);
        }
      }
    }

    final scored = <MapEntry<SchemeEntry, int>>[];
    final tokens = expandedTokens.where((t) => t.length >= 2).toList();
    for (final s in _schemes) {
      int score = 0;
      for (final token in tokens) {
        if (s.titleLc.contains(token)) score += 6;
        if (s.summaryLc.contains(token)) score += 3;
        if (s.benefitsLc.contains(token)) score += 2;
        if (s.eligibilityLc.contains(token)) score += 2;
      }
      if (score > 0) scored.add(MapEntry(s, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  /// Search by predefined category keywords (mirrors webapp chips)
  List<SchemeEntry> searchByCategory(String category, {int limit = 5}) =>
      search(category, limit: limit);

  /// Look up a scheme by its ID (O(1))
  SchemeEntry? findById(String id) => _byId[id.trim()];

  /// Find the best FAQ answer for a query (word-overlap scoring).
  /// The old version matched ANY query containing the word "what".
  FaqEntry? matchFaq(String query) {
    final qWords = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+'))
        .where((w) => w.length > 2)
        .toSet();
    if (qWords.isEmpty) return null;
    FaqEntry? best;
    var bestScore = 0;
    for (final f in _faqs) {
      final fw = f.question
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+'))
          .where((w) => w.length > 2)
          .toSet();
      final score = qWords.intersection(fw).length;
      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  // ─────────────────────────────────────────────
  // WEBAPP-COMPLIANT HTML FORMATTERS
  // ─────────────────────────────────────────────

  /// Format multiple schemes into the exact webapp frontend summary format.
  /// Each scheme gets:
  ///   <strong>1. Title</strong><br>
  ///   Summary<br>
  ///   🎁 <strong>Key Benefits:</strong> Benefits preview<br>
  ///   <button class="scheme-btn" data-scheme-id="ID">📖 View Full Details</button><br><br>
  static String formatMultiSchemeHtml(List<SchemeEntry> schemes, String language) {
    final isTa = language == 'ta';
    final lines = <String>[];

    if (isTa) {
      lines.add(
          "<strong>உங்களுக்கான ${schemes.length} தொடர்புடைய திட்டங்களைக் கண்டறிந்துள்ளேன்:</strong><br>");
    } else {
      lines.add("<strong>I found ${schemes.length} relevant schemes for you:</strong><br>");
    }

    for (int i = 0; i < schemes.length; i++) {
      final s = schemes[i];
      final title = s.title.isNotEmpty ? s.title : "Scheme #${s.id}";
      final summary = s.summary.isNotEmpty ? s.summary : s.details;

      // Preview benefits: first 2 points
      String benefitsPreview = s.benefits;
      if (benefitsPreview.isNotEmpty) {
        final parts = benefitsPreview
            .split(RegExp(r'<br>|\n'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        if (parts.length > 2) {
          benefitsPreview = '${parts.take(2).join("<br>")}...';
        } else {
          benefitsPreview = parts.join("<br>");
        }
      }

      final btnText = isTa ? "📖 முழு விவரங்களைப் பார்க்க" : "📖 View Full Details";
      final benefitLabel = isTa ? "முதன்மை பலன்கள்:" : "Key Benefits:";

      final schemeLines = <String>[
        "<strong>${i + 1}. $title</strong>",
        summary,
        if (benefitsPreview.isNotEmpty) "🎁 <strong>$benefitLabel</strong> $benefitsPreview",
        '<button class="scheme-btn" data-scheme-id="${s.id}" data-language="$language">$btnText</button>',
      ];

      lines.add(schemeLines.join("<br>"));
      lines.add("");
    }

    if (isTa) {
      lines.add(
          "<strong>முழு விவரங்களைப் பார்க்க எந்தத் திட்டத்தையும் கிளிக் செய்யவும்.</strong>");
    } else {
      lines.add(
          "<strong>Click on 'View Full Details' for any scheme to see complete information.</strong>");
    }

    return lines.join("<br>");
  }

  /// Format a single scheme in full details format (matching webapp format_full_scheme)
  static String formatFullSchemeHtml(SchemeEntry s, String language) {
    final isTa = language == 'ta';
    final descHeading = isTa ? "<h4>📋 விளக்கம்</h4>" : "<h4>📋 Description</h4>";
    final benHeading = isTa ? "<h4>🎁 பலன்கள்</h4>" : "<h4>🎁 Benefits</h4>";
    final eligHeading =
        isTa ? "<h4>✅ தகுதி விதிமுறைகள்</h4>" : "<h4>✅ Eligibility Criteria</h4>";
    final appHeading =
        isTa ? "<h4>📝 விண்ணப்ப செயல்முறை</h4>" : "<h4>📝 Application Process</h4>";
    final docHeading =
        isTa ? "<h4>📄 தேவையான ஆவணங்கள்</h4>" : "<h4>📄 Required Documents</h4>";
    final infoHeading =
        isTa ? "<h4>🔗 மேலும் தகவலுக்கு</h4>" : "<h4>🔗 More Information</h4>";

    final buffer = StringBuffer();
    buffer.write("<h3>📌 ${s.title}</h3>");
    buffer.write("<hr>");

    if (s.details.isNotEmpty) {
      buffer.write("$descHeading<p>${s.details.replaceAll('\n', '<br>')}</p>");
    } else if (s.summary.isNotEmpty) {
      buffer.write("$descHeading<p>${s.summary.replaceAll('\n', '<br>')}</p>");
    }

    if (s.benefits.isNotEmpty) {
      buffer.write("$benHeading<p>${s.benefits.replaceAll('\n', '<br>')}</p>");
    }

    if (s.eligibility.isNotEmpty) {
      buffer.write("$eligHeading<p>${s.eligibility.replaceAll('\n', '<br>')}</p>");
    }

    if (s.applicationProcess.isNotEmpty) {
      buffer.write("$appHeading<p>${s.applicationProcess.replaceAll('\n', '<br>')}</p>");
    }

    if (s.documentsRequired.isNotEmpty) {
      buffer.write("$docHeading<p>${s.documentsRequired.replaceAll('\n', '<br>')}</p>");
    }

    if (s.url.isNotEmpty) {
      buffer.write(
          "$infoHeading<p><a href='${s.url}' target='_blank'>${s.url}</a></p>");
    }

    return buffer.toString();
  }

  /// Returns a set of all unique categories inferred from scheme titles
  List<String> get categories => const [
        'Education',
        'Agriculture',
        'Women Welfare',
        'Healthcare',
        'Housing',
        'Senior Citizens',
        'Disability',
        'Farmer',
        'Scholarship',
        'Pension',
        'Business',
        'Fisheries',
      ];
}
