import 'package:flutter/material.dart';

/// 커스텀 앱바 (Cursor AI 스타일)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading ?? (onBack != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          : null),
      
      title: Column(
        crossAxisAlignment: centerTitle 
            ? CrossAxisAlignment.center 
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
      
      actions: actions,
      
      // 하단 경계선
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle != null ? 80.0 : 60.0,
  );
}
