import 'package:flutter/material.dart';
import 'dart:io';
import '../models/photo.dart';
import '../models/photo_group.dart';

class PhotoGroupItem extends StatelessWidget {
  final PhotoGroup group;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(DismissDirection) onDismissed;
  final bool isSelected;
  final bool isReorderingMode;
  final VoidCallback? onEdit;
  final VoidCallback? onUngroup;

  const PhotoGroupItem({
    Key? key,
    required this.group,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
    this.isSelected = false,
    this.isReorderingMode = false,
    this.onEdit,
    this.onUngroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismissible-${group.id}'),
      direction: isReorderingMode ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: onDismissed,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) 
            : null,
        child: InkWell(
          onTap: isReorderingMode ? null : onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group label header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                child: Row(
                  children: [
                    if (isReorderingMode)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.drag_handle, size: 20),
                      ),
                    Expanded(
                      child: Text(
                        group.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isReorderingMode) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Edit group name',
                      ),
                      IconButton(
                        icon: const Icon(Icons.unarchive, size: 20),
                        onPressed: onUngroup,
                        tooltip: 'Ungroup photos',
                      ),
                    ],
                  ],
                ),
              ),
              
              // Photos grid
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final photoCount = group.photos.length;
                    final itemWidth = photoCount > 2 
                        ? (constraints.maxWidth - 8) / 3 
                        : (constraints.maxWidth - 4) / 2;
                    final height = itemWidth * 0.75;
                    
                    return Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        for (var i = 0; i < photoCount; i++)
                          if (i < 5 || photoCount <= 6) // Show up to 5 photos or all if 6 or fewer
                            SizedBox(
                              width: itemWidth,
                              height: height,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.file(
                                  File(group.photos[i].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (i == 5) // For the 6th spot, show a "+X more" indicator
                            SizedBox(
                              width: itemWidth,
                              height: height,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Image.file(
                                      File(group.photos[i].path),
                                      fit: BoxFit.cover,
                                      color: Colors.black.withOpacity(0.5),
                                      colorBlendMode: BlendMode.darken,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '+${photoCount - 5}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}