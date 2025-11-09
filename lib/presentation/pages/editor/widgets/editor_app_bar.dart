import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 에디터 상단 앱바
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final LectureProject project;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onBack;

  const EditorAppBar({
    super.key,
    required this.project,
    required this.onSave,
    required this.onExport,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
        color: AppTheme.textPrimaryColor,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            '${project.slides.length}개 슬라이드',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          color: AppTheme.textPrimaryColor,
          tooltip: '저장',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: onExport,
          color: AppTheme.textPrimaryColor,
          tooltip: '내보내기',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}





