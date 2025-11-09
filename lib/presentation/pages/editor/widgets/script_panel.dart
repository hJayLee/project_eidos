import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/project.dart';

/// 대본 작성 패널
class ScriptPanel extends StatefulWidget {
  final LectureProject project;
  final int selectedSlideIndex;
  final ValueChanged<String> onScriptUpdated;

  const ScriptPanel({
    super.key,
    required this.project,
    required this.selectedSlideIndex,
    required this.onScriptUpdated,
  });

  @override
  State<ScriptPanel> createState() => _ScriptPanelState();
}

class _ScriptPanelState extends State<ScriptPanel> {
  late TextEditingController _scriptController;

  @override
  void initState() {
    super.initState();
    _scriptController = TextEditingController();
    _loadScript();
  }

  @override
  void didUpdateWidget(ScriptPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSlideIndex != widget.selectedSlideIndex) {
      _loadScript();
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  void _loadScript() {
    final slide = widget.selectedSlideIndex < widget.project.slides.length
        ? widget.project.slides[widget.selectedSlideIndex]
        : null;
    
    _scriptController.text = slide?.speakerNotes ?? '';
  }

  void _saveScript() {
    widget.onScriptUpdated(_scriptController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('대본이 저장되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '대본 작성',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_scriptController.text.length}자',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 대본 입력
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scriptController,
                      decoration: InputDecoration(
                        hintText: '아바타가 말할 대본을 입력하세요...',
                        hintStyle: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveScript,
                      icon: const Icon(Icons.save),
                      label: const Text('대본 저장'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
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
}
