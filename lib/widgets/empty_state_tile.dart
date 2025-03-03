// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class EmptyStateTile extends StatelessWidget {
  final VoidCallback onTap;

  const EmptyStateTile({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.add, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8.0),
              Text(
                'Start a new talk',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}