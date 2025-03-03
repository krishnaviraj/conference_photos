// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class EmptyTalkView extends StatelessWidget {
  const EmptyTalkView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Replace with your custom illustration
          Icon(
            Icons.photo_camera_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Start by taking a photo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Everything for this talk will fill in here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface..withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }
}