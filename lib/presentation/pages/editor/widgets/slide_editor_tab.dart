import 'package:flutter/material.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart';
import 'chat_panel.dart';
import 'slide_preview_panel.dart';
import 'editor_context_panel.dart';

/// 슬라이드 편집 탭
class SlideEditorTab extends StatelessWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<int> onSlideSelected;
  final ValueChanged<SlideData> onSlideChanged;
  final Future<void> Function(List<SlideData> slides) onSlidesGenerated;

  const SlideEditorTab({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideSelected,
    required this.onSlideChanged,
    required this.onSlidesGenerated,
  });

  @override
  Widget build(BuildContext context) {
    final currentSlide = selectedSlideIndex < project.slides.length
        ? project.slides[selectedSlideIndex]
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 왼쪽 패널 - AI 어시스턴트 & 슬라이드 생성
        SizedBox(
          width: 320,
          child: SlideGenerationPanel(
            project: project,
            selectedSlideIndex: selectedSlideIndex,
            onSlidesGenerated: onSlidesGenerated,
          ),
        ),
        // 중앙 패널 - 슬라이드 미리보기
        Expanded(
          child: SlidePreviewPanel(
            project: project,
            selectedSlideIndex: selectedSlideIndex,
            onSlideUpdated: onSlideChanged,
          ),
        ),
        // 우측 패널 - 컨텍스트 편집
        SizedBox(
          width: 320,
          child: EditorContextPanel(
            project: project,
            selectedSlideIndex: selectedSlideIndex,
            slide: currentSlide,
            onSlideUpdated: onSlideChanged,
          ),
        ),
      ],
    );
  }
}
