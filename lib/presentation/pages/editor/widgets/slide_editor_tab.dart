import 'package:flutter/material.dart';
import '../../../../data/models/project.dart';
import '../../../../data/models/slide.dart';
import 'slide_preview_panel.dart';

/// 슬라이드 편집 탭
class SlideEditorTab extends StatelessWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<SlideData> onSlideChanged;

  const SlideEditorTab({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SlidePreviewPanel(
      project: project,
      selectedSlideIndex: selectedSlideIndex,
      onSlideUpdated: onSlideChanged,
    );
  }
}
