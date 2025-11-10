import 'dart:convert';
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  NoteModel({
    required super.id,
    required super.content,
    required super.metadata,
  });

  // Converter de Note para NoteModel
  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      content: note.content,
      metadata: note.metadata,
    );
  }

  // Converter de JSON para NoteModel
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      content: json['content'] as String,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  // Converter de Map (Database) para NoteModel
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      content: map['content'] as String,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(map['metadata'] as String) as Map)
          : {},
    );
  }

  // Converter NoteModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'metadata': metadata,
    };
  }

  // Converter NoteModel para Map (Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'metadata': jsonEncode(metadata),
    };
  }

  // Converter NoteModel para Note (Entity)
  Note toEntity() {
    return Note(
      id: id,
      content: content,
      metadata: metadata,
    );
  }

  // CopyWith para facilitar atualizações
  NoteModel copyWith({
    String? id,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return NoteModel(
      id: id ?? this.id,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
    );
  }
}
