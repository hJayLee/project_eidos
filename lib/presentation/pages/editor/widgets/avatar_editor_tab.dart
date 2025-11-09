import 'package:flutter/material.dart';
import '../../../../data/models/project.dart';
import 'avatar_selection_panel.dart';
import 'script_panel.dart';
import 'avatar_preview_panel.dart';

/// 아바타 편집 탭
class AvatarEditorTab extends StatelessWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<int> onSlideSelected;

  const AvatarEditorTab({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSlideSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 왼쪽 패널 - 아바타 설정
        SizedBox(
          width: 350,
          child: Column(
            children: [
              // 아바타 이미지 업로드
              Expanded(
                flex: 1,
                child: AvatarImageUploadPanel(
                  project: project,
                  selectedSlideIndex: selectedSlideIndex,
                  onImageUploaded: (imagePath) {
                    // TODO: 이미지 업로드 로직 구현
                  },
                ),
              ),
              const Divider(height: 1),
              // 대본 작성
              Expanded(
                flex: 1,
                child: ScriptPanel(
                  project: project,
                  selectedSlideIndex: selectedSlideIndex,
                  onScriptUpdated: (script) {
                    // TODO: 대본 업데이트 로직 구현
                  },
                ),
              ),
            ],
          ),
        ),
        // 중앙 패널 - 아바타 영상 미리보기
        Expanded(
          child: AvatarPreviewPanel(
            project: project,
            selectedSlideIndex: selectedSlideIndex,
            onVideoGenerated: () {
              // TODO: 영상 생성 로직 구현
            },
          ),
        ),
      ],
    );
  }
}
