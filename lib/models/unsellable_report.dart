import 'dart:io';

class UnsellableReport {
  const UnsellableReport({
    required this.id,
    required this.title,
    required this.description,
    required this.photoFileName,
    required this.photoPath,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String photoFileName;
  final String photoPath;
  final DateTime createdAt;

  factory UnsellableReport.fromJson(Object? value, String photoDirectory) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid unsellable report');
    }
    final id = value['id'];
    final title = value['title'];
    final description = value['description'];
    final photoFileName = value['photoFileName'];
    final dateText = value['createdAt'];
    final createdAt = dateText is String ? DateTime.tryParse(dateText) : null;
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        description is! String ||
        description.trim().isEmpty ||
        photoFileName is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]+\.[a-zA-Z0-9]{1,8}$')
            .hasMatch(photoFileName) ||
        createdAt == null) {
      throw const FormatException('Invalid unsellable report fields');
    }
    return UnsellableReport(
      id: id,
      title: title,
      description: description,
      photoFileName: photoFileName,
      photoPath: photoDirectory + Platform.pathSeparator + photoFileName,
      createdAt: createdAt,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'photoFileName': photoFileName,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}
