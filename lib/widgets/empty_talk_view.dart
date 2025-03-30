// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyTalkView extends StatelessWidget {
  const EmptyTalkView({Key? key}) : super(key: key);

   @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG illustration
          SvgPicture.asset(
            'assets/images/talk_empty.svg',
            width: 100,
            height: 100,
            semanticsLabel: 'Empty group illustration',
          ),
          const SizedBox(height: 24), // Same consistent spacing as home screen
          Text(
            'Start by taking a photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Everything for this group will fill in here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(179),
                ),
          ),
        ],
      ),
    );
  }
}