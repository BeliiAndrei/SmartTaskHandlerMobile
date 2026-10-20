import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../models/unsellable_report.dart';

typedef UnsellableDirectoryProvider = Future<Directory> Function();

class UnsellableRepository {
  UnsellableRepository({UnsellableDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const fileName = 'unsellable_reports.json';
  static const photosFolder = 'unsellable_photos';
  final UnsellableDirectoryProvider _directoryProvider;

  Future<List<UnsellableReport>> load() async {
    final directory = await _directoryProvider();
    final file = File(directory.path + Platform.pathSeparator + fileName);
    if (!await file.exists()) return <UnsellableReport>[];

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['reports'] is! List) {
      throw const FormatException('Invalid unsellable reports JSON');
    }
    final photoDirectory =
        directory.path + Platform.pathSeparator + photosFolder;
    final reports = (decoded['reports'] as List)
        .map((entry) => UnsellableReport.fromJson(entry, photoDirectory))
        .toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<UnsellableReport> create({
    required String title,
    required String description,
    required File sourcePhoto,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty || trimmedDescription.isEmpty) {
      throw ArgumentError('Title and description are required');
    }
    if (!await sourcePhoto.exists() || await sourcePhoto.length() == 0) {
      throw const FileSystemException('Selected photo is missing or empty');
    }

    // Read before copying so a damaged index is never silently replaced.
    final previous = await load();
    final directory = await _directoryProvider();
    final photos = Directory(
      directory.path + Platform.pathSeparator + photosFolder,
    );
    await photos.create(recursive: true);
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32).toRadixString(16)}';
    final extension = _safeExtension(sourcePhoto.path);
    final photoFileName = '$id.$extension';
    final target = File(photos.path + Platform.pathSeparator + photoFileName);
    await sourcePhoto.copy(target.path);

    final report = UnsellableReport(
      id: id,
      title: trimmedTitle,
      description: trimmedDescription,
      photoFileName: photoFileName,
      photoPath: target.path,
      createdAt: DateTime.now().toUtc(),
    );
    try {
      final index = File(directory.path + Platform.pathSeparator + fileName);
      final contents = const JsonEncoder.withIndent('  ').convert({
        'reports': [report, ...previous].map((item) => item.toJson()).toList(),
      });
      await index.writeAsString('$contents\n', flush: true);
      return report;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  static String _safeExtension(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension) ? extension : 'jpg';
  }
}
