import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class GeminiService {
  final String _baseUrl = AppConfig.saktiApiUrl;
  String? _sessionId;

  // One shared client = keep-alive connections (no new TLS handshake per message).
  static final http.Client _client = http.Client();

  static void _log(Object? m) {
    if (kDebugMode) debugPrint(m.toString());
  }

  /// Wakes up a sleeping (free-tier) backend so the first chat message is fast.
  Future<void> warmUp() async {
    if (_baseUrl.isEmpty) return;
    try {
      await _client
          .get(Uri.parse(_baseUrl.replaceAll(RegExp(r'/$'), '')))
          .timeout(const Duration(seconds: 15));
    } catch (_) {/* ignore - only a wake-up ping */}
  }

  /// POST with a 30s timeout and ONE automatic retry for cold-start
  /// failures (timeout / network drop / 502-504).
  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    Future<http.Response> once() => _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));
    try {
      final r = await once();
      if (r.statusCode == 502 || r.statusCode == 503 || r.statusCode == 504) {
        return await once();
      }
      return r;
    } on TimeoutException {
      return await once();
    } on SocketException {
      return await once();
    } on http.ClientException {
      return await once();
    }
  }

  String? get sessionId => _sessionId;
  void resetSession() => _sessionId = null;

  Future<Map<String, dynamic>> generateResponse(
    String prompt, [
    String language = 'en',
    Map<String, dynamic>? userProfile,
  ]) async {
    final baseUrl = _baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$baseUrl/ask');

    try {
      final payloadMap = <String, dynamic>{
        'query': prompt,
        'action': 'search',
        'language': language,
      };
      if (_sessionId != null) {
        payloadMap['session_id'] = _sessionId;
      }
      if (userProfile != null && userProfile.isNotEmpty) {
        payloadMap['user_profile'] = userProfile;
      }

      _log('🔗 Sending request to $baseUrl/ask');
      final response = await _post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payloadMap),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'Backend request failed: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data.containsKey('session_id')) {
        _sessionId = data['session_id'] as String;
      }

      if (data.containsKey('error') && data['error'] != null) {
        throw Exception(data['error'] as String);
      }

      return data;
    } catch (e) {
      _log('Chat request error: $e');
      rethrow;
    }
  }

  Future<String> fetchSchemeDetails(String schemeId, String language) async {
    final baseUrl = _baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$baseUrl/ask');

    try {
      final payloadMap = <String, dynamic>{
        'action': 'view_details',
        'scheme_id': int.tryParse(schemeId) ?? schemeId,
        'language': language,
      };
      if (_sessionId != null) {
        payloadMap['session_id'] = _sessionId;
      }

      _log('🔗 Sending request to $baseUrl/ask for details of $schemeId');
      final response = await _post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payloadMap),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'Backend request failed: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      final text = data['response'] ??
          data['answer'] ??
          data['message'] ??
          data['text'];

      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString();
      } else if (data.containsKey('error')) {
        throw Exception(data['error'] as String);
      } else {
        return jsonEncode(data);
      }
    } catch (e) {
      _log('Scheme Details request error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateVoiceResponse(
    String base64Audio, {
    Map<String, dynamic>? userProfile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('CHATME_API_URL is not set in .env');
    }

    final baseUrl = _baseUrl.replaceAll(RegExp(r'/$'), '');
    
    // Step 1: Transcribe audio
    final sttUri = Uri.parse('$baseUrl/api/speech-to-text');
    final sttPayload = jsonEncode({
      'audio': base64Audio,
      'language': 'en'
    });
    
    _log('🔗 Sending voice transcription request to $baseUrl/api/speech-to-text');
    final sttResponse = await _post(
      sttUri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: sttPayload,
    ).timeout(const Duration(seconds: 60));
    
    if (sttResponse.statusCode != 200) {
      String errorMsg = 'Failed to transcribe voice';
      try {
        final errorData = jsonDecode(sttResponse.body);
        if (errorData['error'] != null) errorMsg = errorData['error'];
      } catch (_) {}
      throw Exception(errorMsg);
    }
    
    final sttData = jsonDecode(sttResponse.body) as Map<String, dynamic>;
    final transcribedQuery = sttData['transcript'] ?? sttData['text'] ?? sttData['transcription'] ?? sttData['query'] ?? sttData['result'];
    
    if (transcribedQuery == null || transcribedQuery.toString().trim().isEmpty) {
      throw Exception('Could not understand audio. Response was: ${sttResponse.body}');
    }
    
    // Step 2: Send to /ask
    final uri = Uri.parse('$baseUrl/ask');
    final payloadMap = <String, dynamic>{
      'query': transcribedQuery.toString(),
      'action': 'search',
      'source': 'voice',
      'language': 'en',
    };
    if (_sessionId != null) {
      payloadMap['session_id'] = _sessionId;
    }
    if (userProfile != null && userProfile.isNotEmpty) {
      payloadMap['user_profile'] = userProfile;
    }
    
    final payload = jsonEncode(payloadMap);
    _log('🔗 Sending transcribed query to $baseUrl/ask');

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: payload,
    ).timeout(const Duration(seconds: 60));

    _log('Voice response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      String errorMsg = 'Backend voice request failed';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        if (errorData.containsKey('error')) {
          errorMsg = errorData['error'];
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('session_id')) {
      _sessionId = data['session_id'] as String;
    }
    
    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }
    
    // Include transcribed query for the UI
    data['transcribed_query'] = transcribedQuery;
    
    return data;
  }

  Future<Map<String, dynamic>> generateVoiceResponseFromText(
    String text,
    String langCode, {
    Map<String, dynamic>? userProfile,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('CHATME_API_URL is not set in .env');
    }
    final baseUrl = _baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$baseUrl/ask');
    final payloadMap = <String, dynamic>{
      'query': text,
      'action': 'search',
      'source': 'voice',
      'language': langCode.startsWith('ta') ? 'ta' : 'en',
    };
    if (_sessionId != null) {
      payloadMap['session_id'] = _sessionId;
    }
    if (userProfile != null && userProfile.isNotEmpty) {
      payloadMap['user_profile'] = userProfile;
    }
    final payload = jsonEncode(payloadMap);
    _log('🔗 Sending transcribed query to $baseUrl/ask');
    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: payload,
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw Exception('Backend voice request failed: ${response.statusCode} - ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('session_id')) {
      _sessionId = data['session_id'] as String;
    }
    
    // Step 2: Call TTS endpoint to get audio for the response
    final botText = data['response'] ?? data['answer'] ?? data['text'] ?? '';
    if (botText.isNotEmpty) {
      _log('🔗 [TTS_REQUEST] Sending TTS request to $baseUrl/api/text-to-speech for text: ${botText.length > 30 ? botText.substring(0, 30) + '...' : botText}');
      try {
        final ttsUri = Uri.parse('$baseUrl/api/text-to-speech');
        final ttsPayload = jsonEncode({
          'text': botText,
          'language': langCode.startsWith('ta') ? 'ta' : 'en'
        });
        final ttsResponse = await _post(
          ttsUri,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: ttsPayload,
        ).timeout(const Duration(seconds: 60));
        
        _log('🔗 [TTS_RESPONSE] Status: ${ttsResponse.statusCode}');
        if (ttsResponse.statusCode == 200) {
          final ttsData = jsonDecode(ttsResponse.body) as Map<String, dynamic>;
          if (ttsData['success'] == true && ttsData.containsKey('audio')) {
            data['audio'] = ttsData['audio'];
            _log('✅ [TTS_DOWNLOAD_SUCCESS] Audio response received successfully (length: ${ttsData['audio'].toString().length})');
          } else {
            _log('⚠️ [TTS_ERROR] TTS API returned success=false or missing audio: ${ttsData['error']}');
          }
        } else {
          _log('⚠️ [TTS_ERROR] TTS API failed with status ${ttsResponse.statusCode}, body: ${ttsResponse.body}');
        }
      } catch (e) {
        _log('⚠️ [TTS_ERROR] Exception calling TTS API: $e');
      }
    }
    
    return data;
  }
}
