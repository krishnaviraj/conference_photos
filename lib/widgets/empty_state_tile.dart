// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyStateTile extends StatelessWidget {
  final VoidCallback onTap;

  const EmptyStateTile({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        side: BorderSide(color: AppTheme.accentColor.withAlpha(51), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.add,
                color: AppTheme.accentColor,
                size: 28,
              ),
              const SizedBox(width: 16.0),
              Text(
                'Start a new talk',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}