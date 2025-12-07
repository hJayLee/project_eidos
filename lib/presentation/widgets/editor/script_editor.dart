import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/script.dart';

/// 스크립트 에디터 위젯
class ScriptEditor extends StatefulWidget {
  final Script script;
  final Function(String) onScriptChanged;
  final VoidCallback onGenerateSlides;
  final bool isGenerating;

  const ScriptEditor({
    super.key,
    required this.script,
    required this.onScriptChanged,
    required this.onGenerateSlides,
    this.isGenerating = false,
  });

  @override
  State<ScriptEditor> createState() => _ScriptEditorState();
}

class _ScriptEditorState extends State<ScriptEditor> {
  late TextEditingController _controller;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.script.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _getScriptStats();

    return Column(
      children: [
        // 상단 툴바
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '스크립트 편집',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const Spacer(),
              
              // 통계 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.text_fields_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats['words']}단어',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats['readTime']}분',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 미리보기 토글
              IconButton(
                icon: Icon(_showPreview ? Icons.edit_outlined : Icons.preview_outlined),
                tooltip: _showPreview ? '편집 모드' : '미리보기 모드',
                onPressed: () {
                  setState(() {
                    _showPreview = !_showPreview;
                  });
                },
              ),
            ],
          ),
        ),

        // 메인 에디터 영역
        Expanded(
          child: _showPreview ? _buildPreview() : _buildEditor(),
        ),

        // 하단 액션 바
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // 도움말 텍스트
              Expanded(
                child: Text(
                  '팁: 챕터를 구분하려면 "## 챕터 제목" 형식을 사용하세요',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              
              // 챕터 자동 생성 버튼
              OutlinedButton.icon(
                onPressed: _controller.text.trim().isEmpty ? null : _generateChapters,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                label: const Text('챕터 자동 생성'),
              ),
              
              const SizedBox(width: 12),
              
              // AI 슬라이드 생성 버튼
              ElevatedButton.icon(
                onPressed: widget.isGenerating || _controller.text.trim().isEmpty
                    ? null
                    : widget.onGenerateSlides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: widget.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  widget.isGenerating ? '생성 중...' : 'AI 슬라이드 생성',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: '''강의 스크립트를 입력하세요...

예시:
## 소개
안녕하세요, 오늘은 플러터 개발에 대해 알아보겠습니다.

## 플러터란?
플러터는 구글에서 개발한 크로스 플랫폼 프레임워크입니다.

## 주요 특징
- 하나의 코드베이스로 iOS, Android 앱 개발
- 빠른 개발 속도와 핫 리로드 기능
- 네이티브 성능과 아름다운 UI''',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            height: 1.6,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) {
          widget.onScriptChanged(value);
          setState(() {}); // 통계 업데이트를 위해
        },
      ),
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);
    final content = _controller.text;
    
    if (content.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '스크립트가 없습니다',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '편집 모드에서 스크립트를 작성해주세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // 간단한 마크다운 스타일 렌더링
    final lines = content.split('\n');
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            if (line.startsWith('## ')) {
              return Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text(
                  line.substring(3),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            } else if (line.startsWith('# ')) {
              return Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: Text(
                  line.substring(2),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            } else if (line.startsWith('- ')) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line.substring(2),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (line.trim().isEmpty) {
              return const SizedBox(height: 12);
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
              );
            }
          }).toList(),
        ),
      ),
    );
  }

  Map<String, int> _getScriptStats() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      return {'words': 0, 'readTime': 0};
    }

    final words = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final readTime = (words / 150).ceil(); // 분당 150단어 기준

    return {'words': words, 'readTime': readTime};
  }

  void _generateChapters() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    // TODO: 실제 AI 기반 챕터 생성
    // 현재는 간단한 예시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('챕터 자동 생성'),
        content: const Text('AI가 스크립트를 분석하여 적절한 챕터로 구분해드릴게요. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 실제 챕터 생성 로직
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('챕터 자동 생성 기능은 준비중입니다'),
                ),
              );
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}








