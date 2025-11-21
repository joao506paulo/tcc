import 'dart:convert';
import '../../domain/entities/semantic_annotation.dart';

class SemanticAnnotationModel extends SemanticAnnotation {
  SemanticAnnotationModel({
    required super.id,
    required super.noteId,
    required super.templateId,
    required super.classUri,
    super.propertyValues,
    super.relations,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory SemanticAnnotationModel.fromEntity(SemanticAnnotation annotation) {
    return SemanticAnnotationModel(
      id: annotation.id,
      noteId: annotation.noteId,
      templateId: annotation.templateId,
      classUri: annotation.classUri,
      propertyValues: annotation.propertyValues,
      relations: annotation.relations,
      createdAt: annotation.createdAt,
      updatedAt: annotation.updatedAt,
      metadata: annotation.metadata,
    );
  }

  factory SemanticAnnotationModel.fromJson(Map<String, dynamic> json) {
    return SemanticAnnotationModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      templateId: json['template_id'] as String,
      classUri: json['class_uri'] as String,
      propertyValues:
          (json['property_values'] as Map?)?.cast<String, dynamic>() ?? {},
      relations: (json['relations'] as List?)
              ?.map((r) => NoteRelationModel.fromJson(r).toEntity())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  factory SemanticAnnotationModel.fromMap(Map<String, dynamic> map) {
    return SemanticAnnotationModel(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      templateId: map['template_id'] as String,
      classUri: map['class_uri'] as String,
      propertyValues: map['property_values'] != null
          ? (jsonDecode(map['property_values'] as String) as Map)
              .cast<String, dynamic>()
          : {},
      relations: map['relations'] != null
          ? (jsonDecode(map['relations'] as String) as List)
              .map((r) => NoteRelationModel.fromJson(r).toEntity())
              .toList()
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      metadata: map['metadata'] != null
          ? (jsonDecode(map['metadata'] as String) as Map).cast<String, dynamic>()
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'template_id': templateId,
      'class_uri': classUri,
      'property_values': propertyValues,
      'relations':
          relations.map((r) => NoteRelationModel.fromEntity(r).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'template_id': templateId,
      'class_uri': classUri,
      'property_values': jsonEncode(propertyValues),
      'relations': jsonEncode(
          relations.map((r) => NoteRelationModel.fromEntity(r).toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  SemanticAnnotation toEntity() {
    return SemanticAnnotation(
      id: id,
      noteId: noteId,
      templateId: templateId,
      classUri: classUri,
      propertyValues: propertyValues,
      relations: relations,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }
}

class NoteRelationModel extends NoteRelation {
  NoteRelationModel({
    required super.propertyUri,
    required super.targetNoteId,
    super.label,
  });

  factory NoteRelationModel.fromEntity(NoteRelation relation) {
    return NoteRelationModel(
      propertyUri: relation.propertyUri,
      targetNoteId: relation.targetNoteId,
      label: relation.label,
    );
  }

  factory NoteRelationModel.fromJson(Map<String, dynamic> json) {
    return NoteRelationModel(
      propertyUri: json['property_uri'] as String,
      targetNoteId: json['target_note_id'] as String,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_uri': propertyUri,
      'target_note_id': targetNoteId,
      'label': label,
    };
  }

  NoteRelation toEntity() {
    return NoteRelation(
      propertyUri: propertyUri,
      targetNoteId: targetNoteId,
      label: label,
    );
  }
}

class RdfTripleModel extends RdfTriple {
  RdfTripleModel({
    required super.subject,
    required super.predicate,
    required super.object,
    super.isLiteral,
    super.datatype,
    super.language,
  });

  factory RdfTripleModel.fromEntity(RdfTriple triple) {
    return RdfTripleModel(
      subject: triple.subject,
      predicate: triple.predicate,
      object: triple.object,
      isLiteral: triple.isLiteral,
      datatype: triple.datatype,
      language: triple.language,
    );
  }

  factory RdfTripleModel.fromJson(Map<String, dynamic> json) {
    return RdfTripleModel(
      subject: json['subject'] as String,
      predicate: json['predicate'] as String,
      object: json['object'] as String,
      isLiteral: json['is_literal'] as bool? ?? true,
      datatype: json['datatype'] as String?,
      language: json['language'] as String?,
    );
  }

  factory RdfTripleModel.fromMap(Map<String, dynamic> map) {
    return RdfTripleModel(
      subject: map['subject'] as String,
      predicate: map['predicate'] as String,
      object: map['object'] as String,
      isLiteral: (map['is_literal'] as int?) == 1,
      datatype: map['datatype'] as String?,
      language: map['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'predicate': predicate,
      'object': object,
      'is_literal': isLiteral,
      'datatype': datatype,
      'language': language,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'predicate': predicate,
      'object': object,
      'is_literal': isLiteral ? 1 : 0,
      'datatype': datatype,
      'language': language,
    };
  }

  RdfTriple toEntity() {
    return RdfTriple(
      subject: subject,
      predicate: predicate,
      object: object,
      isLiteral: isLiteral,
      datatype: datatype,
      language: language,
    );
  }
}
