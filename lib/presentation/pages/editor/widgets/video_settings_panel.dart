import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 영상 설정 패널
class VideoSettingsPanel extends StatefulWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<Map<String, dynamic>> onSettingsUpdated;

  const VideoSettingsPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onSettingsUpdated,
  });

  @override
  State<VideoSettingsPanel> createState() => _VideoSettingsPanelState();
}

class _VideoSettingsPanelState extends State<VideoSettingsPanel> {
  String _selectedResolution = 'HD';
  String _selectedBackground = '없음';
  String _selectedVoice = '여성';

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
                  Icons.settings,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '영상 설정',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 설정 옵션들
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 해상도 설정
                  _buildSettingItem(
                    '해상도',
                    _selectedResolution,
                    ['SD', 'HD', 'FHD', '4K'],
                    (value) {
                      setState(() {
                        _selectedResolution = value;
                      });
                      _updateSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  // 배경 설정
                  _buildSettingItem(
                    '배경',
                    _selectedBackground,
                    ['없음', '단색', '그라데이션', '이미지'],
                    (value) {
                      setState(() {
                        _selectedBackground = value;
                      });
                      _updateSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  // 음성 설정
                  _buildSettingItem(
                    '음성',
                    _selectedVoice,
                    ['여성', '남성', '아동'],
                    (value) {
                      setState(() {
                        _selectedVoice = value;
                      });
                      _updateSettings();
                    },
                  ),
                  const Spacer(),
                  // 미리듣기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('미리듣기 기능은 준비 중입니다'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('미리듣기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }

  void _updateSettings() {
    widget.onSettingsUpdated({
      'resolution': _selectedResolution,
      'background': _selectedBackground,
      'voice': _selectedVoice,
    });
  }
}






