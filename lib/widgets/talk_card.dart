// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../services/date_format_service.dart';


class TalkCard extends StatelessWidget {
  final Talk talk;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const TalkCard({
    Key? key,
    required this.talk,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              ),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                talk.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Text(
                      DateFormatService.formatDate(talk.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const Spacer(),
                  Text(
                    '${talk.photoCount} photos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}