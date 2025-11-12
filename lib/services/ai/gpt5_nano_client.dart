import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'slide_generation_service.dart';

/// GPT-5 nano 기반 LLM 클라이언트 구현
class Gpt5NanoClient implements LlmClient {
  Gpt5NanoClient({
    http.Client? httpClient,
    String? apiKey,
    String? baseUrl,
    this.defaultModel = 'gpt-5-nano',
  }) : _httpClient = httpClient ?? http.Client(),
       _apiKey = apiKey ?? const String.fromEnvironment(_apiKeyEnvVar),
       _baseUrl = baseUrl ?? _defaultEndpoint {
    if (_apiKey.isEmpty) {
      throw StateError(
        'GPT-5 nano API 키가 설정되지 않았습니다. '
        '"flutter run --dart-define=$_apiKeyEnvVar=YOUR_KEY" 형태로 전달하세요.',
      );
    }
  }

  static const String _apiKeyEnvVar = 'GPT5_NANO_API_KEY';
  static const String _defaultEndpoint =
      'https://api.openai.com/v1/chat/completions';

  final http.Client _httpClient;
  final String _apiKey;
  final String _baseUrl;
  final String defaultModel;

  /// 시스템 프롬프트 기본값
  static const String _systemPrompt =
      '당신은 Project Eidos 슬라이드 디자이너를 돕는 전문 AI입니다. '
      '사용자 요청을 기반으로 JSON 응답을 반환하세요.';

  @override
  Future<String> generate({
    required String prompt,
    Map<String, dynamic>? options,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final requestedTemperature = (options?['temperature'] as num?)?.toDouble();
    final topP = (options?['top_p'] as num?)?.toDouble();
    final rawResponseFormat = options?['response_format'];
    final model = options?['model'] as String? ?? defaultModel;

    double? temperature;
    if (model == defaultModel) {
      // gpt-5-nano currently only supports the default temperature (1.0).
      if (requestedTemperature != null && requestedTemperature != 1.0) {
        debugPrint(
          '[Gpt5NanoClient] temperature ${requestedTemperature.toStringAsFixed(2)} '
          'not supported by $model. Using API default.',
        );
      }
    } else {
      temperature = requestedTemperature ?? 0.7;
    }

    final payload = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
    };

    if (temperature != null) {
      payload['temperature'] = temperature;
    }

    if (topP != null) {
      payload['top_p'] = topP;
    }

    final responseFormat = _normalizeResponseFormat(rawResponseFormat);
    if (responseFormat != null) {
      payload['response_format'] = responseFormat;
    }

    final body = jsonEncode(payload);

    debugPrint(
      '[Gpt5NanoClient] 요청 전송: model=$model, temperature=$temperature',
    );

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[Gpt5NanoClient] 호출 실패: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'GPT-5 nano 응답 실패: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'];

    if (choices is! List || choices.isEmpty) {
      throw Exception('GPT-5 nano 응답에 choices가 없습니다.');
    }

    final message = choices.first['message'];
    if (message is! Map<String, dynamic>) {
      throw Exception('GPT-5 nano 응답 메시지 형식이 잘못되었습니다.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('GPT-5 nano로부터 유효한 콘텐츠를 받지 못했습니다.');
    }

    return content.trim();
  }

  void dispose() {
    _httpClient.close();
  }

  Map<String, dynamic>? _normalizeResponseFormat(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return {
        'type': switch (normalized) {
          'json_object' => 'json_object',
          'json_schema' => 'json_schema',
          _ => 'text',
        }
      };
    }
    debugPrint('[Gpt5NanoClient] Unsupported response_format type: ${value.runtimeType}. Ignoring.');
    return null;
  }
}
