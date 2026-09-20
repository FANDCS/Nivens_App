import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Αναπαριστά μία σημείωση σε markdown με YAML front-matter.
/// (Ονομάστηκε NoteDocument για να μη συγκρούεται με το drift row class.)
class NoteDocument {
  String id;
  String title;
  List<String> tags;
  String font;
  double fontSize;
  DateTime createdAt;
  DateTime updatedAt;
  String body;
  List<String> attachmentIds;

  /// Διαδρομή PNG με διάφανο φόντο που ζωγραφίζεται ΠΑΝΩ από όλα
  /// (κείμενο + εικόνες) στην Προβολή. null = δεν υπάρχει overlay.
  String? overlayPath;

  NoteDocument({
    String? id,
    required this.title,
    this.tags = const [],
    this.font = 'Roboto',
    this.fontSize = 15.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.body = '',
    this.attachmentIds = const [],
    this.overlayPath,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  String toMarkdownFile() {
    final frontMatter = {
      'id': id,
      'title': title,
      'tags': tags,
      'font': font,
      'fontSize': fontSize,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentIds': attachmentIds,
      'overlay': overlayPath ?? '',
    };
    final yamlStr = YamlWriter().write(frontMatter);
    return '---\n$yamlStr---\n\n$body';
  }

  factory NoteDocument.fromMarkdownFile(String content) {
    final match = RegExp(r'^---\n([\s\S]*?)\n---\n\n?([\s\S]*)$')
        .firstMatch(content);
    if (match == null) {
      throw FormatException('Μη έγκυρο note file: λείπει το front-matter');
    }
    final yamlMap = loadYaml(match.group(1)!) as YamlMap;
    final body = match.group(2) ?? '';

    return NoteDocument(
      id: yamlMap['id'] as String,
      title: yamlMap['title'] as String? ?? 'Χωρίς τίτλο',
      tags: (yamlMap['tags'] as YamlList?)?.map((e) => e.toString()).toList() ?? [],
      font: yamlMap['font'] as String? ?? 'Roboto',
      fontSize: (yamlMap['fontSize'] as num?)?.toDouble() ?? 15.0,
      createdAt: DateTime.parse(yamlMap['createdAt'] as String),
      updatedAt: DateTime.parse(yamlMap['updatedAt'] as String),
      body: body,
      attachmentIds: (yamlMap['attachmentIds'] as YamlList?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      overlayPath: (yamlMap['overlay'] as String?)?.isEmpty ?? true
          ? null
          : yamlMap['overlay'] as String,
    );
  }
}
