import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';

class PhotoListItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(DismissDirection) onDismissed;
  final bool isSelected;
  final bool isReorderingMode;

  const PhotoListItem({
    Key? key,
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
    this.isSelected = false,
    this.isReorderingMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismissible-${photo.id}'),
      direction: isReorderingMode ? DismissDirection.none : DismissDirection.startToEnd,
      onDismissed: onDismissed,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 77) 
            : null,
        child: InkWell(
          onTap: isReorderingMode ? null : onTap,
          onLongPress: onLongPress,
          child: Row(
            children: [
              if (isReorderingMode)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 179),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.annotation,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: FileImage(File(photo.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}