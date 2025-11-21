import 'dart:convert';
import '../../domain/entities/ontology.dart';
import '../../domain/entities/ontology_class.dart';
import '../../domain/entities/ontology_property.dart';

class OntologyModel extends Ontology {
  OntologyModel({
    required super.id,
    required super.baseUri,
    required super.name,
    super.description,
    super.version,
    super.classes,
    super.properties,
    super.imports,
    super.prefixes,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory OntologyModel.fromEntity(Ontology ontology) {
    return OntologyModel(
      id: ontology.id,
      baseUri: ontology.baseUri,
      name: ontology.name,
      description: ontology.description,
      version: ontology.version,
      classes: ontology.classes,
      properties: ontology.properties,
      imports: ontology.imports,
      prefixes: ontology.prefixes,
      createdAt: ontology.createdAt,
      updatedAt: ontology.updatedAt,
      metadata: ontology.metadata,
    );
  }

  factory OntologyModel.fromJson(Map<String, dynamic> json) {
    return OntologyModel(
      id: json['id'] as String,
      baseUri: json['base_uri'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      classes: (json['classes'] as List?)
              ?.map((c) => OntologyClassModel.fromJson(c).toEntity())
              .toList() ??
          [],
      properties: (json['properties'] as List?)
              ?.map((p) => OntologyPropertyModel.fromJson(p).toEntity())
              .toList() ??
          [],
      imports:
          (json['imports'] as List?)?.map((i) => i as String).toList() ?? [],
      prefixes: (json['prefixes'] as Map?)?.cast<String, String>() ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  factory OntologyModel.fromMap(Map<String, dynamic> map) {
    return OntologyModel(
      id: map['id'] as String,
      baseUri: map['base_uri'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      version: map['version'] as String? ?? '1.0.0',
      classes: map['classes'] != null
          ? (jsonDecode(map['classes'] as String) as List)
              .map((c) => OntologyClassModel.fromJson(c).toEntity())
              .toList()
          : [],
      properties: map['properties'] != null
          ? (jsonDecode(map['properties'] as String) as List)
              .map((p) => OntologyPropertyModel.fromJson(p).toEntity())
              .toList()
          : [],
      imports: map['imports'] != null
          ? (jsonDecode(map['imports'] as String) as List)
              .map((i) => i as String)
              .toList()
          : [],
      prefixes: map['prefixes'] != null
          ? (jsonDecode(map['prefixes'] as String) as Map).cast<String, String>()
          : {},
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
      'base_uri': baseUri,
      'name': name,
      'description': description,
      'version': version,
      'classes': classes.map((c) => OntologyClassModel.fromEntity(c).toJson()).toList(),
      'properties': properties.map((p) => OntologyPropertyModel.fromEntity(p).toJson()).toList(),
      'imports': imports,
      'prefixes': prefixes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_uri': baseUri,
      'name': name,
      'description': description,
      'version': version,
      'classes': jsonEncode(classes.map((c) => OntologyClassModel.fromEntity(c).toJson()).toList()),
      'properties': jsonEncode(properties.map((p) => OntologyPropertyModel.fromEntity(p).toJson()).toList()),
      'imports': jsonEncode(imports),
      'prefixes': jsonEncode(prefixes),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  Ontology toEntity() {
    return Ontology(
      id: id,
      baseUri: baseUri,
      name: name,
      description: description,
      version: version,
      classes: classes,
      properties: properties,
      imports: imports,
      prefixes: prefixes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }
}

class OntologyClassModel extends OntologyClass {
  OntologyClassModel({
    required super.uri,
    required super.label,
    super.description,
    super.parentClassUri,
    super.propertyUris,
    super.restrictions,
    super.metadata,
  });

  factory OntologyClassModel.fromEntity(OntologyClass ontClass) {
    return OntologyClassModel(
      uri: ontClass.uri,
      label: ontClass.label,
      description: ontClass.description,
      parentClassUri: ontClass.parentClassUri,
      propertyUris: ontClass.propertyUris,
      restrictions: ontClass.restrictions,
      metadata: ontClass.metadata,
    );
  }

  factory OntologyClassModel.fromJson(Map<String, dynamic> json) {
    return OntologyClassModel(
      uri: json['uri'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      parentClassUri: json['parent_class_uri'] as String?,
      propertyUris: (json['property_uris'] as List?)?.cast<String>() ?? [],
      restrictions: (json['restrictions'] as List?)
              ?.map((r) => OntologyRestrictionModel.fromJson(r).toEntity())
              .toList() ??
          [],
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'label': label,
      'description': description,
      'parent_class_uri': parentClassUri,
      'property_uris': propertyUris,
      'restrictions': restrictions.map((r) => OntologyRestrictionModel.fromEntity(r).toJson()).toList(),
      'metadata': metadata,
    };
  }

  OntologyClass toEntity() {
    return OntologyClass(
      uri: uri,
      label: label,
      description: description,
      parentClassUri: parentClassUri,
      propertyUris: propertyUris,
      restrictions: restrictions,
      metadata: metadata,
    );
  }
}

class OntologyRestrictionModel extends OntologyRestriction {
  OntologyRestrictionModel({
    required super.type,
    required super.propertyUri,
    required super.value,
    super.description,
  });

  factory OntologyRestrictionModel.fromEntity(OntologyRestriction restriction) {
    return OntologyRestrictionModel(
      type: restriction.type,
      propertyUri: restriction.propertyUri,
      value: restriction.value,
      description: restriction.description,
    );
  }

  factory OntologyRestrictionModel.fromJson(Map<String, dynamic> json) {
    return OntologyRestrictionModel(
      type: RestrictionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RestrictionType.maxCardinality,
      ),
      propertyUri: json['property_uri'] as String,
      value: json['value'],
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'property_uri': propertyUri,
      'value': value,
      'description': description,
    };
  }

  OntologyRestriction toEntity() {
    return OntologyRestriction(
      type: type,
      propertyUri: propertyUri,
      value: value,
      description: description,
    );
  }
}

class OntologyPropertyModel extends OntologyProperty {
  OntologyPropertyModel({
    required super.uri,
    required super.label,
    super.description,
    required super.type,
    required super.domainUri,
    required super.rangeUri,
    super.isRequired,
    super.isFunctional,
    super.inversePropertyUri,
    super.metadata,
  });

  factory OntologyPropertyModel.fromEntity(OntologyProperty prop) {
    return OntologyPropertyModel(
      uri: prop.uri,
      label: prop.label,
      description: prop.description,
      type: prop.type,
      domainUri: prop.domainUri,
      rangeUri: prop.rangeUri,
      isRequired: prop.isRequired,
      isFunctional: prop.isFunctional,
      inversePropertyUri: prop.inversePropertyUri,
      metadata: prop.metadata,
    );
  }

  factory OntologyPropertyModel.fromJson(Map<String, dynamic> json) {
    return OntologyPropertyModel(
      uri: json['uri'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      type: PropertyType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PropertyType.dataProperty,
      ),
      domainUri: json['domain_uri'] as String,
      rangeUri: json['range_uri'] as String,
      isRequired: json['is_required'] as bool? ?? false,
      isFunctional: json['is_functional'] as bool? ?? false,
      inversePropertyUri: json['inverse_property_uri'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'label': label,
      'description': description,
      'type': type.name,
      'domain_uri': domainUri,
      'range_uri': rangeUri,
      'is_required': isRequired,
      'is_functional': isFunctional,
      'inverse_property_uri': inversePropertyUri,
      'metadata': metadata,
    };
  }

  OntologyProperty toEntity() {
    return OntologyProperty(
      uri: uri,
      label: label,
      description: description,
      type: type,
      domainUri: domainUri,
      rangeUri: rangeUri,
      isRequired: isRequired,
      isFunctional: isFunctional,
      inversePropertyUri: inversePropertyUri,
      metadata: metadata,
    );
  }
}
