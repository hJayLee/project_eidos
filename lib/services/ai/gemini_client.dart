import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/config_loader.dart';
import 'slide_generation_service.dart';

/// Gemini 2.5 Pro 기반 LLM 클라이언트 구현
class GeminiClient implements LlmClient {
  GeminiClient({
    http.Client? httpClient,
    String? apiKey,
    String? baseUrl,
    this.defaultModel = 'gemini-2.5-pro',
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl,
        _initialApiKey = apiKey ?? '';

  static const String _apiKeyEnvVar = 'GEMINI_API_KEY';
  static const String _defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final http.Client _httpClient;
  final String _baseUrl;
  final String defaultModel;
  final String _initialApiKey;
  
  String? _cachedApiKey;
  bool _apiKeyLoaded = false;

  /// API 키 가져오기 (환경 변수 우선, dev.json 시도)
  Future<String> _getApiKey() async {
    // 이미 로드되었으면 반환
    if (_apiKeyLoaded && _cachedApiKey != null) {
      return _cachedApiKey!;
    }

    // 제공된 키가 있으면 사용
    if (_initialApiKey.isNotEmpty) {
      _cachedApiKey = _initialApiKey;
      _apiKeyLoaded = true;
      return _cachedApiKey!;
    }

    // 1. 환경 변수에서 시도
    final envKey = const String.fromEnvironment(_apiKeyEnvVar);
    if (envKey.isNotEmpty) {
      _cachedApiKey = envKey;
      _apiKeyLoaded = true;
      return _cachedApiKey!;
    }

    // 2. dev.json에서 시도 (웹/네이티브 모두)
    try {
      final key = await ConfigLoader.getApiKey(_apiKeyEnvVar);
      if (key != null && key.isNotEmpty) {
        _cachedApiKey = key;
        _apiKeyLoaded = true;
        debugPrint('✅ Gemini API 키를 dev.json에서 로드했습니다.');
        return _cachedApiKey!;
      }
    } catch (e) {
      debugPrint('⚠️ dev.json에서 API 키 로드 실패: $e');
    }

    throw StateError(
      'Gemini API 키가 설정되지 않았습니다. '
      'dev.json 파일(.env/dev.json 또는 assets/dev.json)에 GEMINI_API_KEY를 추가하거나 '
      '"flutter run --dart-define=$_apiKeyEnvVar=YOUR_KEY" 형태로 전달하세요.',
    );
  }

  /// 시스템 프롬프트 기본값
  static const String _systemPrompt =
      '당신은 Project Eidos 슬라이드 디자이너를 돕는 전문 AI입니다. '
      '사용자 요청을 기반으로 JSON 응답을 반환하세요.';

  @override
  Future<String> generate({
    required String prompt,
    Map<String, dynamic>? options,
  }) async {
    final apiKey = await _getApiKey();
    final model = options?['model'] as String? ?? defaultModel;
    final requestedTemperature = (options?['temperature'] as num?)?.toDouble();
    final temperature = requestedTemperature ?? 0.7;
    
    // Gemini API 엔드포인트 구성
    final uri = Uri.parse('$_baseUrl/models/$model:generateContent').replace(
      queryParameters: {'key': apiKey},
    );

    // response_format 처리
    final responseFormat = options?['response_format'];
    final shouldUseJson = responseFormat != null &&
        (responseFormat == 'json_object' ||
            (responseFormat is Map &&
                responseFormat['type']?.toString().toLowerCase() == 'json_object'));

    // Gemini API 요청 형식 구성
    final generationConfig = <String, dynamic>{
      'temperature': temperature,
    };

    if (shouldUseJson) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    // max_output_tokens 지원 (Gemini에서는 maxOutputTokens)
    if (options?['max_tokens'] != null) {
      generationConfig['maxOutputTokens'] = options!['max_tokens'];
    }

    final payload = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {
              'text': '$_systemPrompt\n\n$prompt',
            }
          ]
        }
      ],
      'generationConfig': generationConfig,
    };

    final body = jsonEncode(payload);

    debugPrint(
      '[GeminiClient] 요청 전송: model=$model, temperature=$temperature',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[GeminiClient] 호출 실패: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Gemini API 응답 실패: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Gemini API 응답 형식 파싱
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini API 응답에 candidates가 없습니다.');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'];
    if (content is! Map<String, dynamic>) {
      throw Exception('Gemini API 응답의 content 형식이 잘못되었습니다.');
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini API 응답에 parts가 없습니다.');
    }

    final part = parts.first as Map<String, dynamic>;
    final text = part['text'];
    
    if (text is! String || text.trim().isEmpty) {
      throw Exception('Gemini API로부터 유효한 콘텐츠를 받지 못했습니다.');
    }

    return text.trim();
  }

  void dispose() {
    _httpClient.close();
  }
}

