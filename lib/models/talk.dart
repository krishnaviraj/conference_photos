class Talk {
  final String id;
  final String name;
  final String? presenter;
  final DateTime createdAt;
  final int photoCount;

  Talk({
    required this.id,
    required this.name,
    this.presenter,
    required this.createdAt,
    this.photoCount = 0,
  });

  Talk copyWith({
    String? name,
    String? presenter,
    int? photoCount,
  }) {
    return Talk(
      id: id,
      name: name ?? this.name,
      presenter: presenter ?? this.presenter,
      createdAt: createdAt,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  Talk updatePhotoCount(int count) {
    return copyWith(photoCount: count);
  }
}