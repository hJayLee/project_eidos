import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

/// 로그인 다이얼로그 결과
enum LoginPromptResult {
  cancel,
  login,
  temporary,
}

/// 로그인 필요 다이얼로그
class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          const Text(
            '로그인이 필요합니다',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: const Text(
        '프로젝트를 생성하려면 로그인이 필요합니다.\n\n'
        'Google 로그인을 시도할 수 있습니다.\n'
        '실패할 경우 임시 모드로 진행되며, 프로젝트는 로컬에 저장됩니다.\n\n'
        'Google 로그인 설정이 완료되면 클라우드에 저장됩니다.',
        style: TextStyle(
          color: AppTheme.textSecondaryColor,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(LoginPromptResult.cancel),
          child: const Text(
            '취소',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(LoginPromptResult.login),
          icon: const Icon(Icons.login),
          label: const Text('Google로 로그인 시도'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(LoginPromptResult.temporary),
          child: const Text('임시 모드로 계속'),
        ),
      ],
    );
  }

  /// 다이얼로그 표시
  static Future<LoginPromptResult> show(BuildContext context) async {
    final result = await showDialog<LoginPromptResult>(
      context: context,
      builder: (dialogContext) => const LoginRequiredDialog(),
    );

    return result ?? LoginPromptResult.cancel;
  }
}

