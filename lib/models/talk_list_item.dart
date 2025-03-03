import 'package:flutter/foundation.dart';
import 'photo.dart';
import 'photo_group.dart';

abstract class TalkListItem {
  String get id;
  DateTime get createdAt;
  bool get isGroup;
}

// Extend Photo class to implement TalkListItem
extension PhotoAsListItem on Photo {
  TalkListItem asListItem() {
    return _PhotoListItemAdapter(this);
  }
}

class _PhotoListItemAdapter implements TalkListItem {
  final Photo photo;
  
  _PhotoListItemAdapter(this.photo);
  
  @override
  String get id => photo.id;
  
  @override
  DateTime get createdAt => photo.createdAt;
  
  @override
  bool get isGroup => false;
}

// Extend PhotoGroup to implement TalkListItem
extension PhotoGroupAsListItem on PhotoGroup {
  TalkListItem asListItem() {
    return _PhotoGroupListItemAdapter(this);
  }
}

class _PhotoGroupListItemAdapter implements TalkListItem {
  final PhotoGroup group;
  
  _PhotoGroupListItemAdapter(this.group);
  
  @override
  String get id => group.id;
  
  @override
  DateTime get createdAt => group.createdAt;
  
  @override
  bool get isGroup => true;
}