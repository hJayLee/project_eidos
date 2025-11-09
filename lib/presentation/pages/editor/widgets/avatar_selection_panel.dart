import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 아바타 이미지 업로드 패널
class AvatarImageUploadPanel extends StatefulWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<String> onImageUploaded;

  const AvatarImageUploadPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onImageUploaded,
  });

  @override
  State<AvatarImageUploadPanel> createState() => _AvatarImageUploadPanelState();
}

class _AvatarImageUploadPanelState extends State<AvatarImageUploadPanel> {
  String? _uploadedImagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.upload,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '아바타 이미지 업로드',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 업로드 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 업로드 버튼
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _uploadImage,
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '이미지 업로드',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '클릭하여 아바타 이미지를 선택하세요',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 업로드된 이미지 미리보기
                  if (_uploadedImagePath != null) ...[
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _uploadedImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.surfaceColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppTheme.textSecondaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '이미지를 불러올 수 없습니다',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 이미지 제거 버튼
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('이미지 제거'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _uploadImage() {
    // TODO: 실제 이미지 업로드 로직 구현
    // 임시로 더미 이미지 URL 설정
    setState(() {
      _uploadedImagePath = 'https://via.placeholder.com/300x300/007bff/ffffff?text=Avatar+Image';
    });
    
    widget.onImageUploaded(_uploadedImagePath!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지가 업로드되었습니다')),
    );
  }

  void _removeImage() {
    setState(() {
      _uploadedImagePath = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지가 제거되었습니다')),
    );
  }
}
