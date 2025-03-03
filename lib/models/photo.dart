class Photo {
  final String id;
  final String path;
  String annotation;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.path,
    required this.annotation,
    required this.createdAt,
  });

  Photo copyWith({
    String? path,
    String? annotation,
  }) {
    return Photo(
      id: id,
      path: path ?? this.path,
      annotation: annotation ?? this.annotation,
      createdAt: createdAt,
    );
  }
}