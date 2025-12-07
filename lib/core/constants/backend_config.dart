import 'package:http/http.dart' as http;

/// Backend 서비스 URL 관리
class BackendConfig {
  // VisionStory 서비스 (아바타 생성)
  static const String visionStoryUrl = String.fromEnvironment(
    'VISIONSTORY_BACKEND_URL',
    defaultValue: 'https://visionstory-backend-5mhpr2kjqa-du.a.run.app',
  );

  // Slide Generator 서비스 (슬라이드 생성) - 예정
  static const String slideGeneratorUrl = String.fromEnvironment(
    'SLIDE_GENERATOR_URL',
    defaultValue: 'http://localhost:5002',
  );

  // Video Processor 서비스 (비디오 처리) - 예정
  static const String videoProcessorUrl = String.fromEnvironment(
    'VIDEO_PROCESSOR_URL',
    defaultValue: 'http://localhost:5003',
  );

  // 현재 환경 확인
  static bool get isProduction => 
      visionStoryUrl.contains('run.app');

  static bool get isDevelopment => !isProduction;

  // 헬스 체크
  static Future<Map<String, bool>> checkAllServices() async {
    return {
      'visionstory': await _checkService(visionStoryUrl),
      'slideGenerator': await _checkService(slideGeneratorUrl),
      'videoProcessor': await _checkService(videoProcessorUrl),
    };
  }

  static Future<bool> _checkService(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

