import 'dart:math';

import '../../data/models/project.dart';
import '../../data/models/slide.dart';

/// 아바타 음성 미리듣기 생성 서비스 (스텁 구현)
///
/// 실제 음성 합성/아바타 렌더 API 연동 전까지는
/// 네트워크 호출 없이 지연을 주고 성공 여부만 반환한다.
class AvatarAudioService {
  const AvatarAudioService._();

  /// 슬라이드 대본을 기반으로 아바타 음성 미리듣기를 생성한다.
  ///
  /// [script]가 비어있으면 예외를 던진다.
  static Future<AvatarAudioPreviewResult> generatePreview({
    required LectureProject project,
    required SlideData slide,
    required String script,
  }) async {
    final trimmedScript = script.trim();
    if (trimmedScript.isEmpty) {
      throw ArgumentError('대본이 비어있어 음성을 생성할 수 없습니다.');
    }

    // 실제 API 연동 전까지는 1.2~2초 사이 지연 후 미리듣기 URL을 임시 반환
    final randomDelay = Duration(
      milliseconds: 1200 + Random().nextInt(800),
    );
    await Future.delayed(randomDelay);

    final fakePreviewUrl =
        'https://example.com/audio_previews/${slide.id}.mp3'; // 임시 URL

    return AvatarAudioPreviewResult(
      previewUrl: fakePreviewUrl,
      estimatedDuration:
          Duration(milliseconds: max(1500, trimmedScript.length * 40)),
    );
  }
}

class AvatarAudioPreviewResult {
  const AvatarAudioPreviewResult({
    required this.previewUrl,
    required this.estimatedDuration,
  });

  /// 임시 음성 미리듣기 URL (실제 구현 시 오디오 스트림 URL)
  final String previewUrl;

  /// 추정 재생 시간
  final Duration estimatedDuration;
}

