import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 설정 파일 로더
class ConfigLoader {
  static Map<String, dynamic>? _cachedConfig;

  /// dev.json 파일에서 설정 동기 로드 (네이티브 환경 전용)
  static Map<String, dynamic> loadConfigSync() {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    if (kIsWeb) {
      return {};
    }

    try {
      final paths = [
        '.env/dev.json',  // .env 폴더 (우선순위 1)
        'dev.json',       // 프로젝트 루트 (우선순위 2)
      ];
      
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) {
          final jsonString = file.readAsStringSync();
          _cachedConfig = jsonDecode(jsonString) as Map<String, dynamic>;
          debugPrint('✅ dev.json 로드 성공: $path');
          return _cachedConfig!;
        }
      }
    } catch (e) {
      debugPrint('⚠️ dev.json 로드 실패: $e');
    }

    return {};
  }

  /// dev.json 파일에서 설정 로드
  static Future<Map<String, dynamic>> loadConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      String jsonString;
      
      // 웹 환경에서는 assets에서 읽기 시도
      if (kIsWeb) {
        // 웹 환경에서는 assets 폴더에서만 읽을 수 있음
        try {
          jsonString = await rootBundle.loadString('assets/dev.json');
          debugPrint('✅ dev.json 로드 성공 (웹): assets/dev.json');
        } catch (e) {
          debugPrint('⚠️ 웹 환경: assets/dev.json 로드 실패: $e');
          return {};
        }
      } else {
        // 네이티브 환경에서는 여러 경로에서 시도
        final paths = [
          '.env/dev.json',  // .env 폴더 (우선순위 1)
          'dev.json',       // 프로젝트 루트 (우선순위 2)
        ];
        
        String? loadedJson;
        for (final path in paths) {
          final file = File(path);
          if (await file.exists()) {
            loadedJson = await file.readAsString();
            debugPrint('✅ dev.json 로드 성공: $path');
            break;
          }
        }
        
        if (loadedJson != null) {
          jsonString = loadedJson;
        } else {
          // assets 폴더에서 시도
          try {
            jsonString = await rootBundle.loadString('assets/dev.json');
            debugPrint('✅ dev.json 로드 성공: assets/dev.json');
          } catch (e) {
            debugPrint('⚠️ 네이티브 환경: dev.json을 찾을 수 없습니다.');
            return {};
          }
        }
      }

      _cachedConfig = jsonDecode(jsonString) as Map<String, dynamic>;
      return _cachedConfig!;
    } catch (e) {
      debugPrint('⚠️ dev.json 로드 실패: $e');
      return {};
    }
  }

  /// 특정 키 값 가져오기
  static Future<String?> getValue(String key) async {
    final config = await loadConfig();
    return config[key]?.toString();
  }

  /// API 키 가져오기
  static Future<String?> getApiKey(String keyName) async {
    return await getValue(keyName);
  }
}

