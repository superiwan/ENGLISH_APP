import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

class WordListItem extends StatelessWidget {
  const WordListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: dense,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppUi.space12,
          vertical: 2,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: dense ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
