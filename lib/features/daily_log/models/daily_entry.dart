import 'package:uuid/uuid.dart';




class DailyEntry {
  final String id;
  final DateTime timestamp;
  String text;
  String? tag; 
  int weight; 

  DailyEntry({
    String? id,
    DateTime? timestamp,
    required this.text,
    this.tag,
    this.weight = 1,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'text': text,
        'tag': tag,
        'weight': weight,
      };

  factory DailyEntry.fromJson(Map<String, dynamic> json) => DailyEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        text: json['text'] as String,
        tag: json['tag'] as String?,
        weight: json['weight'] as int? ?? 1,
      );
}
